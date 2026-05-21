import 'dart:math' as math;

import '../models/task.dart';
import '../models/user_badge.dart';
import '../models/user_stats.dart';
import 'database_service.dart';
import 'secure_storage_service.dart';

/// 1 日あたりのタスク完了 XP の上限 (#2-B: 不正稼ぎ抑止)。
const int kDailyTaskXpCap = 200;

/// タスク作成から完了までの最小経過時間。 これ未満は XP 付与しない (#2-B)。
const Duration kMinTaskAge = Duration(seconds: 60);

/// ゲーミフィケーション基盤サービス。XP/レベル/ストリーク/バッジ判定を一括管理。
///
/// 呼び出し側 (TasksNotifier 等) は基本的に以下のみ使う:
/// - [onTaskCompleted] : タスク完了時
/// - [onAiSorted]      : AI整理実行時
/// - [touchActivity]   : アプリ操作（XPを伴わない活動）でストリーク維持
class GamificationService {
  GamificationService(this._db, {SecureStorageService? secureStorage})
      : _secure = secureStorage;
  final DatabaseService _db;
  final SecureStorageService? _secure;

  /// Lv.1〜10 に必要な累計XP (個別指定)。
  /// Lv.11 以降は [_levelCheckpoints] 間を線形補間して算出 (Lv.100 で 116000 XP)。
  static const List<int> _baseLevelXp = <int>[
    0, // Lv.1
    30, // Lv.2 (+30)
    80, // Lv.3 (+50)
    160, // Lv.4 (+80)
    300, // Lv.5 (+140)
    500, // Lv.6 (+200)
    800, // Lv.7 (+300)
    1200, // Lv.8 (+400)
    1760, // Lv.9 (+560)
    2544, // Lv.10 (+784)
  ];

  /// Lv.11+ の補間用チェックポイント (累計 XP)。 仕様の到達目安表に合わせて
  /// Lv.10 (2544) から Lv.100 (116000) まで非線形に成長。
  static const Map<int, int> _levelCheckpoints = <int, int>{
    10: 2544,
    20: 11500,
    30: 17500,
    50: 35500,
    70: 61500,
    100: 116000,
  };

  // ====== Public: Reads ======

  Future<UserStats> getStats() async {
    final row = await _db.getUserStats();
    if (row == null) {
      throw StateError('user_stats not initialized (run DB migration v11)');
    }
    return UserStats.fromMap(row);
  }

  /// #2-D: 起動時 1 回呼ぶ。 Keychain バックアップと DB を比較し、
  /// Keychain の方が大きければ (= 再 install 等で DB がクリアされた状態) DB を書き戻す。
  /// バックアップが小さければ DB の値で Keychain を更新。
  Future<void> reconcileTotalXpBackup() async {
    if (_secure == null) return;
    final stats = await getStats();
    final backup = await _secure.getTotalXpBackup();
    if (backup > stats.totalXp) {
      final restoredLevel = levelFromXp(backup);
      await _db.updateUserStats({
        'total_xp': backup,
        'current_level': restoredLevel,
      });
    } else if (stats.totalXp > backup) {
      await _secure.updateTotalXpBackup(stats.totalXp);
    }
  }

  Future<List<UserBadge>> getBadges() async {
    final rows = await _db.getAllBadges();
    return rows.map(UserBadge.fromMap).toList();
  }

  /// 過去N日のアクティビティ件数（ヒートマップ用）。
  Future<Map<String, int>> getActivityHeatmap({int days = 14}) =>
      _db.getActivityCountByDay(days: days);

  // ====== Public: 主要イベント ======

