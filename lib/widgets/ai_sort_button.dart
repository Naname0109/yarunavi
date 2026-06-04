import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../l10n/generated/app_localizations.dart';
import '../services/secure_storage_service.dart';
import '../providers/event_provider.dart';
import 'ai_purchase_bottom_sheet.dart';
import 'ai_sort_tips.dart';
import '../providers/gamification_provider.dart';
import '../providers/purchase_provider.dart';
import '../providers/secure_storage_provider.dart';
import '../providers/sound_provider.dart';
import '../providers/task_provider.dart';
import '../services/ai_service.dart';
import '../services/rewarded_ad_service.dart';
import '../services/sound_service.dart';
import '../utils/category_helper.dart';
import '../utils/constants.dart';
import '../providers/dev_mode_provider.dart';
import '../providers/settings_provider.dart';
import '../utils/feature_gate.dart';
import '../utils/notification_utils.dart';
import 'logo_heartbeat_overlay.dart';

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
  const AiSortButton({super.key, this.builder});

  /// 任意のカスタム描画。null の場合は既存の AppBar 用 TextButton.icon を使う。
  /// HeroAiCard 等から再利用するためのフック。
  final Widget Function(
    BuildContext context,
    bool isLoading,
    VoidCallback? onTap,
  )? builder;

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
    final onTap = _isLoading ? null : () => _onTap(l10n);

    if (widget.builder != null) {
      return widget.builder!(context, _isLoading, onTap);
    }
    return TextButton.icon(
      key: const Key('ai_sort_button'),
      onPressed: onTap,
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

    // #8: AI 整理チケット在庫を先にチェック。 allowed でなくてもチケットがあれば消費。
    // チケット消費パスでは usage count を増やさない (premium 月間 30 回上限を圧迫しない)。
    final ticketsAvailable = await secure.getAiTicketsAvailable();
    if (access != AiSortAccess.allowed && ticketsAvailable > 0) {
      await secure.consumeAiTicket();
      if (!mounted) return;
      final confirmed = await _showAiSortSheet(l10n);
      if (confirmed == true) {
        await _executeAiSort(l10n, locale, skipUsageCount: true);
      }
      return;
    }

    switch (access) {
      case AiSortAccess.allowed:
        if (!mounted) return;
        final confirmed = await _showAiSortSheet(l10n);
        if (confirmed == true) await _executeAiSort(l10n, locale);
      case AiSortAccess.rewardedAdRequired:
        // 「rewarded を見るかどうか」を購入案内シートで提示 (#8 統合)
        if (!mounted) return;
        await _showPurchaseSheet(l10n, locale,
            rewardedAvailable: true, secure: secure);
      case AiSortAccess.rewardedAdUsedToday:
        // 当日 rewarded 使用済み → 購入案内 (premium / チケット のみ)
        if (!mounted) return;
        await _showPurchaseSheet(l10n, locale,
            rewardedAvailable: false, secure: secure);
      case AiSortAccess.premiumMonthlyLimitReached:
        if (!mounted) return;
        await _showPremiumLimitDialog(l10n);
    }
  }

  /// #8: 無料回数なし & チケットなし時の購入案内 BottomSheet。
  Future<void> _showPurchaseSheet(
    AppLocalizations l10n,
    String locale, {
    required bool rewardedAvailable,
    required SecureStorageService secure,
  }) async {
    final lifetime = await secure.getAiTicketLifetimePurchases();
    final rewardedTotal = await secure.getRewardedTotalUsed();
    if (!mounted) return;
    final choice = await AiPurchaseBottomSheet.show(
      context,
      rewardedAvailable: rewardedAvailable,
      ticketLifetime: lifetime,
      rewardedTotalUsed: rewardedTotal,
    );
    if (!mounted || choice == null) return;
    switch (choice) {
      case AiPurchaseChoice.premium:
        context.push('/store');
      case AiPurchaseChoice.ticket:
        await ref.read(purchaseServiceProvider).purchaseAiTicket();
      case AiPurchaseChoice.rewarded:
        await _showRewardedAdDialog(l10n, locale);
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
    bool skipUsageCount = false, // #8: チケット消費パスでは月次/無料枠カウンタを増やさない
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
        AiSortProgressController(incompleteTasks.length);

    // ローディングモーダル表示
    bool backgroundMode = false;
    bool dialogDismissed = false;
    if (!mounted) return;
    // 非同期処理中に State の context が無効化 (mounted=false) されても遷移が
    // 走るよう、 root navigator と go_router 参照を最初に capture しておく。
    final rootNavigator = Navigator.of(context, rootNavigator: true);
    final goRouter = GoRouter.of(context);
    _showLoadingModal(l10n, progressController, () {
      backgroundMode = true;
      dialogDismissed = true;
    });

    // 送信開始 → 0%→5%へ (500ms)
    progressController.setPhase(AiSortPhase.sending);
    // sending 完了直後に awaiting (5%→30%→60%→75% の多段階) を開始
    Future.delayed(const Duration(milliseconds: 500), () {
      progressController.setPhase(AiSortPhase.awaiting);
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
      // #3-3: スケジュール設定を AI に渡す
      final weekdayBusyness =
          ref.read(weekdayBusynessProvider).valueOrNull;
      var blockedDates =
          ref.read(blockedDatesProvider).valueOrNull;

      // #2: avoidEventDays=ON の場合、 予定がある日も blocked_dates 同等に追加。
      // ただし AI プロンプトのトークン消費を抑えるため、
      // 「今日〜AI整理対象タスクの最遠期限日 + 7日」 の範囲だけを採用する。
      final avoidEvent =
          ref.read(avoidEventDaysProvider).valueOrNull ?? false;
      if (avoidEvent && incompleteTasks.isNotEmpty) {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final maxDue = incompleteTasks
            .map((t) => t.dueDate)
            .reduce((a, b) => a.isAfter(b) ? a : b);
        final windowEnd = DateTime(maxDue.year, maxDue.month, maxDue.day)
            .add(const Duration(days: 7));
        final events = ref.read(eventsProvider).valueOrNull ?? const [];
        final eventDates = events
            .map((e) => DateTime(e.date.year, e.date.month, e.date.day))
            .where((d) =>
                !d.isBefore(today) && !d.isAfter(windowEnd))
            .toSet();
        blockedDates = <DateTime>[
          ...(blockedDates ?? const []),
          ...eventDates,
        ];
      }

      final response = await AiService.sortTasks(
        incompleteTasks,
        categoryNames: categoryNames,
        additionalContext: additionalContext,
        executionTimingFactor: timingFactor,
        weekdayBusyness: weekdayBusyness,
        blockedDates: blockedDates,
      );

      // レスポンス受信 → 80%→95%
      progressController.setPhase(AiSortPhase.receiving);

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

      // Safety net 0: AI response に含まれなかった incompleteTask にも
      // デフォルト entry を作る。 後段の「rec==null/due と同じなら前倒し」
      // ロジックに乗せて、 取りこぼし task の rec=null を必ず埋める。
      for (final t in incompleteTasks) {
        if (t.id != null && !updates.containsKey(t.id)) {
          updates[t.id!] = (
            priority: t.priority > 0 ? t.priority : 3,
            aiComment: t.aiComment,
            recommendedDate: t.recommendedDate,
          );
          if (kDebugMode) {
            debugPrint('[AI-DEBUG] AI 未返却 → デフォルト entry: '
                'id=${t.id} title="${t.title}" rec=${t.recommendedDate}');
          }
        }
      }

      // Safety net: recommended_date != due_date を強制保証
      // blocked_dates も避ける (1 度の getBlockedDates 呼び出しで使い回し)
      final now2 = DateTime.now();
      final today2 = DateTime(now2.year, now2.month, now2.day);
      final blockedSet = <String>{
        for (final d in await db.getBlockedDates())
          '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}',
      };
      bool isBlocked(DateTime d) {
        final iso =
            '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
        return blockedSet.contains(iso);
      }
      DateTime avoidBlocked(DateTime d) {
        var probe = d;
        for (var i = 0; i < 30; i++) {
          if (!isBlocked(probe)) return probe;
          probe = probe.subtract(const Duration(days: 1));
          if (probe.isBefore(today2)) return today2;
        }
        return d;
      }
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
          // #3: blocked_dates 回避 (前に向かって 1 日ずつシフト)
          newRec = avoidBlocked(newRec);
          if (kDebugMode) debugPrint('[AI-DEBUG] FORCE FIX: ${taskObj.title} rec→${newRec.toIso8601String().substring(0, 10)}');
          finalUpdates[taskId] = (priority: data.priority, aiComment: data.aiComment, recommendedDate: newRec);
        } else {
          // AI が return した rec が blocked_dates に当たる場合も回避
          final shifted = avoidBlocked(recNorm);
          if (shifted != recNorm) {
            if (kDebugMode) debugPrint('[AI-DEBUG] BLOCKED SHIFT: ${taskObj.title} rec=$recStr→${shifted.toIso8601String().substring(0, 10)}');
            finalUpdates[taskId] = (priority: data.priority, aiComment: data.aiComment, recommendedDate: shifted);
          } else {
            finalUpdates[taskId] = data;
          }
        }
      }

      // ========== SAFETY NET (#6): DB 保存直前の最終防衛線 ==========
      // 上記ループで対処したつもりでも、 タイミングや AI 応答の揺れで
      // rec==due / rec==null が残る可能性に備える。 ここで blocked_dates 回避も
      // 含めて最終調整し、 確実に rec < due になることを保証する。
      // 手動指定された taskId はそのまま (skipManualDateIds で守る)。
      // 注意: `due` には時刻が含まれることがあるため、 比較・減算は dueNorm
      // (時刻 0:00 正規化) を使う。
      final blockedDateSet =
          (await db.getBlockedDates()).map((d) => d.toIso8601String().substring(0, 10)).toSet();
      final safetyKeys = finalUpdates.keys.toList(growable: false);
      for (final taskId in safetyKeys) {
        if (skipManualDateIds.contains(taskId)) continue;
        final update = finalUpdates[taskId]!;
        final taskMatch = incompleteTasks.where((t) => t.id == taskId);
        if (taskMatch.isEmpty) continue;
        final task = taskMatch.first;
        final rec = update.recommendedDate;
        final due = task.dueDate;
        final dueNorm = DateTime(due.year, due.month, due.day);

        bool needsFix = false;
        if (rec == null) {
          needsFix = true;
          if (kDebugMode) debugPrint('[SAFETY] ${task.title}: rec is NULL');
        } else {
          final recNorm = DateTime(rec.year, rec.month, rec.day);
          if (recNorm == dueNorm) {
            needsFix = true;
            if (kDebugMode) {
              debugPrint('[SAFETY] ${task.title}: rec == due ($recNorm)');
            }
          }
        }
        if (!needsFix) continue;

        final daysLeft = dueNorm.difference(today2).inDays;
        int daysBack;
        if (daysLeft <= 0) {
          daysBack = 0;
        } else if (daysLeft == 1) {
          daysBack = 0;
        } else if (daysLeft <= 3) {
          daysBack = 1;
        } else if (daysLeft <= 7) {
          daysBack = 2;
        } else if (daysLeft <= 14) {
          daysBack = 4;
        } else {
          daysBack = 7;
        }
        var newRec = dueNorm.subtract(Duration(days: daysBack));
        if (newRec.isBefore(today2)) newRec = today2;
        // blocked_dates 回避 (最大 30 日まで遡って空き日を探す)
        var retry = 30;
        while (blockedDateSet
                .contains(newRec.toIso8601String().substring(0, 10)) &&
            retry > 0) {
          newRec = newRec.subtract(const Duration(days: 1));
          if (newRec.isBefore(today2)) {
            newRec = today2;
            break;
          }
          retry--;
        }
        finalUpdates[taskId] = (
          priority: update.priority,
          aiComment: update.aiComment,
          recommendedDate: newRec,
        );
        if (kDebugMode) {
          debugPrint(
              '[SAFETY] ${task.title}: FIXED rec=$newRec (dueNorm=$dueNorm, daysLeft=$daysLeft)');
        }
      }
      // ========== END SAFETY NET ==========

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
          debugPrint('[FINAL-CHECK] ${t.title}: rec=$recStr due=$dueStr ${same ? "⚠️SAME" : "✅OK"} comment=$commentPreview');
        }
        debugPrint('[DB-SAVE] ===================================');
      }

      await db.updateTaskPriorities(finalUpdates,
          skipRecommendedDateIds: skipManualDateIds);

      // 保存直後に DB から読み直して [AI-READ] で検証 (rec/due/priority)
      if (kDebugMode) {
        final saved = await db.getAllTasks();
        debugPrint('[AI-READ] ===== DB 保存後 readback =====');
        for (final t in saved.where((s) => !s.isCompleted)) {
          final rec = t.recommendedDate;
          final due = t.dueDate;
          final isSame = rec != null &&
              rec.year == due.year &&
              rec.month == due.month &&
              rec.day == due.day;
          final mark = isSame ? '⚠️SAME' : (rec == null ? '⚠️NULL' : '✅OK');
          debugPrint('[AI-READ] $mark ${t.title}: rec=$rec due=$due pri=${t.priority}');
        }
        debugPrint('[AI-READ] ================================');
      }

      // プレミアム: AIのnotify_dateで自動通知スケジュール (手動設定済みは尊重)
      final isPremium = ref.read(isPremiumProvider);
      final notifyService = ref.read(notificationServiceProvider);
      if (isPremium) {
        // #6-1 実行日通知: finalUpdates 全件 (= AI response 取りこぼし含む)
        // で recommended_date 朝 9 時の通知を再スケジュール。
        for (final entry in finalUpdates.entries) {
          final taskId = entry.key;
          final newRec = entry.value.recommendedDate;
          final task =
              incompleteTasks.where((t) => t.id == taskId).firstOrNull;
          if (task == null) continue;
          final taskForExec = newRec != null
              ? task.copyWith(recommendedDate: newRec)
              : task;
          await notifyService.scheduleExecutionDayNotification(
            taskForExec,
            isPremium: true,
            locale: locale,
          );
        }

        // AI 推奨 notify_date による事前通知 (AI return 分のみ)
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
          // #6: 列指定 UPDATE で notify_settings だけ書く。
          // task.copyWith() + updateTask だと、 古いスナップショットの
          // recommended_date が SAFETY NET の修正を上書きしてしまうため。
          if (task.id != null) {
            await db.updateTaskNotifySettings(
              task.id!,
              jsonEncode(['ai_auto']),
            );
          }
        }
      }

      if (isRealApiCall) {
        await db.recordAiUsage();
        if (!skipUsageCount) {
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
      }

      // AI履歴に保存
      await db.insertAiHistory(
        summaryJa: response.summaryJa,
        summaryEn: response.summaryEn,
        resultJson: jsonEncode(response.toJson()),
        taskCount: response.tasks.length,
      );

      // 90% → 100% (DB保存完了、500ms)
      progressController.setPhase(AiSortPhase.finalizing);
      debugPrint('[AI-FLOW] finalizing → 550ms hold');
      await Future.delayed(const Duration(milliseconds: 550));

      // 100%到達 → 完了演出
      // 演出タイムライン (合計 ~1500ms):
      //   t=0       バーが Gold に変化 (300ms transition) + heavyImpact
      //   t=120ms   バースト発射 (500ms) + mediumImpact
      //   t=350ms   チェックマーク登場 (500ms elasticOut) + lightImpact + サウンド
      //   t=350ms以降 余韻 → 1500ms 後に画面遷移
      progressController.setPhase(AiSortPhase.complete);
      debugPrint('[AI-FLOW] setPhase(complete)');

      // 視覚に同期したハプティクス + サウンド
      final sound = ref.read(soundServiceProvider);
      unawaited(sound.playHaptic(SoundEvent.aiSortComplete));
      // システムサウンドはチェックマーク登場の瞬間に合わせる
      Future.delayed(const Duration(milliseconds: 350), () {
        unawaited(sound.playSystemSound(SoundEvent.aiSortComplete));
      });

      // 結果をProviderに保存
      ref.read(aiSortResponseProvider.notifier).state = response;
      ref.invalidate(tasksProvider);

      ref.read(calendarHighlightProvider.notifier).state = true;
      ref.read(aiHistoryBadgeProvider.notifier).state = true;

      // 演出の余韻を保ってから遷移
      // (バー Gold 0.3s + バースト 0.5s + チェック 0.5s + ホールド 0.2s = 1.5s)
      debugPrint('[AI-FLOW] 演出開始 → 1500ms hold');
      await Future.delayed(const Duration(milliseconds: 1500));
      debugPrint('[AI-FLOW] 演出完了 (mounted=$mounted dismissed=$dialogDismissed)');

      // モーダルを閉じる。 release で State が unmount される race を避け、
      // 起動時に capture した rootNavigator を直接呼ぶ (mounted 不要)。
      if (!dialogDismissed) {
        try {
          rootNavigator.popUntil((route) => route is PageRoute);
        } catch (e) {
          debugPrint('[AI-FLOW] popUntil exception: $e');
        }
        dialogDismissed = true;
        debugPrint('[AI-FLOW] ダイアログ閉じ');
      }

      // ダイアログ pop のアニメーションが完了するまで少し待つ。
      // これを入れないと pop と直後の push('/ai-result') が同一フレームで
      // 競合し、 結果画面が出ない/フリーズする場合がある。
      await Future.delayed(const Duration(milliseconds: 300));

      // フォールバック時はSnackbarで通知（API未設定時のみ走るパス）
      if (response.isFallback && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.aiFallbackNotice)),
        );
      }

      if (backgroundMode) {
        ref.read(aiCompleteBannerProvider.notifier).state = true;
        debugPrint('[AI-FLOW] backgroundMode banner shown');
      } else {
        // capture した goRouter を使用 (mounted=false でも遷移可能)
        debugPrint('[AI-FLOW] 結果画面遷移');
        goRouter.push('/ai-result');
        debugPrint('[AI-FLOW] push 完了');
      }

      // ゲーミフィケーション (XP/バッジ/レベルアップ) と レビュー依頼は、
      // **遷移完了後** に発火する。 LoadingDialog 表示中に LevelUpOverlay や
      // BadgeUnlockPopup が showDialog でスタックに乗ると、 後続の pop / push
      // と競合して画面が固まることがあったため。
      unawaited(
        ref
            .read(userStatsProvider.notifier)
            .recordAiSort(taskCount: incompleteTasks.length)
            .catchError((Object e, StackTrace st) {
          debugPrint('[AiSort] gamification 記録失敗: $e');
        }),
      );
      final reviewService = ref.read(reviewServiceProvider);
      unawaited(reviewService.incrementAiSortCount());
      Future.delayed(const Duration(seconds: 5), () {
        reviewService.requestReviewIfEligible();
      });
    } on AiServiceException catch (e) {
      // エラー時: プログレスバーを赤色フェードアウト + エラーハプティクスパターン
      progressController.setPhase(AiSortPhase.error);
      final sound = ref.read(soundServiceProvider);
      unawaited(sound.playHaptic(SoundEvent.aiSortError));
      await Future.delayed(const Duration(milliseconds: 600));

      if (mounted && !dialogDismissed) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      if (!mounted) return;
      await _showAiErrorDialog(l10n, e.type);
    } catch (e, st) {
      debugPrint('[AiSort] unexpected error: $e');
      debugPrint('[AiSort] stackTrace: $st');
      progressController.setPhase(AiSortPhase.error);
      final sound = ref.read(soundServiceProvider);
      unawaited(sound.playHaptic(SoundEvent.aiSortError));
      await Future.delayed(const Duration(milliseconds: 600));
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
    AiSortProgressController controller,
    VoidCallback onBackground,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AiLoadingDialog(
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

    // 広告準備: 未ロードならローディングダイアログ表示 + 最大10秒待機 + リトライ
    if (!_rewardedAdService.isReady) {
      // ローディングダイアログを表示
      bool dialogPopped = false;
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogCtx) => AlertDialog(
          content: Row(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 16),
              Expanded(child: Text(l10n.aiRewardedAdLoading)),
            ],
          ),
        ),
      ).then((_) => dialogPopped = true);

      // プリロード開始 + 最大10秒待機 (500ms × 20回)
      // ignore: unawaited_futures
      _rewardedAdService.preload();
      for (var i = 0; i < 20; i++) {
        await Future.delayed(const Duration(milliseconds: 500));
        if (_rewardedAdService.isReady) break;
        if (!mounted) return;
      }

      // ローディングダイアログを閉じる
      if (!dialogPopped && mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    }

    if (!_rewardedAdService.isReady) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.aiRewardedAdLoadFailed),
          duration: const Duration(seconds: 4),
        ),
      );
      return;
    }

    final rewarded = await _rewardedAdService.show();
    if (!rewarded || !mounted) return;

    // リワード成功 → 累計使用カウンタを進める (#4: 生涯 2 回まで)
    final secure = ref.read(secureStorageServiceProvider);
    await secure.recordRewardedUsage();
    await secure.incrementRewardedTotalUsed();

    // skipUsageCount: リワード動画視聴 = free 枠を 1 回追加した形なので、
    // _executeAiSort 内で incrementLifetimeFreeUsage が走っても整合する
    await _executeAiSort(l10n, locale);
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
enum AiSortPhase {
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
class AiSortProgressController extends ChangeNotifier {
  AiSortProgressController(this.taskCount, {this.isRefine = false});

