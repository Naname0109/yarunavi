import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../l10n/generated/app_localizations.dart';
import '../providers/purchase_provider.dart';
import '../providers/secure_storage_provider.dart';
import '../providers/task_provider.dart';
import '../services/ai_service.dart';
import '../services/rewarded_ad_service.dart';
import '../services/secure_storage_service.dart';
import '../utils/category_helper.dart';
import '../utils/constants.dart';
import '../providers/dev_mode_provider.dart';
import '../utils/feature_gate.dart';
import '../utils/notification_utils.dart';

/// AI整理レスポンスを保持するProvider
final aiSortResponseProvider =
    StateProvider<AiSortResponse?>((ref) => null);

/// AI整理結果を保持（後方互換）
final aiSortResultsProvider =
    Provider<List<AiSortResult>>((ref) {
  return ref.watch(aiSortResponseProvider)?.tasks ?? [];
});

/// AI整理完了バナー表示フラグ
final aiCompleteBannerProvider = StateProvider<bool>((ref) => false);

class AiSortButton extends ConsumerStatefulWidget {
  const AiSortButton({super.key});

  @override
  ConsumerState<AiSortButton> createState() => _AiSortButtonState();
}

class _AiSortButtonState extends ConsumerState<AiSortButton> {
  bool _isLoading = false;
  final _rewardedAdService = RewardedAdService();

  @override
  void initState() {
    super.initState();
    // リワード広告をプリロード
    _rewardedAdService.preload();
  }

  @override
  void dispose() {
    _rewardedAdService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return TextButton.icon(
      key: const Key('ai_sort_button'),
      onPressed: _isLoading ? null : () => _onTap(l10n),
      icon: _isLoading
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.auto_awesome, size: 20),
      label: Text(_isLoading ? l10n.aiSorting : l10n.aiSort),
    );
  }

  Future<void> _onTap(AppLocalizations l10n) async {
    final secure = ref.read(secureStorageServiceProvider);
    final isPremium = ref.read(isPremiumProvider);
    final locale = Localizations.localeOf(context).languageCode;
    final devAiUnlimited = ref.read(devModeAiUnlimitedProvider);

    final access = await FeatureGate.checkAiSortAccess(
      secure,
      isPremium,
      devAiUnlimited: devAiUnlimited,
    );

    switch (access) {
      case AiSortAccess.allowed:
        await _executeAiSort(l10n, locale);
      case AiSortAccess.rewardedAdRequired:
        if (!mounted) return;
        await _showRewardedAdDialog(l10n, locale);
      case AiSortAccess.rewardedAdUsedToday:
        if (!mounted) return;
        await _showTodayLimitDialog(l10n);
      case AiSortAccess.premiumMonthlyLimitReached:
        if (!mounted) return;
        await _showPremiumLimitDialog(l10n);
    }
  }

  Future<void> _executeAiSort(
    AppLocalizations l10n,
    String locale, {
    String? additionalContext,
  }) async {
    final db = ref.read(databaseServiceProvider);

    final tasks = await db.getAllTasks();
    final incompleteTasks = tasks.where((t) => !t.isCompleted).toList();

    if (incompleteTasks.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.aiSortNoTasks)),
      );
      return;
    }

    setState(() => _isLoading = true);

    // ローディングモーダル表示
    bool backgroundMode = false;
    bool dialogDismissed = false;
    if (mounted) {
      _showLoadingModal(l10n, () {
        backgroundMode = true;
        dialogDismissed = true;
      });
    }

    try {
      final categories = await db.getAllCategories();
      final categoryNames = <int, String>{};
      for (final cat in categories) {
        if (cat.id != null) {
          categoryNames[cat.id!] = getCategoryDisplayName(cat.name, l10n);
        }
      }

      final response = await AiService.sortTasks(
        incompleteTasks,
        categoryNames: categoryNames,
        additionalContext: additionalContext,
      );

      final isRealApiCall = AppConstants.anthropicApiKey.isNotEmpty;

      // priority/aiComment/recommendedDate更新
      final updates = <int,
          ({
            int priority,
            String? aiComment,
            DateTime? recommendedDate,
          })>{};
      for (final r in response.tasks) {
        final comment = locale == 'ja' ? r.commentJa : r.commentEn;
        final date = (r.recommendedDate != null &&
                r.recommendedDate!.isNotEmpty)
            ? DateTime.tryParse(r.recommendedDate!)
            : null;
        updates[r.taskId] = (
          priority: r.priority,
          aiComment: comment,
          recommendedDate: date,
        );
      }
      await db.updateTaskPriorities(updates);

      // プレミアム: AIのnotify_dateで自動通知スケジュール (手動設定済みは尊重)
      final isPremium = ref.read(isPremiumProvider);
      final notifyService = ref.read(notificationServiceProvider);
      if (isPremium) {
        for (final r in response.tasks) {
          final notifyDate = r.notifyDate;
          if (notifyDate == null || notifyDate.isEmpty) continue;
          final task =
              incompleteTasks.where((t) => t.id == r.taskId).firstOrNull;
          if (task == null) continue;

          // 手動設定済み (ai_auto以外で非null) はスキップ
          final hasManual = task.notifySettings != null &&
              !isAiAutoNotify(task.notifySettings);
          if (hasManual) continue;

          await notifyService.scheduleNotificationsForDates(
            task,
            dates: [notifyDate],
            isPremium: true,
            locale: locale,
          );
          // notify_settings を ai_auto に統一
          await db.updateTask(task.copyWith(
            notifySettings: jsonEncode(['ai_auto']),
            updatedAt: DateTime.now(),
          ));
        }
      }

      if (isRealApiCall) {
        await db.recordAiUsage();
        final secure = ref.read(secureStorageServiceProvider);
        final isPremium = ref.read(isPremiumProvider);
        if (isPremium) {
          await secure.incrementAiUsage(
            SecureStorageService.currentMonthKey(DateTime.now()),
          );
        } else {
          // 無料ユーザー: 永続カウンターをインクリメント
          await secure.incrementLifetimeFreeUsage();
        }
      }

      // AI履歴に保存
      await db.insertAiHistory(
        summaryJa: response.summaryJa,
        summaryEn: response.summaryEn,
        resultJson: jsonEncode(response.toJson()),
        taskCount: response.tasks.length,
      );

      // AI整理完了ハプティクス
      HapticFeedback.heavyImpact();

      // 結果をProviderに保存
      ref.read(aiSortResponseProvider.notifier).state = response;
      ref.invalidate(tasksProvider);

      // トリガーB: AI整理完了後にレビュー依頼
      final reviewService = ref.read(reviewServiceProvider);
      await reviewService.incrementAiSortCount();
      Future.delayed(const Duration(seconds: 5), () {
        reviewService.requestReviewIfEligible();
      });

      // モーダルを閉じる（まだ閉じていない場合のみ）
      if (mounted && !dialogDismissed) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      // フォールバック時はSnackbarで通知
      if (response.isFallback && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.aiFallbackNotice)),
        );
      }

      if (backgroundMode) {
        // バックグラウンドモード: バナー表示
        ref.read(aiCompleteBannerProvider.notifier).state = true;
      } else if (mounted) {
        context.push('/ai-result');
      }
    } on AiServiceException catch (e) {
      if (mounted && !dialogDismissed) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      if (!mounted) return;
      final message = switch (e.type) {
        AiErrorType.network => l10n.aiErrorNetwork,
        AiErrorType.parse => l10n.aiErrorParse,
        AiErrorType.rateLimit => l10n.aiErrorRateLimit,
      };
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (e, st) {
      debugPrint('[AiSort] unexpected error: $e');
      debugPrint('[AiSort] stackTrace: $st');
      if (mounted && !dialogDismissed) {
        Navigator.of(context, rootNavigator: true).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.aiErrorNetwork)),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showLoadingModal(AppLocalizations l10n, VoidCallback onBackground) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _AiLoadingDialog(
        l10n: l10n,
        onBackground: () {
          onBackground();
          Navigator.of(ctx).pop();
        },
      ),
    );
  }

  /// リワード広告を視聴してAI整理する
  Future<void> _showRewardedAdDialog(
      AppLocalizations l10n, String locale) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.aiSort),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.aiRewardedAdPrompt),
            const SizedBox(height: 12),
            Text(l10n.aiRewardedAdDesc,
                style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.of(ctx).pop(true),
            icon: const Icon(Icons.play_circle_outline, size: 18),
            label: Text(l10n.aiWatchAdButton),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    // 広告準備
    if (!_rewardedAdService.isReady) {
      await _rewardedAdService.preload();
      await Future.delayed(const Duration(seconds: 2));
    }

    if (!_rewardedAdService.isReady) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.aiRewardedAdNotReady)),
      );
      return;
    }

    final rewarded = await _rewardedAdService.show();
    if (!rewarded || !mounted) return;

    // リワード成功 → 使用記録
    final secure = ref.read(secureStorageServiceProvider);
    await secure.recordRewardedUsage();

    await _executeAiSort(l10n, locale);
  }

  /// 今日はリワード広告を使用済み
  Future<void> _showTodayLimitDialog(AppLocalizations l10n) async {
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.aiSort),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.aiRewardedAdUsedToday),
            const SizedBox(height: 12),
            Text(l10n.aiRewardedAdTomorrow,
                style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.push('/store');
            },
            child: Text(l10n.aiSortUpgradeToPremium),
          ),
        ],
      ),
    );
  }

  /// プレミアムの月間上限到達
  Future<void> _showPremiumLimitDialog(AppLocalizations l10n) async {
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.aiSort),
        content: Text(l10n.aiSortMonthlyLimitReached),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.cancel),
          ),
        ],
      ),
    );
  }
}