  /// タスク完了時の包括処理。
  ///
  /// - +10 XP / 全完了なら +25 ボーナス / ストリーク維持 / バッジ判定
  /// - 累計タスク完了数を +1
  ///
  /// XP 不正取得対策 (#2):
  /// - B: [task] の作成 1 分以内 (kMinTaskAge) は XP 付与しない
  /// - B: 当日獲得 XP が kDailyTaskXpCap 以上なら以降スキップ
  /// - E: 全完了ボーナス (all_today_done) は 1 日 1 回まで
  Future<TaskCompleteResult> onTaskCompleted({
    required bool isAllTodayDone,
    required Task task,
  }) async {
    final stats = await getStats();
    final xpEvents = <XpAwardResult>[];
    final earned = <UserBadge>[];

    final newCompleted = stats.totalTasksCompleted + 1;
    await _db.updateUserStats({'total_tasks_completed': newCompleted});

    // #2-B: 作成 → 完了 が短すぎる / 1 日上限超過 ならベース XP 付与しない
    final completedAt = task.completedAt ?? DateTime.now();
    final age = completedAt.difference(task.createdAt);
    final todayXp = await _db.getTodayXpTotal();
    final tooFresh = age < kMinTaskAge;
    final overCap = todayXp >= kDailyTaskXpCap;
    if (!tooFresh && !overCap) {
      final base = await _award(amount: 10, reason: 'task_complete');
      xpEvents.add(base);
      earned.addAll(base.newlyEarnedBadges);
    }

    // #2-E: all_today_done は当日まだ付与していない場合のみ
    if (isAllTodayDone && !await _db.hasXpReasonToday('all_today_done')) {
      final bonus = await _award(amount: 25, reason: 'all_today_done');
      xpEvents.add(bonus);
      earned.addAll(bonus.newlyEarnedBadges);
    }

    // 完了数バッジ
    Future<void> tryBadge(String id, int threshold) async {
      if (newCompleted >= threshold && await _db.markBadgeEarned(id)) {
        earned.add(UserBadge(
          id: id,
          isEarned: true,
          earnedAt: DateTime.now(),
        ));
      }
    }

    await tryBadge('first_step', 1);
    await tryBadge('task_10', 10);
    await tryBadge('task_25', 25);
    await tryBadge('task_50', 50);
    await tryBadge('task_100', 100);
    await tryBadge('task_250', 250);
    await tryBadge('task_500', 500);
    await tryBadge('task_1000', 1000);

    // ストリーク
    final streak = await touchActivity();
    if (streak.extended) {
      final streakEvents = await _awardStreakCheckpoints(streak.streakDays);
      for (final e in streakEvents) {
        xpEvents.add(e);
        earned.addAll(e.newlyEarnedBadges);
      }
    }

    // #5 隠しバッジ: タスク完了時に走る判定
    final hiddenEvents = await _checkHiddenBadgesOnTaskCompleted(task);
    for (final e in hiddenEvents) {
      xpEvents.add(e);
      earned.addAll(e.newlyEarnedBadges);
    }

    final finalStats = await getStats();
    return TaskCompleteResult(
      xpEvents: xpEvents,
      newlyEarnedBadges: earned,
      streak: streak,
      finalStats: finalStats,
    );
  }

  /// AI整理実行時の包括処理。
  ///
  /// - +5 XP / 5件以上で +10 ボーナス / ai_first バッジ / ストリーク維持
  Future<AiSortResult> onAiSorted({required int taskCount}) async {
    final stats = await getStats();
    final xpEvents = <XpAwardResult>[];
    final earned = <UserBadge>[];

    final newCount = stats.totalAiSorts + 1;
    await _db.updateUserStats({'total_ai_sorts': newCount});

    final base = await _award(amount: 5, reason: 'ai_sort');
    xpEvents.add(base);
    earned.addAll(base.newlyEarnedBadges);

    if (taskCount >= 5) {
      final bonus = await _award(amount: 10, reason: 'ai_sort_bulk');
      xpEvents.add(bonus);
      earned.addAll(bonus.newlyEarnedBadges);
    }

    Future<void> tryAiBadge(String id, int threshold) async {
      if (newCount >= threshold && await _db.markBadgeEarned(id)) {
        earned.add(UserBadge(
          id: id,
          isEarned: true,
          earnedAt: DateTime.now(),
        ));
      }
    }

    await tryAiBadge('ai_first', 1);
    await tryAiBadge('ai_10', 10);
    await tryAiBadge('ai_50', 50);

    final streak = await touchActivity();
    if (streak.extended) {
      final streakEvents = await _awardStreakCheckpoints(streak.streakDays);
      for (final e in streakEvents) {
        xpEvents.add(e);
        earned.addAll(e.newlyEarnedBadges);
      }
    }

    final finalStats = await getStats();
    return AiSortResult(
      xpEvents: xpEvents,
      newlyEarnedBadges: earned,
      streak: streak,
      finalStats: finalStats,
    );
  }