  final int taskCount;

  /// #2: 再整理 (refineWithAnswers) は初回より所要時間が短いので速めに進める。
  final bool isRefine;
  AiSortPhase _phase = AiSortPhase.sending;

  AiSortPhase get phase => _phase;

  /// awaiting フェーズの3段階の所要時間 (ms)。
  /// stage1: 5% → 30%、stage2: 30% → 60% (stage1の1.5倍)、stage3: 60% → 75% (stage1の2倍)。
  /// 再整理時は固定で短め (合計 約 5 秒) にする。
  ({int stage1Ms, int stage2Ms, int stage3Ms}) get awaitingStageMs {
    if (isRefine) {
      return (stage1Ms: 1500, stage2Ms: 1800, stage3Ms: 2200);
    }
    final s1 = taskCount <= 5
        ? 8000
        : (taskCount <= 10 ? 12000 : 18000);
    return (
      stage1Ms: s1,
      stage2Ms: (s1 * 1.5).round(),
      stage3Ms: s1 * 2,
    );
  }

  void setPhase(AiSortPhase newPhase) {
    if (_phase == newPhase) return;
    _phase = newPhase;
    notifyListeners();
  }
}

/// AI整理中ローディングダイアログ
class AiLoadingDialog extends StatefulWidget {
  const AiLoadingDialog({
    super.key,
    required this.l10n,
    required this.controller,
    required this.onBackground,
  });

