import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../l10n/generated/app_localizations.dart';
import '../providers/purchase_provider.dart';
import '../providers/task_provider.dart';
import '../services/ad_service.dart';
import '../services/ai_service.dart';
import '../utils/category_helper.dart';
import '../utils/constants.dart';
import '../utils/feature_gate.dart';

/// AdServiceのProvider（main.dartでoverrideされる）
final adServiceProvider = Provider<AdService>((ref) {
  throw UnimplementedError('adServiceProvider must be overridden');
});

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
  Future<bool> _rewardUnlockedFuture = Future.value(false);

  @override
  void initState() {
    super.initState();
    _refreshRemaining();
  }

  void _refreshRemaining() {
    final db = ref.read(databaseServiceProvider);
    final isPremium = ref.read(isPremiumProvider);
    _remainingFuture = FeatureGate.getRemainingAiSortCount(db, isPremium);
    _rewardUnlockedFuture = AdService.isRewardUnlocked();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isPremium = ref.watch(isPremiumProvider);

    return FutureBuilder<int>(
      future: _remainingFuture,
      builder: (context, snapshot) {
        final remaining = snapshot.data ?? 0;

        return FutureBuilder<bool>(
          future: _rewardUnlockedFuture,
          builder: (context, rewardSnapshot) {
            final rewardUnlocked = rewardSnapshot.data ?? false;

            String label;
            if (_isLoading) {
              label = l10n.aiSorting;
            } else if (isPremium || kDebugMode) {
              label = l10n.aiSort;
            } else if (rewardUnlocked) {
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
      },
    );
  }

  Future<void> _onTap(AppLocalizations l10n) async {
    final db = ref.read(databaseServiceProvider);
    final isPremium = ref.read(isPremiumProvider);
    final locale = Localizations.localeOf(context).languageCode;

    final canUse = await FeatureGate.canUseAiSort(db, isPremium);
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

      // priority/aiComment更新
      final updates = <int, ({int priority, String? aiComment})>{};
      for (final r in response.tasks) {
        final comment = locale == 'ja' ? r.commentJa : r.commentEn;
        updates[r.taskId] = (priority: r.priority, aiComment: comment);
      }
      await db.updateTaskPriorities(updates);

      // ai_autoのタスクの通知をAI推奨日で更新
      final isPremium = ref.read(isPremiumProvider);
      final notifyService = ref.read(notificationServiceProvider);
      for (final r in response.tasks) {
        if (r.recommendedNotifyDates.isEmpty) continue;
        final task =
            incompleteTasks.where((t) => t.id == r.taskId).firstOrNull;
        if (task == null) continue;

        bool isAiAuto = false;
        if (task.notifySettings != null) {
          try {
            final decoded =
                List<String>.from(jsonDecode(task.notifySettings!) as List);
            isAiAuto = decoded.length == 1 && decoded.first == 'ai_auto';
          } catch (_) {}
        }

        if (isAiAuto) {
          await notifyService.scheduleNotificationsForDates(
            task,
            dates: r.recommendedNotifyDates,
            isPremium: isPremium,
            locale: locale,
          );
        }
      }

      if (isRealApiCall) {
        await db.recordAiUsage();
      }

      // AI履歴に保存
      await db.insertAiHistory(
        summaryJa: response.summaryJa,
        summaryEn: response.summaryEn,
        resultJson: jsonEncode(response.toJson()),
        taskCount: response.tasks.length,
      );

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
    final message =
        isPremium ? l10n.aiSortDailyLimitReached : l10n.aiSortLimitReached;
    final canShowReward = await FeatureGate.canShowRewardAd(isPremium);
    final adService = ref.read(adServiceProvider);

    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.aiSort),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.cancel),
          ),
          if (canShowReward && adService.isRewardedAdReady)
            TextButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                final rewarded = await adService.showRewardedAd();
                if (rewarded && mounted) {
                  final locale = Localizations.localeOf(context).languageCode;
                  await _executeAiSort(l10n, locale);
                }
              },
              child: Text(l10n.aiSortWatchAd),
            ),
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