  /// XPを伴わないアクティビティでストリーク維持（タスク追加・編集等）。
  Future<StreakUpdate> touchActivity() async {
    final stats = await getStats();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (stats.streakLastDate == null) {
      const newStreak = 1;
      final newLongest = math.max(stats.longestStreak, newStreak);
      await _db.updateUserStats({
        'streak_days': newStreak,
        'streak_last_date': today.toIso8601String(),
        'longest_streak': newLongest,
      });
      return StreakUpdate(
        streakDays: newStreak,
        extended: true,
        reset: false,
        isNewRecord: newStreak > stats.longestStreak,
        longestStreak: newLongest,
      );
    }

    final last = stats.streakLastDate!;
    final lastDay = DateTime(last.year, last.month, last.day);
    final diff = today.difference(lastDay).inDays;

    // #2-C: 端末日付を巻き戻されても (今日 < 最後の活動日) ストリークを伸ばさない。
    // 「同日扱い」と同じ no-op で返す。
    if (diff <= 0) {
      return StreakUpdate(
        streakDays: stats.streakDays,
        extended: false,
        reset: false,
        isNewRecord: false,
        longestStreak: stats.longestStreak,
      );
    }
    if (diff == 1) {
      final newStreak = stats.streakDays + 1;
      final newLongest = math.max(stats.longestStreak, newStreak);
      await _db.updateUserStats({
        'streak_days': newStreak,
        'streak_last_date': today.toIso8601String(),
        'longest_streak': newLongest,
      });
      return StreakUpdate(
        streakDays: newStreak,
        extended: true,
        reset: false,
        isNewRecord: newStreak > stats.longestStreak,
        longestStreak: newLongest,
      );
    }
    // 2日以上空いた → リセット
    await _db.updateUserStats({
      'streak_days': 1,
      'streak_last_date': today.toIso8601String(),
    });
    return StreakUpdate(
      streakDays: 1,
      extended: true,
      reset: true,
      isNewRecord: false,
      longestStreak: stats.longestStreak,
    );
  }

  // ====== Internal ======

  /// XPを加算してレベルアップ判定。レベルバッジも内包。
  Future<XpAwardResult> _award({
    required int amount,
    required String reason,
  }) async {
    final stats = await getStats();
    final newTotal = stats.totalXp + amount;
    final newLevel = levelFromXp(newTotal);

    await _db.recordXp(amount, reason);
    await _db.updateUserStats({
      'total_xp': newTotal,
      'current_level': newLevel,
    });
    // #2-D: 累計 XP の Keychain バックアップを更新
    await _secure?.updateTotalXpBackup(newTotal);

    final earned = <UserBadge>[];
    Future<void> tryLevelBadge(String id, int threshold) async {
      if (newLevel >= threshold &&
          stats.currentLevel < threshold &&
          await _db.markBadgeEarned(id)) {
        earned.add(UserBadge(
          id: id,
          isEarned: true,
          earnedAt: DateTime.now(),
        ));
      }
    }

    await tryLevelBadge('level_5', 5);
    await tryLevelBadge('level_10', 10);
    await tryLevelBadge('level_20', 20);
    await tryLevelBadge('level_30', 30);
    await tryLevelBadge('level_50', 50);
    await tryLevelBadge('level_70', 70);
    await tryLevelBadge('level_100', 100);

    return XpAwardResult(
      amount: amount,
      reason: reason,
      newTotalXp: newTotal,
      oldLevel: stats.currentLevel,
      newLevel: newLevel,
      newlyEarnedBadges: earned,
    );
  }

