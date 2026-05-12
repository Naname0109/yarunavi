import 'dart:math' as math;

import '../models/user_badge.dart';
import '../models/user_stats.dart';
import 'database_service.dart';

/// ゲーミフィケーション基盤サービス。XP/レベル/ストリーク/バッジ判定を一括管理。
///
/// 呼び出し側 (TasksNotifier 等) は基本的に以下のみ使う:
/// - [onTaskCompleted] : タスク完了時
/// - [onAiSorted]      : AI整理実行時
/// - [touchActivity]   : アプリ操作（XPを伴わない活動）でストリーク維持
class GamificationService {
  GamificationService(this._db);
  final DatabaseService _db;

  /// Lv.1〜8 に必要な累計XP（v1要件で固定）
  /// Lv.N (N>=9) は前デルタ × 1.4 で外挿。
  static const List<int> _baseLevelXp = <int>[
    0, // Lv.1
    30, // Lv.2 (+30)
    80, // Lv.3 (+50)
    160, // Lv.4 (+80)
    300, // Lv.5 (+140)
    500, // Lv.6 (+200)
    800, // Lv.7 (+300)
    1200, // Lv.8 (+400)
  ];

  // ====== Public: Reads ======

  Future<UserStats> getStats() async {
    final row = await _db.getUserStats();
    if (row == null) {
      throw StateError('user_stats not initialized (run DB migration v11)');
    }
    return UserStats.fromMap(row);
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
  Future<TaskCompleteResult> onTaskCompleted({
    required bool isAllTodayDone,
  }) async {
    final stats = await getStats();
    final xpEvents = <XpAwardResult>[];
    final earned = <UserBadge>[];

    final newCompleted = stats.totalTasksCompleted + 1;
    await _db.updateUserStats({'total_tasks_completed': newCompleted});

    final base = await _award(amount: 10, reason: 'task_complete');
    xpEvents.add(base);
    earned.addAll(base.newlyEarnedBadges);

    if (isAllTodayDone) {
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
    await tryBadge('task_50', 50);
    await tryBadge('task_100', 100);

    // ストリーク
    final streak = await touchActivity();
    if (streak.extended) {
      final streakEvents = await _awardStreakCheckpoints(streak.streakDays);
      for (final e in streakEvents) {
        xpEvents.add(e);
        earned.addAll(e.newlyEarnedBadges);
      }
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

    if (newCount == 1 && await _db.markBadgeEarned('ai_first')) {
      earned.add(UserBadge(
        id: 'ai_first',
        isEarned: true,
        earnedAt: DateTime.now(),
      ));
    }

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

    if (diff == 0) {
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

    final earned = <UserBadge>[];
    if (newLevel >= 5 &&
        stats.currentLevel < 5 &&
        await _db.markBadgeEarned('level_5')) {
      earned.add(UserBadge(
        id: 'level_5',
        isEarned: true,
        earnedAt: DateTime.now(),
      ));
    }
    if (newLevel >= 10 &&
        stats.currentLevel < 10 &&
        await _db.markBadgeEarned('level_10')) {
      earned.add(UserBadge(
        id: 'level_10',
        isEarned: true,
        earnedAt: DateTime.now(),
      ));
    }

    return XpAwardResult(
      amount: amount,
      reason: reason,
      newTotalXp: newTotal,
      oldLevel: stats.currentLevel,
      newLevel: newLevel,
      newlyEarnedBadges: earned,
    );
  }

  /// ストリーク達成バッジ（3/7/14/30 日）→ バッジ獲得時に XP ボーナス
  Future<List<XpAwardResult>> _awardStreakCheckpoints(int streakDays) async {
    final results = <XpAwardResult>[];
    final checkpoints = <({int days, String badge, int xp})>[
      (days: 3, badge: 'streak_3', xp: 10),
      (days: 7, badge: 'streak_7', xp: 30),
      (days: 14, badge: 'streak_14', xp: 50),
      (days: 30, badge: 'streak_30', xp: 100),
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

  /// レベルNに到達するための累計XP閾値。
  static int xpForLevel(int level) {
    if (level <= 0) return 0;
    if (level <= _baseLevelXp.length) return _baseLevelXp[level - 1];
    int total = _baseLevelXp.last;
    int delta = _baseLevelXp.last - _baseLevelXp[_baseLevelXp.length - 2];
    for (int l = _baseLevelXp.length + 1; l <= level; l++) {
      delta = (delta * 1.4).round();
      total += delta;
    }
    return total;
  }

  /// 累計XPからレベルを算出。
  static int levelFromXp(int totalXp) {
    if (totalXp < 0) return 1;
    int level = 1;
    while (xpForLevel(level + 1) <= totalXp) {
      level++;
      if (level > 200) break;
    }
    return level;
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

  /// レベル名 i18n キー（Lv.1〜8は固有、9以降は共通キー＋プレースホルダ）
  static String levelNameKey(int level) {
    if (level >= 1 && level <= 8) return 'levelName$level';
    return 'levelNameHigh';
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
