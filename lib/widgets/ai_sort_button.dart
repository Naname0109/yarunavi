import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../l10n/generated/app_localizations.dart';
import '../providers/purchase_provider.dart';
import '../providers/secure_storage_provider.dart';
import '../providers/sound_provider.dart';
import '../providers/task_provider.dart';
import '../services/ai_service.dart';
import '../services/rewarded_ad_service.dart';
import '../services/secure_storage_service.dart';
import '../services/sound_service.dart';
import '../utils/category_helper.dart';
import '../utils/constants.dart';
import '../providers/dev_mode_provider.dart';
import '../providers/settings_provider.dart';
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

/// AI整理後カレンダータブ強調フラグ
final calendarHighlightProvider = StateProvider<bool>((ref) => false);

/// AI履歴の新着バッジフラグ（セッション単位）
final aiHistoryBadgeProvider = StateProvider<bool>((ref) => false);

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
        if (!mounted) return;
        final confirmed = await _showAiSortSheet(l10n);
        if (confirmed == true) await _executeAiSort(l10n, locale);
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

  Future<bool?> _showAiSortSheet(AppLocalizations l10n) {
    return showModalBottomSheet<bool>(
      context: context,
      builder: (ctx) => _AiSortBottomSheet(l10n: l10n),
    );
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

    // 手動設定の実行日があるタスクをチェック
    final manualDateTasks =
        incompleteTasks.where((t) => t.isRecommendedDateManual).toList();
    var skipManualDateIds = <int>{};
    if (manualDateTasks.isNotEmpty && mounted) {
      final keepManual = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l10n.manualDateOverwriteTitle),
          content: Text(
              l10n.manualDateOverwriteMessage(manualDateTasks.length)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(l10n.manualDateOverwriteAll),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(l10n.manualDateKeep),
            ),
          ],
        ),
      );
      if (keepManual == true) {
        skipManualDateIds =
            manualDateTasks.where((t) => t.id != null).map((t) => t.id!).toSet();
      }
    }

    setState(() => _isLoading = true);

    // プログレスコントローラー（タスク数に応じた進行速度）
    final progressController =
        _AiSortProgressController(incompleteTasks.length);

    // ローディングモーダル表示
    bool backgroundMode = false;
    bool dialogDismissed = false;
    if (mounted) {
      _showLoadingModal(l10n, progressController, () {
        backgroundMode = true;
        dialogDismissed = true;
      });
    }

    // 送信開始 → 0%→10%へ即ジャンプ
    progressController.setPhase(_AiPhase.sending);
    // 少し待ってから awaiting フェーズに進む（10%→80%のロング進行を開始）
    Future.delayed(const Duration(milliseconds: 250), () {
      progressController.setPhase(_AiPhase.awaiting);
    });

    try {
      final categories = await db.getAllCategories();
      final categoryNames = <int, String>{};
      for (final cat in categories) {
        if (cat.id != null) {
          categoryNames[cat.id!] = getCategoryDisplayName(cat.name, l10n);
        }
      }

      final timingFactor = ref.read(executionTimingProvider);

      final response = await AiService.sortTasks(
        incompleteTasks,
        categoryNames: categoryNames,
        additionalContext: additionalContext,
        executionTimingFactor: timingFactor,
      );

      // レスポンス受信 → 80%→95%
      progressController.setPhase(_AiPhase.receiving);

      final isRealApiCall = AppConstants.anthropicApiKey.isNotEmpty ||
          AppConstants.aiProxyUrl.isNotEmpty;

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
        if (kDebugMode) debugPrint('[AI-DEBUG] response: id=${r.taskId} comment=$comment rec=${r.recommendedDate}');
        updates[r.taskId] = (
          priority: r.priority,
          aiComment: comment,
          recommendedDate: date,
        );
      }

      // Safety net: recommended_date != due_date を強制保証
      final now2 = DateTime.now();
      final today2 = DateTime(now2.year, now2.month, now2.day);
      final finalUpdates = <int,
          ({
            int priority,
            String? aiComment,
            DateTime? recommendedDate,
          })>{};
      for (final entry in updates.entries) {
        final taskId = entry.key;
        final data = entry.value;
        if (skipManualDateIds.contains(taskId)) {
          finalUpdates[taskId] = data;
          continue;
        }
        final matches = incompleteTasks.where((t) => t.id == taskId);
        if (matches.isEmpty) {
          finalUpdates[taskId] = data;
          continue;
        }
        final taskObj = matches.first;
        final dueNorm = DateTime(taskObj.dueDate.year, taskObj.dueDate.month, taskObj.dueDate.day);
        final recDate = data.recommendedDate;
        final recNorm = recDate != null
            ? DateTime(recDate.year, recDate.month, recDate.day)
            : null;
        final dueStr = dueNorm.toIso8601String().substring(0, 10);
        final recStr = recNorm?.toIso8601String().substring(0, 10) ?? 'null';
        if (kDebugMode) debugPrint('[AI-DEBUG] DB保存: ${taskObj.title} rec=$recStr due=$dueStr same=${recNorm == dueNorm}');

        if (recNorm == null || recNorm == dueNorm) {
          final daysUntilDue = dueNorm.difference(today2).inDays;
          DateTime newRec;
          if (daysUntilDue <= 1) {
            newRec = today2;
          } else if (daysUntilDue <= 3) {
            newRec = dueNorm.subtract(const Duration(days: 1));
          } else if (daysUntilDue <= 7) {
            newRec = dueNorm.subtract(const Duration(days: 2));
          } else if (daysUntilDue <= 14) {
            newRec = dueNorm.subtract(const Duration(days: 4));
          } else {
            newRec = dueNorm.subtract(const Duration(days: 7));
          }
          if (newRec.isBefore(today2)) newRec = today2;
          if (kDebugMode) debugPrint('[AI-DEBUG] FORCE FIX: ${taskObj.title} rec→${newRec.toIso8601String().substring(0, 10)}');
          finalUpdates[taskId] = (priority: data.priority, aiComment: data.aiComment, recommendedDate: newRec);
        } else {
          finalUpdates[taskId] = data;
        }
      }

      // 最終検証ログ: DB保存直前に全タスクのrec vs dueを出力
      if (kDebugMode) {
        debugPrint('[DB-SAVE] ===== DB保存直前の最終状態 =====');
        for (final entry in finalUpdates.entries) {
          final taskId = entry.key;
          final data = entry.value;
          final taskMatch = incompleteTasks.where((t) => t.id == taskId);
          if (taskMatch.isEmpty) continue;
          final t = taskMatch.first;
          final dueStr = '${t.dueDate.year}-${t.dueDate.month.toString().padLeft(2, '0')}-${t.dueDate.day.toString().padLeft(2, '0')}';
          final recStr = data.recommendedDate != null
              ? '${data.recommendedDate!.year}-${data.recommendedDate!.month.toString().padLeft(2, '0')}-${data.recommendedDate!.day.toString().padLeft(2, '0')}'
              : 'NULL';
          final same = recStr == dueStr;
          final commentPreview = data.aiComment != null ? data.aiComment!.substring(0, data.aiComment!.length.clamp(0, 20)) : 'null';
          debugPrint('[DB-SAVE] ${t.title}: rec=$recStr due=$dueStr same=$same comment=$commentPreview');
          if (same) {
            debugPrint('[DB-SAVE] ★★★ ERROR: recommended_date == due_date が検出されました！ ★★★');
          }
        }
        debugPrint('[DB-SAVE] ===================================');
      }

      await db.updateTaskPriorities(finalUpdates,
          skipRecommendedDateIds: skipManualDateIds);

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

      // 95% → 100% (DB保存完了)
      progressController.setPhase(_AiPhase.finalizing);
      await Future.delayed(const Duration(milliseconds: 350));

      // 100%到達 → 完了演出
      progressController.setPhase(_AiPhase.complete);

      // サウンド + ハプティクスパターン (heavy → medium → light)
      final sound = ref.read(soundServiceProvider);
      unawaited(sound.play(SoundEvent.aiSortComplete));

      // 結果をProviderに保存
      ref.read(aiSortResponseProvider.notifier).state = response;
      ref.invalidate(tasksProvider);

      // トリガーB: AI整理完了後にレビュー依頼
      final reviewService = ref.read(reviewServiceProvider);
      await reviewService.incrementAiSortCount();
      Future.delayed(const Duration(seconds: 5), () {
        reviewService.requestReviewIfEligible();
      });

      ref.read(calendarHighlightProvider.notifier).state = true;
      ref.read(aiHistoryBadgeProvider.notifier).state = true;

      // 完了演出の余韻（バースト 0.5s + チェックバウンス 0.3s + 余韻 0.2s ≒ 1.0s）
      // 仕様のステップ5「演出が一通り終わったら0.5秒後に遷移」を含めて約1.0秒
      await Future.delayed(const Duration(milliseconds: 1000));

      // モーダルを閉じる（まだ閉じていない場合のみ）
      if (mounted && !dialogDismissed) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      // フォールバック時はSnackbarで通知（API未設定時のみ走るパス）
      if (response.isFallback && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.aiFallbackNotice)),
        );
      }

      if (backgroundMode) {
        ref.read(aiCompleteBannerProvider.notifier).state = true;
      } else if (mounted) {
        context.push('/ai-result');
      }
    } on AiServiceException catch (e) {
      // エラー時: プログレスバーを赤色フェードアウト
      progressController.setPhase(_AiPhase.error);
      HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted && !dialogDismissed) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      if (!mounted) return;
      await _showAiErrorDialog(l10n, e.type);
    } catch (e, st) {
      debugPrint('[AiSort] unexpected error: $e');
      debugPrint('[AiSort] stackTrace: $st');
      progressController.setPhase(_AiPhase.error);
      HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted && !dialogDismissed) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      if (mounted) {
        await _showAiErrorDialog(l10n, AiErrorType.parse);
      }
    } finally {
      progressController.dispose();
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// AI整理失敗時のエラーダイアログ
  Future<void> _showAiErrorDialog(
      AppLocalizations l10n, AiErrorType type) async {
    final (title, body) = switch (type) {
      AiErrorType.network => (l10n.aiErrorNetworkTitle, l10n.aiErrorNetworkBody),
      AiErrorType.rateLimit => (
          l10n.aiErrorRateLimitTitle,
          l10n.aiErrorRateLimitBody
        ),
      AiErrorType.parse => (l10n.aiErrorApiTitle, l10n.aiErrorApiBody),
    };
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.aiErrorClose),
          ),
        ],
      ),
    );
  }

  void _showLoadingModal(
    AppLocalizations l10n,
    _AiSortProgressController controller,
    VoidCallback onBackground,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _AiLoadingDialog(
        l10n: l10n,
        controller: controller,
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

/// AI整理の進捗フェーズ
enum _AiPhase {
  /// AIリクエスト送信中（0% → 10%、即ジャンプ）
  sending,
  /// レスポンス待ち（10% → 80%、タスク数に応じた速度）
  awaiting,
  /// レスポンス受信後（80% → 95%、0.5秒）
  receiving,
  /// パース・DB保存完了（95% → 100%、0.3秒）
  finalizing,
  /// 完了演出（バースト＋チェック）
  complete,
  /// エラー（赤色→フェードアウト）
  error,
}

/// AI整理進捗のコントローラー
/// 外部からフェーズを更新するためのChangeNotifier
class _AiSortProgressController extends ChangeNotifier {
  _AiSortProgressController(this.taskCount);

  final int taskCount;
  _AiPhase _phase = _AiPhase.sending;

  _AiPhase get phase => _phase;

  /// タスク数に応じた送信→レスポンスまでの所要時間
  Duration get awaitingDuration {
    if (taskCount <= 5) return const Duration(seconds: 5);
    if (taskCount <= 10) return const Duration(seconds: 8);
    return const Duration(seconds: 12);
  }

  void setPhase(_AiPhase newPhase) {
    if (_phase == newPhase) return;
    _phase = newPhase;
    notifyListeners();
  }
}

/// AI整理中ローディングダイアログ
class _AiLoadingDialog extends StatefulWidget {
  const _AiLoadingDialog({
    required this.l10n,
    required this.controller,
    required this.onBackground,
  });

  final AppLocalizations l10n;
  final _AiSortProgressController controller;
  final VoidCallback onBackground;

  @override
  State<_AiLoadingDialog> createState() => _AiLoadingDialogState();
}

class _AiLoadingDialogState extends State<_AiLoadingDialog>
    with TickerProviderStateMixin {
  int _messageIndex = 0;
  late final AnimationController _pulseController;
  late final AnimationController _progressController;
  late final AnimationController _burstController;
  late final AnimationController _checkController;
  late final AnimationController _errorFadeController;

  late Animation<double> _progressAnimation;

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

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _progressAnimation =
        Tween<double>(begin: 0, end: 0).animate(_progressController);

    _burstController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _checkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _errorFadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
      value: 1.0,
    );

    widget.controller.addListener(_onPhaseChange);
    // 初期フェーズに合わせてアニメーション開始
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _onPhaseChange();
    });
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

  void _onPhaseChange() {
    if (!mounted) return;
    final phase = widget.controller.phase;
    switch (phase) {
      case _AiPhase.sending:
        _animateProgress(
            to: 0.1, duration: const Duration(milliseconds: 200));
      case _AiPhase.awaiting:
        _animateProgress(
          to: 0.8,
          duration: widget.controller.awaitingDuration,
          curve: Curves.easeOut,
        );
      case _AiPhase.receiving:
        _animateProgress(
            to: 0.95, duration: const Duration(milliseconds: 500));
      case _AiPhase.finalizing:
        _animateProgress(
            to: 1.0, duration: const Duration(milliseconds: 300));
      case _AiPhase.complete:
        _animateProgress(
            to: 1.0, duration: const Duration(milliseconds: 100));
        Future.delayed(const Duration(milliseconds: 120), () {
          if (mounted) {
            _burstController.forward(from: 0);
            _checkController.forward(from: 0);
          }
        });
      case _AiPhase.error:
        _errorFadeController.reverse(from: 1.0);
    }
    setState(() {}); // フェーズに応じたUI切り替え
  }

  void _animateProgress({
    required double to,
    required Duration duration,
    Curve curve = Curves.easeOut,
  }) {
    final from = _progressAnimation.value;
    _progressController.stop();
    _progressController.duration = duration;
    _progressAnimation = Tween<double>(begin: from, end: to).animate(
      CurvedAnimation(parent: _progressController, curve: curve),
    );
    _progressController.forward(from: 0);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onPhaseChange);
    _pulseController.dispose();
    _progressController.dispose();
    _burstController.dispose();
    _checkController.dispose();
    _errorFadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final phase = widget.controller.phase;
    final isComplete = phase == _AiPhase.complete;
    final isError = phase == _AiPhase.error;

    return Dialog(
      child: FadeTransition(
        opacity: _errorFadeController,
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // アイコン: 通常時はパルス、完了時はチェック
              SizedBox(
                height: 80,
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    if (!isComplete)
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
                    if (isComplete)
                      AnimatedBuilder(
                        animation: _checkController,
                        builder: (context, _) {
                          final t = Curves.elasticOut.transform(
                              _checkController.value.clamp(0.0, 1.0));
                          // チェックの色: ゴールド → Primary
                          final color = Color.lerp(
                            _goldColor,
                            theme.colorScheme.primary,
                            _checkController.value,
                          )!;
                          return Transform.scale(
                            scale: t.clamp(0.0, 1.2),
                            child: Icon(
                              Icons.check_circle,
                              size: 56,
                              color: color,
                            ),
                          );
                        },
                      ),
                    // バースト演出
                    if (isComplete)
                      RepaintBoundary(
                        child: AnimatedBuilder(
                          animation: _burstController,
                          builder: (context, _) {
                            // 3色目はライト/ダークで切替（ライトでは白が見えないため）
                            final accent = theme.brightness == Brightness.dark
                                ? Colors.white
                                : theme.colorScheme.tertiary;
                            return CustomPaint(
                              size: const Size(180, 180),
                              painter: _BurstPainter(
                                progress: _burstController.value,
                                primaryColor: theme.colorScheme.primary,
                                goldColor: _goldColor,
                                accentColor: accent,
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
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
              // プログレスバー
              AnimatedBuilder(
                animation: _progressAnimation,
                builder: (context, _) {
                  final value = _progressAnimation.value.clamp(0.0, 1.0);
                  final color = isError
                      ? theme.colorScheme.error
                      : (isComplete
                          ? _goldColor
                          : theme.colorScheme.primary);
                  return LinearProgressIndicator(
                    value: value,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    backgroundColor:
                        theme.colorScheme.surfaceContainerHighest,
                  );
                },
              ),
              const SizedBox(height: 20),
              if (!isComplete && !isError)
                OutlinedButton(
                  onPressed: widget.onBackground,
                  child: Text(widget.l10n.aiRunBackground),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

const Color _goldColor = Color(0xFFFFC107);

/// 完了バースト用のCustomPainter
/// 中央から放射状に20〜30個の小さな円が飛び散ってフェードアウト
class _BurstPainter extends CustomPainter {
  _BurstPainter({
    required this.progress,
    required this.primaryColor,
    required this.goldColor,
    required this.accentColor,
  });

  final double progress;
  final Color primaryColor;
  final Color goldColor;
  final Color accentColor;

  static const _particleCount = 24;
  // 固定シードで毎回同じ動きにする
  static final _seeds = List<({double angle, double speed, int colorIdx})>.generate(
    _particleCount,
    (i) {
      final angle = (i / _particleCount) * 2 * math.pi +
          ((i * 7919) % 100) / 200.0; // 少しランダム
      final speed = 0.6 + ((i * 104729) % 100) / 250.0; // 0.6〜1.0
      return (angle: angle, speed: speed, colorIdx: i % 3);
    },
  );

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;
    final fade = 1.0 - progress; // 進むほど薄く
    final colors = [primaryColor, goldColor, accentColor];

    for (final s in _seeds) {
      final dist = maxRadius * progress * s.speed;
      final dx = center.dx + math.cos(s.angle) * dist;
      final dy = center.dy + math.sin(s.angle) * dist;
      final paint = Paint()
        ..color = colors[s.colorIdx].withValues(alpha: fade.clamp(0.0, 1.0));
      final r = 3.5 + (1.0 - progress) * 2.0;
      canvas.drawCircle(Offset(dx, dy), r, paint);
    }
  }

  @override
  bool shouldRepaint(_BurstPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

/// AI整理実行前のボトムシート（実行日傾向スライダー付き）
class _AiSortBottomSheet extends ConsumerStatefulWidget {
  const _AiSortBottomSheet({required this.l10n});
  final AppLocalizations l10n;

  @override
  ConsumerState<_AiSortBottomSheet> createState() => _AiSortBottomSheetState();
}

class _AiSortBottomSheetState extends ConsumerState<_AiSortBottomSheet> {
  late double _factor;

  @override
  void initState() {
    super.initState();
    _factor = ref.read(executionTimingProvider);
  }

  String _getDescription(double factor) {
    final l10n = widget.l10n;
    if (factor <= 0.1) return l10n.executionTimingDesc0;
    if (factor <= 0.4) return l10n.executionTimingDesc1;
    if (factor <= 0.5) return l10n.executionTimingDesc2;
    if (factor <= 0.7) return l10n.executionTimingDesc3;
    return l10n.executionTimingDesc4;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 32,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Text(l10n.aiSort,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Text(l10n.executionTimingLabel,
              style: TextStyle(
                  fontSize: 14, color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 4),
          Center(
            child: Text(
              _getDescription(_factor),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          Row(
            children: [
              Text(l10n.executionTimingDeadline,
                  style: TextStyle(
                      fontSize: 11, color: theme.colorScheme.outline)),
              Expanded(
                child: Slider(
                  value: _factor,
                  min: 0.0,
                  max: 1.0,
                  divisions: 10,
                  onChanged: (v) {
                    setState(() => _factor = v);
                    ref.read(executionTimingProvider.notifier).setFactor(v);
                  },
                ),
              ),
              Text(l10n.executionTimingEarly,
                  style: TextStyle(
                      fontSize: 11, color: theme.colorScheme.outline)),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => Navigator.of(context).pop(true),
              icon: const Icon(Icons.auto_awesome, size: 18),
              label: Text(l10n.aiSortExecute),
            ),
          ),
        ],
      ),
    );
  }
}