  // ====== #5 隠しバッジ判定 ======

  /// 共通: バッジ ID を獲得済みにマークし、 成功したら XP ボーナス + イベント返却。
  Future<XpAwardResult?> _tryEarnBadge(String badgeId) async {
    if (!await _db.markBadgeEarned(badgeId)) return null;
    final xp = DatabaseService.kBadgeXpReward[badgeId] ?? 0;
    final result = await _award(amount: xp, reason: 'badge_$badgeId');
    result.newlyEarnedBadges.add(UserBadge(
      id: badgeId,
      isEarned: true,
      isHidden: DatabaseService.kHiddenBadgeIds.contains(badgeId),
      earnedAt: DateTime.now(),
    ));
    return result;
  }

  /// タスク完了時に走る隠しバッジ判定 (early_bird / night_owl / busy_day / ...)。
  Future<List<XpAwardResult>> _checkHiddenBadgesOnTaskCompleted(Task task) async {
    final out = <XpAwardResult>[];
    final now = DateTime.now();

    // 時間帯
    if (now.hour < 6) {
      final r = await _tryEarnBadge('early_bird');
      if (r != null) out.add(r);
    }
    if (now.hour >= 0 && now.hour < 3) {
      final r = await _tryEarnBadge('night_owl');
      if (r != null) out.add(r);
    }

    // 同日件数 (busy_day_5 / busy_day_10)
    final todayCount = await _db.getTodayTaskCompleteCount();
    if (todayCount >= 5) {
      final r = await _tryEarnBadge('busy_day_5');
      if (r != null) out.add(r);
    }
    if (todayCount >= 10) {
      final r = await _tryEarnBadge('busy_day_10');
      if (r != null) out.add(r);
    }

    // 月間件数 (busy_month_30)
    final monthCount = await _db.getThisMonthTaskCompleteCount();
    if (monthCount >= 30) {
      final r = await _tryEarnBadge('busy_month_30');
      if (r != null) out.add(r);
    }

    // 復帰 (back_from_hibernation): 今のタスクを除く最後の完了から 60 日以上
    // task.id が null (理論上発生しない経路) でも 今回完了の `now` 自身を除外する
    // 必要があるため、 ガードして excludingTaskId が null の場合は判定スキップ。
    if (task.id != null) {
      final last = await _db.getLastCompletedAt(excludingTaskId: task.id);
      if (last != null && now.difference(last).inDays >= 60) {
        final r = await _tryEarnBadge('back_from_hibernation');
        if (r != null) out.add(r);
      }
    }

    // multi_tasker: 3 つ以上のカテゴリで完了済み
    final distinctCats = await _db.getCompletedDistinctCategoryCount();
    if (distinctCats >= 3) {
      final r = await _tryEarnBadge('multi_tasker');
      if (r != null) out.add(r);
    }

    // zero_overdue: 期限切れ未完了 0 件
    final overdue = await _db.getOverdueIncompleteCount();
    if (overdue == 0) {
      final r = await _tryEarnBadge('zero_overdue');
      if (r != null) out.add(r);
    }

    // weekend_warrior: 直近 7 日の土日合計 5+
    final weekend = await _db.getWeekendTaskCompleteCountLast7Days();
    if (weekend >= 5) {
      final r = await _tryEarnBadge('weekend_warrior');
      if (r != null) out.add(r);
    }

    // perfect_week: 直近 7 日すべての日で 1 件以上完了
    final daysWithCompletion = await _db.getDistinctTaskCompleteDaysLast7Days();
    if (daysWithCompletion >= 7) {
      final r = await _tryEarnBadge('perfect_week');
      if (r != null) out.add(r);
    }

    return out;
  }