/// AI整理中ローディングダイアログ
class _AiLoadingDialog extends StatefulWidget {
  const _AiLoadingDialog({
    required this.l10n,
    required this.onBackground,
  });

  final AppLocalizations l10n;
  final VoidCallback onBackground;

  @override
  State<_AiLoadingDialog> createState() => _AiLoadingDialogState();
}

class _AiLoadingDialogState extends State<_AiLoadingDialog>
    with SingleTickerProviderStateMixin {
  int _messageIndex = 0;
  late final AnimationController _pulseController;

  List<String> get _messages => [
        widget.l10n.aiLoadingAnalyze,
        widget.l10n.aiLoadingPriority,
        widget.l10n.aiLoadingNotify,
        widget.l10n.aiLoadingAdvice,
        widget.l10n.aiLoadingAlmost,
      ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _cycleMessages();
  }

  void _cycleMessages() {
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _messageIndex = (_messageIndex + 1) % _messages.length;
        });
        _cycleMessages();
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                final scale = 1.0 + _pulseController.value * 0.15;
                return Transform.scale(
                  scale: scale,
                  child: Icon(
                    Icons.auto_awesome,
                    size: 48,
                    color: theme.colorScheme.primary,
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Text(
                _messages[_messageIndex],
                key: ValueKey(_messageIndex),
                style: theme.textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 20),
            const LinearProgressIndicator(),
            const SizedBox(height: 20),
            OutlinedButton(
              onPressed: widget.onBackground,
              child: Text(widget.l10n.aiRunBackground),
            ),
          ],
        ),
      ),
    );
  }
}