  final AppLocalizations l10n;
  final AiSortProgressController controller;
  final VoidCallback onBackground;

  @override
  State<AiLoadingDialog> createState() => _AiLoadingDialogState();
}

class _AiLoadingDialogState extends State<AiLoadingDialog>
    with TickerProviderStateMixin {
  int _messageIndex = 0;
  // stage3 (60%→75%、最後の遅いレーン) に入ったらメッセージを「もう少しで完了します」に固定
  bool _stage3Reached = false;
  late final AnimationController _pulseController;
  late final AnimationController _progressController;
  late final AnimationController _barColorController; // バー色 Primary → Gold (300ms)
  late final AnimationController _barFlashController; // バー上の白フラッシュ (400ms)
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

    _barColorController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _barFlashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _burstController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _checkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
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
      if (!mounted || _stage3Reached) return;
      setState(() {
        _messageIndex = (_messageIndex + 1) % _messages.length;
      });
      _cycleMessages();
    });
  }

  void _onPhaseChange() {
    if (!mounted) return;
    final phase = widget.controller.phase;
    switch (phase) {
      case AiSortPhase.sending:
        // 0% → 5% (0.5秒、即ジャンプ感)
        _animateProgress(
            to: 0.05, duration: const Duration(milliseconds: 500));
      case AiSortPhase.awaiting:
        // 5% → 30% → 60% → 75% を3段階で順次進める
        _animateAwaitingSequence();
      case AiSortPhase.receiving:
        // 現在位置 → 90% (0.8秒)
        _animateProgress(
            to: 0.90, duration: const Duration(milliseconds: 800));
      case AiSortPhase.finalizing:
        // 90% → 100% (0.5秒)
        _animateProgress(
            to: 1.0, duration: const Duration(milliseconds: 500));
      case AiSortPhase.complete:
        // ステップ1 (t=0): プログレスバーを 100% に固定し、Primary → Gold へ
        _animateProgress(
            to: 1.0, duration: const Duration(milliseconds: 80));
        _barColorController.forward(from: 0);
        _barFlashController.forward(from: 0);
        // ステップ2 (t≈120ms): バースト発射
        Future.delayed(const Duration(milliseconds: 120), () {
          if (mounted) _burstController.forward(from: 0);
        });
        // ステップ3 (t≈350ms): チェックマーク登場 + リング拡散
        Future.delayed(const Duration(milliseconds: 350), () {
          if (mounted) _checkController.forward(from: 0);
        });
      case AiSortPhase.error:
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

  /// awaiting フェーズの3段階アニメーション
  /// 5%→30% (stage1) → 30%→60% (stage1×1.5) → 60%→75% (stage1×2)
  /// レスポンスが受信されてフェーズが変わったら自動で停止
  Future<void> _animateAwaitingSequence() async {
    final stages = widget.controller.awaitingStageMs;

    bool stillAwaiting() =>
        mounted && widget.controller.phase == AiSortPhase.awaiting;

    // stage1: 5% → 30%
    _animateProgress(
      to: 0.30,
      duration: Duration(milliseconds: stages.stage1Ms),
    );
    await Future.delayed(Duration(milliseconds: stages.stage1Ms));
    if (!stillAwaiting()) return;

    // stage2: 30% → 60% (より遅く)
    _animateProgress(
      to: 0.60,
      duration: Duration(milliseconds: stages.stage2Ms),
    );
    await Future.delayed(Duration(milliseconds: stages.stage2Ms));
    if (!stillAwaiting()) return;

    // stage3: 60% → 75% (さらに遅く、停止して待機)
    // メッセージを「もう少しで完了します...」に固定して停止感を軽減
    if (mounted) {
      setState(() {
        _stage3Reached = true;
        _messageIndex = _messages.length - 1; // aiLoadingAlmost
      });
    }
    _animateProgress(
      to: 0.75,
      duration: Duration(milliseconds: stages.stage3Ms),
    );
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onPhaseChange);
    _pulseController.dispose();
    _progressController.dispose();
    _barColorController.dispose();
    _barFlashController.dispose();
    _burstController.dispose();
    _checkController.dispose();
    _errorFadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final phase = widget.controller.phase;
    final isComplete = phase == AiSortPhase.complete;
    final isError = phase == AiSortPhase.error;
    final isDark = theme.brightness == Brightness.dark;
    // ライトモードでは白が消えるため tertiary に差し替え
    final accentParticle = isDark ? Colors.white : theme.colorScheme.tertiary;

    return Dialog(
      child: FadeTransition(
        opacity: _errorFadeController,
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // アイコン: 通常時はパルス、完了時はチェック + リング + バースト
              SizedBox(
                height: 96,
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    // 1. バースト (チェックの背後で先に展開)
                    if (isComplete)
                      RepaintBoundary(
                        child: AnimatedBuilder(
                          animation: _burstController,
                          builder: (context, _) {
                            return CustomPaint(
                              size: const Size(220, 220),
                              painter: AiSortBurstPainter(
                                progress: _burstController.value,
                                primaryColor: theme.colorScheme.primary,
                                goldColor: kAiGoldColor,
                                accentColor: accentParticle,
                              ),
                            );
                          },
                        ),
                      ),
                    // 2. 光のリング (チェックの直前に拡散してフェード)
                    if (isComplete)
                      AnimatedBuilder(
                        animation: _checkController,
                        builder: (context, _) {
                          final t = _checkController.value;
                          // 立ち上がりは易しく、終盤フェードアウト
                          final ringT = Curves.easeOutCubic.transform(t);
                          final size = 40.0 + ringT * 64.0;
                          final alpha = (1.0 - ringT) * 0.75;
                          if (alpha <= 0) return const SizedBox.shrink();
                          return Container(
                            width: size,
                            height: size,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: kAiGoldColor.withValues(alpha: alpha),
                                width: 2.5,
                              ),
                            ),
                          );
                        },
                      ),
                    // 3. パルスアイコン (通常時)
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
                    // 4. チェックマーク (完了時、elasticOutでバウンス)
                    if (isComplete)
                      AnimatedBuilder(
                        animation: _checkController,
                        builder: (context, _) {
                          final v = _checkController.value;
                          // elasticOutで 0→1.2→1.0 を実現 (clampでオーバーシュート維持)
                          final scale = Curves.elasticOut
                              .transform(v.clamp(0.0, 1.0))
                              .clamp(0.0, 1.2);
                          final color = Color.lerp(
                            kAiGoldColor,
                            theme.colorScheme.primary,
                            v,
                          )!;
                          return Opacity(
                            opacity: v.clamp(0.0, 1.0),
                            child: Transform.scale(
                              scale: scale,
                              child: Icon(
                                Icons.check_circle,
                                size: 64,
                                color: color,
                              ),
                            ),
                          );
                        },
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
              // プログレスバー (グロウ + フラッシュオーバーレイ付き)
              _buildProgressBar(theme, isComplete, isError),
              const SizedBox(height: 16),
              // #3: AI 整理中の Tips カード
              if (!isError)
                AnimatedBuilder(
                  animation: _progressAnimation,
                  builder: (context, _) {
                    final progress = _progressAnimation.value.clamp(0.0, 1.0);
                    return AiSortTipsCard(progress: progress);
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

  /// グロウ + フラッシュ付きのプログレスバー
  Widget _buildProgressBar(ThemeData theme, bool isComplete, bool isError) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _progressAnimation,
        _barColorController,
        _barFlashController,
      ]),
      builder: (context, _) {
        final value = _progressAnimation.value.clamp(0.0, 1.0);
        // 色は AnimationController で Primary → Gold に滑らかに遷移
        final Color color;
        if (isError) {
          color = theme.colorScheme.error;
        } else {
          color = Color.lerp(
            theme.colorScheme.primary,
            kAiGoldColor,
            _barColorController.value,
          )!;
        }
        // 完了時のグロウ (BoxShadow)
        final glowStrength = isComplete ? _barColorController.value : 0.0;
        // 上を一瞬走る白いフラッシュ
        final flashOpacity =
            isComplete ? _barFlashIntensity(_barFlashController.value) : 0.0;

        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            boxShadow: glowStrength > 0
                ? [
                    BoxShadow(
                      color: kAiGoldColor.withValues(alpha: 0.5 * glowStrength),
                      blurRadius: 16 * glowStrength,
                      spreadRadius: 1.0 * glowStrength,
                    ),
                  ]
                : const [],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 8,
              child: Stack(
                children: [
                  LinearProgressIndicator(
                    value: value,
                    minHeight: 8,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    backgroundColor:
                        theme.colorScheme.surfaceContainerHighest,
                  ),
                  if (flashOpacity > 0)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                Colors.white.withValues(alpha: 0),
                                Colors.white.withValues(alpha: flashOpacity),
                                Colors.white.withValues(alpha: 0),
                              ],
                              stops: const [0.0, 0.5, 1.0],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// フラッシュ強度: 0→0.5でピーク、0.5→1で減衰
  double _barFlashIntensity(double t) {
    if (t <= 0) return 0;
    if (t < 0.5) return (t * 2) * 0.6; // 0 → 0.6
    return (1.0 - (t - 0.5) * 2) * 0.6; // 0.6 → 0
  }
}

const Color kAiGoldColor = Color(0xFFFFC107);

/// パーティクル形状
enum _AiBurstShape { circle, sparkle, line }

/// パーティクルのシード（事前生成して毎回同じ動きを保証）
class _AiBurstSeed {
  const _AiBurstSeed({
    required this.angle,
    required this.speed,
    required this.colorIdx,
    required this.shape,
    required this.size,
    required this.rotation,
    required this.curve,
  });
  final double angle;
  final double speed;
  final int colorIdx;
  final _AiBurstShape shape;
  final double size;
  final double rotation;
  /// 距離カーブの選択（0=easeOutCubic, 1=easeOutQuart）
  final int curve;
}

/// 完了バースト用のCustomPainter
/// 中央の光のフラッシュ + 30個のパーティクル
/// (円 14個 / 4方向スパークル 10個 / 光の筋 6本)
class AiSortBurstPainter extends CustomPainter {
  AiSortBurstPainter({
    required this.progress,
    required this.primaryColor,
    required this.goldColor,
    required this.accentColor,
  });

  final double progress;
  final Color primaryColor;
  final Color goldColor;
  final Color accentColor;

  static const _particleCount = 30;
  static final List<_AiBurstSeed> _seeds = _generateSeeds();

  static List<_AiBurstSeed> _generateSeeds() {
    final rng = math.Random(20260511);
    return List<_AiBurstSeed>.generate(_particleCount, (i) {
      // 角度は均等に散らしつつ若干のランダム性
      final baseAngle = (i / _particleCount) * 2 * math.pi;
      final jitter = (rng.nextDouble() - 0.5) * 0.5;
      // 形状の振り分け: 14円 / 10星 / 6線
      final _AiBurstShape shape;
      if (i < 14) {
        shape = _AiBurstShape.circle;
      } else if (i < 24) {
        shape = _AiBurstShape.sparkle;
      } else {
        shape = _AiBurstShape.line;
      }
      // 色: 円は Primary/Gold/Accent をローテーション、星は Gold 多め
      final colorIdx = shape == _AiBurstShape.sparkle
          ? (i.isEven ? 1 : 2)
          : i % 3;
      return _AiBurstSeed(
        angle: baseAngle + jitter,
        // 速度の幅を広く: 0.55〜1.15 で「速い遠飛び」と「近くでフワッ」が混在
        speed: 0.55 + rng.nextDouble() * 0.6,
        colorIdx: colorIdx,
        shape: shape,
        size: shape == _AiBurstShape.circle
            ? 3.0 + rng.nextDouble() * 2.0
            : shape == _AiBurstShape.sparkle
                ? 5.0 + rng.nextDouble() * 2.5
                : 12.0 + rng.nextDouble() * 8.0,
        rotation: rng.nextDouble() * 2 * math.pi,
        curve: rng.nextInt(2),
      );
    });
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2.2;
    final colors = [primaryColor, goldColor, accentColor];

    // --- 中央の光のフラッシュ (前半 0〜35% でピーク後フェード) ---
    if (progress < 0.5) {
      final flashT = (progress / 0.5).clamp(0.0, 1.0);
      // ピーク 0.2 で最大、その後減衰
      final flashAlpha = flashT < 0.2
          ? flashT / 0.2
          : (1.0 - (flashT - 0.2) / 0.8);
      final flashRadius = 12 + flashT * 28;
      final flashPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            goldColor.withValues(alpha: 0.55 * flashAlpha),
            goldColor.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: flashRadius));
      canvas.drawCircle(center, flashRadius, flashPaint);
    }

    for (final s in _seeds) {
      // 距離カーブ: 立ち上がりが急で後半ゆっくり (爆発感)
      final distT = s.curve == 0
          ? Curves.easeOutCubic.transform(progress)
          : Curves.easeOutQuart.transform(progress);
      final dist = maxRadius * distT * s.speed;
      final dx = center.dx + math.cos(s.angle) * dist;
      final dy = center.dy + math.sin(s.angle) * dist;

      // フェード: 開始時不透明 → 終盤で消える
      // 前半は満タン、60% を超えたあたりから減衰
      final fade = progress < 0.6
          ? 1.0
          : (1.0 - (progress - 0.6) / 0.4).clamp(0.0, 1.0);
      final color = colors[s.colorIdx].withValues(alpha: fade);
      final paint = Paint()..color = color;

      switch (s.shape) {
        case _AiBurstShape.circle:
          // 進むほど少しだけ縮む
          final r = s.size * (1.0 - progress * 0.2);
          canvas.drawCircle(Offset(dx, dy), r, paint);
        case _AiBurstShape.sparkle:
          _drawSparkle(canvas, Offset(dx, dy), s.size, paint,
              s.rotation + progress * math.pi);
        case _AiBurstShape.line:
          // 光の筋: 中心から離れる方向に細い直線
          final strokePaint = Paint()
            ..color = color
            ..strokeWidth = 1.5
            ..strokeCap = StrokeCap.round
            ..style = PaintingStyle.stroke;
          final back = s.size * (1.0 - progress * 0.5);
          final startX = dx - math.cos(s.angle) * back;
          final startY = dy - math.sin(s.angle) * back;
          canvas.drawLine(Offset(startX, startY), Offset(dx, dy), strokePaint);
      }
    }
  }

  /// 4方向のスパークル(きらめき)を描画
  void _drawSparkle(
      Canvas canvas, Offset center, double size, Paint paint, double rotation) {
    final path = Path();
    final s = size;
    // 4芒星: 長軸4 / 短軸 s*0.3
    path.moveTo(0, -s);
    path.lineTo(s * 0.3, -s * 0.3);
    path.lineTo(s, 0);
    path.lineTo(s * 0.3, s * 0.3);
    path.lineTo(0, s);
    path.lineTo(-s * 0.3, s * 0.3);
    path.lineTo(-s, 0);
    path.lineTo(-s * 0.3, -s * 0.3);
    path.close();

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);
    canvas.drawPath(path, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(AiSortBurstPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.primaryColor != primaryColor ||
      oldDelegate.goldColor != goldColor ||
      oldDelegate.accentColor != accentColor;
}

/// AI整理の進捗ダイアログを、実APIを呼ばずに「成功」または「指定エラー」で
/// 再生するデバッグ用プレビュー関数。
///
/// - [taskCount] でタスク数を渡すと awaiting フェーズの所要時間が
///   5/8/12秒のどれかに切り替わる
/// - [simulateError] を指定するとエラー演出 (赤フェード+ダイアログ) を再生
Future<void> showAiSortPreviewDialog(
  BuildContext context, {
  required AppLocalizations l10n,
  required int taskCount,
  AiErrorType? simulateError,
  SoundService? sound,
}) async {
  final controller = AiSortProgressController(taskCount);
  bool dialogClosed = false;

  // ダイアログを「閉じる」ためのハンドラ。awaitしないで先に show する
  unawaited(showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AiLoadingDialog(
      l10n: l10n,
      controller: controller,
      onBackground: () {
        dialogClosed = true;
        Navigator.of(ctx).pop();
      },
    ),
  ).then((_) => dialogClosed = true));

  try {
    // 送信 → awaiting
    controller.setPhase(AiSortPhase.sending);
    await Future.delayed(const Duration(milliseconds: 500));
    if (dialogClosed) return;
    controller.setPhase(AiSortPhase.awaiting);

    if (simulateError != null) {
      // awaiting stage1 の途中で打ち切ってエラー演出
      await Future.delayed(const Duration(milliseconds: 3000));
      if (dialogClosed) return;
      controller.setPhase(AiSortPhase.error);
      if (sound != null) {
        unawaited(sound.playHaptic(SoundEvent.aiSortError));
      }
      await Future.delayed(const Duration(milliseconds: 650));
      if (!dialogClosed && context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        dialogClosed = true;
      }
      if (context.mounted) {
        final (title, body) = switch (simulateError) {
          AiErrorType.network =>
            (l10n.aiErrorNetworkTitle, l10n.aiErrorNetworkBody),
          AiErrorType.rateLimit =>
            (l10n.aiErrorRateLimitTitle, l10n.aiErrorRateLimitBody),
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
      return;
    }

    // 成功シナリオ: awaiting stage1+stage2 程度を見たら receiving へ
    // (75% 到達まで待つと長過ぎるので、stage1 を待ってから受信させる)
    final stages = controller.awaitingStageMs;
    await Future.delayed(Duration(milliseconds: stages.stage1Ms));
    if (dialogClosed) return;
    controller.setPhase(AiSortPhase.receiving);
    await Future.delayed(const Duration(milliseconds: 800));
    if (dialogClosed) return;
    controller.setPhase(AiSortPhase.finalizing);
    await Future.delayed(const Duration(milliseconds: 550));
    if (dialogClosed) return;
    controller.setPhase(AiSortPhase.complete);
    if (sound != null) {
      unawaited(sound.playHaptic(SoundEvent.aiSortComplete));
      Future.delayed(const Duration(milliseconds: 350), () {
        unawaited(sound.playSystemSound(SoundEvent.aiSortComplete));
      });
    }
    // ロゴ鼓動演出を発火 (本番の _executeAiSort と同じタイミング)
    Future.delayed(const Duration(milliseconds: 600), () {
      if (context.mounted) LogoHeartbeatOverlay.show(context);
    });
    await Future.delayed(const Duration(milliseconds: 1500));
  } finally {
    if (!dialogClosed && context.mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    }
    controller.dispose();
  }
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