  /// アプリ起動時に走る判定 (long_time_no_see: 30 日以上ぶり)。
  /// streak_last_date を比較。 touchActivity の **前** に呼ぶ。
  Future<List<XpAwardResult>> checkLongTimeNoSee() async {
    final out = <XpAwardResult>[];
    final stats = await getStats();
    final last = stats.streakLastDate;
    if (last == null) return out;
    final days = DateTime.now().difference(last).inDays;
    if (days >= 30) {
      final r = await _tryEarnBadge('long_time_no_see');
      if (r != null) out.add(r);
    }
    return out;
  }

  /// カテゴリ作成時に呼ぶ (category_master: 5 個以上)。
  Future<XpAwardResult?> checkCategoryMaster() async {
    final count = await _db.getCategoryCount();
    if (count >= 5) return _tryEarnBadge('category_master');
    return null;
  }

  /// 定期タスク追加時に呼ぶ (habit_demon: 5 件以上)。
  Future<XpAwardResult?> checkRecurringHabitMaster() async {
    final count = await _db.getRecurringTaskCount();
    if (count >= 5) return _tryEarnBadge('habit_demon');
    return null;
  }

  /// 曜日空き設定がデフォルトから変更された時に呼ぶ (schedule_master)。
  Future<XpAwardResult?> checkScheduleMaster() async {
    return _tryEarnBadge('schedule_master');
  }

  /// AI 整理チケットを購入した時に呼ぶ (ticket_buyer)。
  Future<XpAwardResult?> checkTicketBuyer() async {
    return _tryEarnBadge('ticket_buyer');
  }

  /// ストリーク達成バッジ (3/7/14/30/60/100 日) → バッジ獲得時に XP ボーナス
  Future<List<XpAwardResult>> _awardStreakCheckpoints(int streakDays) async {
    final results = <XpAwardResult>[];
    final checkpoints = <({int days, String badge, int xp})>[
      (days: 3, badge: 'streak_3', xp: 10),
      (days: 7, badge: 'streak_7', xp: 30),
      (days: 14, badge: 'streak_14', xp: 50),
      (days: 30, badge: 'streak_30', xp: 100),
      (days: 60, badge: 'streak_60', xp: 200),
      (days: 100, badge: 'streak_100', xp: 500),
    ];
    for (final cp in checkpoints) {
      if (streakDays >= cp.days && await _db.markBadgeEarned(cp.badge)) {
        final r = await _award(amount: cp.xp, reason: cp.badge);
        // バッジ自身も結果に含める
        r.newlyEarnedBadges.add(UserBadge(
          id: cp.badge,
          isEarned: true,
          earnedAt: DateTime.now(),
        ));
        results.add(r);
      }
    }
    return results;
  }

  // ====== Level calculation (static helpers) ======

  /// レベルNに到達するための累計XP閾値 (Lv.1〜100)。
  static int xpForLevel(int level) {
    if (level <= 0) return 0;
    if (level <= _baseLevelXp.length) return _baseLevelXp[level - 1];
    if (level >= 100) return _levelCheckpoints[100]!;
    // _levelCheckpoints の前後で線形補間
    final keys = _levelCheckpoints.keys.toList()..sort();
    for (var i = 0; i < keys.length - 1; i++) {
      final lo = keys[i];
      final hi = keys[i + 1];
      if (level >= lo && level <= hi) {
        final t = (level - lo) / (hi - lo);
        final xp = _levelCheckpoints[lo]! +
            (_levelCheckpoints[hi]! - _levelCheckpoints[lo]!) * t;
        return xp.round();
      }
    }
    return _levelCheckpoints[100]!;
  }

  /// 累計XPからレベルを算出 (1〜100)。
  static int levelFromXp(int totalXp) {
    if (totalXp < 0) return 1;
    int level = 1;
    while (level < 100 && xpForLevel(level + 1) <= totalXp) {
      level++;
    }
    return level;
  }

