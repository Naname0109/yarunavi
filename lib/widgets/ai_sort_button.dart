import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../l10n/generated/app_localizations.dart';
import '../providers/purchase_provider.dart';
import '../providers/task_provider.dart';
import '../services/ad_service.dart';
import '../services/ai_service.dart';
import '../utils/constants.dart';
import '../utils/feature_gate.dart';

/// AdServiceのProvider（main.dartでoverrideされる）
final adServiceProvider = Provider<AdService>((ref) {
  throw UnimplementedError('adServiceProvider must be overridden');
});

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

    // 回数チェック
    final canUse = await FeatureGate.canUseAiSort(db, isPremium);
    if (!canUse) {
      if (!mounted) return;
      await _showLimitDialog(l10n, isPremium);
      return;
    }

    await _executeAiSort(l10n, locale);
  }

  Future<void> _executeAiSort(AppLocalizations l10n, String locale) async {
    final db = ref.read(databaseServiceProvider);

    // タスク取得
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

    try {
      final results = await AiService.sortTasks(incompleteTasks);

      final isRealApiCall = AppConstants.anthropicApiKey.isNotEmpty;

      final updates = <int, ({int priority, String? aiComment})>{};
      for (final r in results) {
        final comment = locale == 'ja' ? r.commentJa : r.commentEn;
        updates[r.taskId] = (priority: r.priority, aiComment: comment);
      }
      await db.updateTaskPriorities(updates);

      if (isRealApiCall) {
        await db.recordAiUsage();
      }

      ref.invalidate(tasksProvider);
      _refreshRemaining();

      if (mounted) {
        context.push('/ai-result');
      }
    } on AiServiceException catch (e) {
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.aiErrorNetwork)),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _showLimitDialog(AppLocalizations l10n, bool isPremium) async {
    final message = isPremium
        ? l10n.aiSortDailyLimitReached
        : l10n.aiSortLimitReached;
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
