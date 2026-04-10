import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../l10n/generated/app_localizations.dart';
import '../providers/purchase_provider.dart';
import '../providers/secure_storage_provider.dart';
import '../providers/task_provider.dart';
import '../services/ai_service.dart';
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
  late Future<int> _remainingFuture;

  @override
  void initState() {
    super.initState();
    _refreshRemaining();
  }

  void _refreshRemaining() {
    final secure = ref.read(secureStorageServiceProvider);
    final isPremium = ref.read(isPremiumProvider);
    final devAiUnlimited = ref.read(devModeAiUnlimitedProvider);
    _remainingFuture = FeatureGate.getRemainingAiSortCount(
      secure,
      isPremium,
      devAiUnlimited: devAiUnlimited,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isPremium = ref.watch(isPremiumProvider);

    return FutureBuilder<int>(
      future: _remainingFuture,
      builder: (context, snapshot) {
        final remaining = snapshot.data ?? 0;

        String label;
        if (_isLoading) {
          label = l10n.aiSorting;
        } else if (isPremium || kDebugMode) {
          label = l10n.aiSort;
        } else {
          label = '${l10n.aiSort} (${l10n.aiSortRemaining(remaining)})';
        }

        return TextButton.icon(
          onPressed: _isLoading ? null : () => _onTap(l10n),
          icon: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.auto_awesome, size: 20),
          label: Text(label),
        );
      },
    );
  }

  Future<void> _onTap(AppLocalizations l10n) async {
    final secure = ref.read(secureStorageServiceProvider);
    final isPremium = ref.read(isPremiumProvider);
    final locale = Localizations.localeOf(context).languageCode;

    final devAiUnlimited = ref.read(devModeAiUnlimitedProvider);
    final canUse = await FeatureGate.canUseAiSort(
      secure,
      isPremium,
      devAiUnlimited: devAiUnlimited,
    );
    if (!canUse) {
      if (!mounted) return;
      await _showLimitDialog(l10n, isPremium);
      return;
    }

    await _executeAiSort(l10n, locale);
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

      // priority/aiComment/recommendedStart/end更新
      final updates = <int,
          ({
            int priority,
            String? aiComment,
            DateTime? recommendedStart,
            DateTime? recommendedEnd,
          })>{};
      for (final r in response.tasks) {
        final comment = locale == 'ja' ? r.commentJa : r.commentEn;
        final start = (r.recommendedStart != null &&
                r.recommendedStart!.isNotEmpty)
            ? DateTime.tryParse(r.recommendedStart!)
            : null;
        final end = (r.recommendedEnd != null && r.recommendedEnd!.isNotEmpty)
            ? DateTime.tryParse(r.recommendedEnd!)
            : null;
        updates[r.taskId] = (
          priority: r.priority,
          aiComment: comment,
          recommendedStart: start,
          recommendedEnd: end,
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
        await secure.incrementAiUsage(
          SecureStorageService.currentMonthKey(DateTime.now()),
        );
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
      _refreshRemaining();

      // モーダルを閉じる（まだ閉じていない場合のみ）
      if (mounted && !dialogDismissed) {
        Navigator.of(context, rootNavigator: true).pop();
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
    } catch (_) {
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

  Future<void> _showLimitDialog(AppLocalizations l10n, bool isPremium) async {
    final theme = Theme.of(context);

    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.aiSort),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(isPremium
                ? l10n.aiSortMonthlyLimitReached
                : l10n.aiSortLimitReached),
            if (!isPremium) ...[
              const SizedBox(height: 16),
              // ミニ訴求
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.aiLimitUpgradeHint,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      l10n.aiLimitUpgradeDesc,
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.cancel),
          ),
          if (!isPremium)
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                context.push('/store');
              },
              child: Text(l10n.aiSortUpgradeToPremium),
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