  /// レベル名 (固定名 14 段階)。 該当なしは null → 呼び出し側で「Lv.N」表記。
  static const Map<int, String> _levelNameKeys = <int, String>{
    1: 'levelName1',
    2: 'levelName2',
    3: 'levelName3',
    4: 'levelName4',
    5: 'levelName5',
    6: 'levelName6',
    7: 'levelName7',
    8: 'levelName8',
    9: 'levelName9',
    10: 'levelName10',
    15: 'levelName15',
    20: 'levelName20',
    30: 'levelName30',
    50: 'levelName50',
    70: 'levelName70',
    100: 'levelName100',
  };

  /// 該当レベル以下で一番大きい固定名 key を返す。 該当なしは null。
  static String? levelNameKeyFor(int level) {
    int? best;
    for (final k in _levelNameKeys.keys) {
      if (k <= level && (best == null || k > best)) {
        best = k;
      }
    }
    return best == null ? null : _levelNameKeys[best];
  }

  /// 次レベルまでの残りXP。
  static int xpToNextLevel(int totalXp) {
    final lv = levelFromXp(totalXp);
    return xpForLevel(lv + 1) - totalXp;
  }

  /// 現レベル開始XP。
  static int currentLevelStartXp(int totalXp) =>
      xpForLevel(levelFromXp(totalXp));

  /// 現レベル内での進捗 (0.0〜1.0)
  static double levelProgress(int totalXp) {
    final lv = levelFromXp(totalXp);
    final start = xpForLevel(lv);
    final next = xpForLevel(lv + 1);
    final span = next - start;
    if (span <= 0) return 1.0;
    return ((totalXp - start) / span).clamp(0.0, 1.0);
  }

  /// レベル名 i18n キー。 固定名 14 段階のいずれか、 該当なしは null。
  /// 表示側で null なら 'Lv.N' を使う。
  static String levelNameKey(int level) {
    return levelNameKeyFor(level) ?? 'levelNameHigh';
  }
}

// ====== Result classes ======

class XpAwardResult {
  XpAwardResult({
    required this.amount,
    required this.reason,
    required this.newTotalXp,
    required this.oldLevel,
    required this.newLevel,
    required this.newlyEarnedBadges,
  });

  final int amount;
  final String reason;
  final int newTotalXp;
  final int oldLevel;
  final int newLevel;
  final List<UserBadge> newlyEarnedBadges;

  bool get leveledUp => newLevel > oldLevel;
}

class StreakUpdate {
  const StreakUpdate({
    required this.streakDays,
    required this.extended,
    required this.reset,
    required this.isNewRecord,
    required this.longestStreak,
  });
  final int streakDays;
  final bool extended;
  final bool reset;
  final bool isNewRecord;
  final int longestStreak;
}

class TaskCompleteResult {
  const TaskCompleteResult({
    required this.xpEvents,
    required this.newlyEarnedBadges,
    required this.streak,
    required this.finalStats,
  });
  final List<XpAwardResult> xpEvents;
  final List<UserBadge> newlyEarnedBadges;
  final StreakUpdate streak;
  final UserStats finalStats;

  int get totalXpAwarded => xpEvents.fold(0, (s, r) => s + r.amount);
  bool get leveledUp => xpEvents.any((r) => r.leveledUp);
}

class AiSortResult {
  const AiSortResult({
    required this.xpEvents,
    required this.newlyEarnedBadges,
    required this.streak,
    required this.finalStats,
  });
  final List<XpAwardResult> xpEvents;
  final List<UserBadge> newlyEarnedBadges;
  final StreakUpdate streak;
  final UserStats finalStats;

  int get totalXpAwarded => xpEvents.fold(0, (s, r) => s + r.amount);
  bool get leveledUp => xpEvents.any((r) => r.leveledUp);
}
