import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

import '../models/task.dart';
import '../models/category.dart' as model;
import '../models/event.dart';
import '../utils/date_utils.dart' as app_date;
import '../utils/recurrence_utils.dart';

class DatabaseService {
  Database? _db;

  Database get db {
    if (_db == null) {
      throw StateError('DatabaseService not initialized. Call initialize() first.');
    }
    return _db!;
  }

  Future<void> initialize() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'yarunavi.db');

    // v12: tasks.xp_granted (XP 1 タスク 1 回保証)
    _db = await openDatabase(
      path,
      version: 15,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// バッジ定義の正規ID一覧 (#5 全 41 個)。
  /// 表 (23) と 隠し (18) は [kHiddenBadgeIds] で区別する。
  static const List<String> kBadgeIds = [
    // === 表バッジ 23 個 ===
    // タスク完了系 (8)
    'first_step',
    'task_10', 'task_25', 'task_50', 'task_100',
    'task_250', 'task_500', 'task_1000',
    // ストリーク系 (6)
    'streak_3', 'streak_7', 'streak_14', 'streak_30', 'streak_60', 'streak_100',
    // AI 整理系 (3)
    'ai_first', 'ai_10', 'ai_50',
    // レベル系 (4)
    'level_5', 'level_10', 'level_20', 'level_30',

    // === 隠しバッジ 18 個 ===
    // 時間帯
    'early_bird', 'night_owl',
    // 大量処理
    'busy_day_5', 'busy_day_10', 'busy_month_30',
    // 復帰
    'back_from_hibernation', 'long_time_no_see',
    // 設定
    'category_master', 'habit_demon', 'schedule_master',
    // 特殊
    'zero_overdue', 'multi_tasker', 'ticket_buyer',
    'weekend_warrior', 'perfect_week',
    // 高レベル (隠し)
    'level_50', 'level_70', 'level_100',
  ];

  /// 隠しバッジ (条件を「???」 で伏せる)。
  static const Set<String> kHiddenBadgeIds = {
    'early_bird', 'night_owl',
    'busy_day_5', 'busy_day_10', 'busy_month_30',
    'back_from_hibernation', 'long_time_no_see',
    'category_master', 'habit_demon', 'schedule_master',
    'zero_overdue', 'multi_tasker', 'ticket_buyer',
    'weekend_warrior', 'perfect_week',
    'level_50', 'level_70', 'level_100',
  };

  /// バッジ獲得時に付与する XP ボーナス
  static const Map<String, int> kBadgeXpReward = {
    // 表
    'first_step': 5,
    'task_10': 20, 'task_25': 30, 'task_50': 50, 'task_100': 100,
    'task_250': 150, 'task_500': 200, 'task_1000': 500,
    'streak_3': 10, 'streak_7': 30, 'streak_14': 50,
    'streak_30': 100, 'streak_60': 200, 'streak_100': 500,
    'ai_first': 10, 'ai_10': 30, 'ai_50': 100,
    'level_5': 50, 'level_10': 100, 'level_20': 200, 'level_30': 300,
    // 隠し
    'early_bird': 15, 'night_owl': 15,
    'busy_day_5': 40, 'busy_day_10': 80, 'busy_month_30': 100,
    'back_from_hibernation': 30, 'long_time_no_see': 15,
    'category_master': 20, 'habit_demon': 30, 'schedule_master': 10,
    'zero_overdue': 30, 'multi_tasker': 20, 'ticket_buyer': 10,
    'weekend_warrior': 25, 'perfect_week': 50,
    'level_50': 500, 'level_70': 700, 'level_100': 1000,
  };

  /// マイグレーション時に既存データから遡及して獲得済みにすべきバッジか
  static bool _shouldAutoEarnOnMigration(
    String id,
    int completed,
    int aiSorts,
  ) {
    return switch (id) {
      'first_step' => completed >= 1,
      'task_10' => completed >= 10,
      'task_25' => completed >= 25,
      'task_50' => completed >= 50,
      'task_100' => completed >= 100,
      'task_250' => completed >= 250,
      'task_500' => completed >= 500,
      'task_1000' => completed >= 1000,
      'ai_first' => aiSorts >= 1,
      'ai_10' => aiSorts >= 10,
      'ai_50' => aiSorts >= 50,
      _ => false,
    };
  }

  /// v11: ゲーミフィケーションテーブル群を作成 + 初期データ投入。
  ///
  /// `_onCreate` でも `_onUpgrade` でも呼ばれる。既存 `tasks` / `ai_history` から
  /// 累計完了数・AI整理回数を引き継ぐが、XP/レベル/ストリークは 0 から開始。
  Future<void> _migrateToV11(Database db) async {
    await db.execute('''
      CREATE TABLE user_stats (
        id INTEGER PRIMARY KEY,
        total_xp INTEGER NOT NULL DEFAULT 0,
        current_level INTEGER NOT NULL DEFAULT 1,
        streak_days INTEGER NOT NULL DEFAULT 0,
        streak_last_date TEXT,
        longest_streak INTEGER NOT NULL DEFAULT 0,
        total_tasks_completed INTEGER NOT NULL DEFAULT 0,
        total_ai_sorts INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE badges (
        id TEXT PRIMARY KEY,
        is_hidden INTEGER NOT NULL DEFAULT 0,
        is_earned INTEGER NOT NULL DEFAULT 0,
        earned_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE xp_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        amount INTEGER NOT NULL,
        reason TEXT NOT NULL,
        earned_at TEXT NOT NULL
      )
    ''');

    await db.execute(
      'CREATE INDEX idx_xp_history_date ON xp_history(earned_at)',
    );

    // 既存データを集計（新規インストール時は 0 になる）
    final completedRow = await db.rawQuery(
      'SELECT COUNT(*) as cnt FROM tasks WHERE is_completed = 1',
    );
    final totalCompleted = Sqflite.firstIntValue(completedRow) ?? 0;

    final aiSortRow = await db.rawQuery(
      'SELECT COUNT(*) as cnt FROM ai_history',
    );
    final totalAiSorts = Sqflite.firstIntValue(aiSortRow) ?? 0;

    final now = DateTime.now().toIso8601String();

    await db.insert('user_stats', {
      'id': 1,
      'total_xp': 0,
      'current_level': 1,
      'streak_days': 0,
      'streak_last_date': null,
      'longest_streak': 0,
      'total_tasks_completed': totalCompleted,
      'total_ai_sorts': totalAiSorts,
      'created_at': now,
    });

    final batch = db.batch();
    for (final id in kBadgeIds) {
      final retro = _shouldAutoEarnOnMigration(id, totalCompleted, totalAiSorts);
      batch.insert(
        'badges',
        {
          'id': id,
          'is_hidden': kHiddenBadgeIds.contains(id) ? 1 : 0,
          'is_earned': retro ? 1 : 0,
          'earned_at': retro ? now : null,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE tasks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        due_date TEXT NOT NULL,
        memo TEXT,
        category_id INTEGER,
        is_completed INTEGER NOT NULL DEFAULT 0,
        completed_at TEXT,
        priority INTEGER NOT NULL DEFAULT 0,
        ai_comment TEXT,
        recurrence_type TEXT,
        recurrence_value INTEGER,
        recurrence_parent_id INTEGER,
        notify_settings TEXT,
        calendar_event_id TEXT,
        estimated_time TEXT,
        importance INTEGER NOT NULL DEFAULT 1,
        sort_order INTEGER NOT NULL DEFAULT 0,
        recommended_date TEXT,
        is_recommended_date_manual INTEGER NOT NULL DEFAULT 0,
        recommended_start TEXT,
        recommended_end TEXT,
        xp_granted INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        icon TEXT NOT NULL,
        sort_order INTEGER NOT NULL DEFAULT 0,
        is_default INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE ai_usage (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        used_at TEXT NOT NULL,
        month_key TEXT NOT NULL
      )
    ''');

    await db.execute(
      'CREATE INDEX idx_ai_usage_month ON ai_usage(month_key)',
    );

    await db.execute('''
      CREATE TABLE ai_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        summary_ja TEXT,
        summary_en TEXT,
        result_json TEXT NOT NULL,
        task_count INTEGER NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    // v13: タスク実行不可日 (#3)
    await db.execute('''
      CREATE TABLE blocked_dates (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL UNIQUE
      )
    ''');

    // v15: カレンダーの予定 (#2 — タスクとは独立。 AI 整理対象外)
    await db.execute('''
      CREATE TABLE events (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        date TEXT NOT NULL,
        start_time TEXT,
        end_time TEXT,
        is_all_day INTEGER NOT NULL DEFAULT 1,
        memo TEXT,
        source TEXT NOT NULL DEFAULT 'manual',
        external_id TEXT,
        created_at TEXT NOT NULL
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_events_date ON events(date)',
    );

    // デフォルトカテゴリ投入（nameはi18nキーとして保存）
    final now = DateTime.now().toIso8601String();
    final defaultCategories = [
      {'name': 'categoryPayment', 'icon': '💰', 'sort_order': 0, 'is_default': 1},
      {'name': 'categoryPaperwork', 'icon': '📋', 'sort_order': 1, 'is_default': 1},
      {'name': 'categoryShopping', 'icon': '🛒', 'sort_order': 2, 'is_default': 1},
      {'name': 'categoryHousehold', 'icon': '🏠', 'sort_order': 3, 'is_default': 1},
      {'name': 'categoryWork', 'icon': '💼', 'sort_order': 4, 'is_default': 1},
      {'name': 'categoryOther', 'icon': '🎯', 'sort_order': 5, 'is_default': 1},
    ];

    final batch = db.batch();
    for (final cat in defaultCategories) {
      batch.insert('categories', {
        ...cat,
        'created_at': now,
      });
    }
    await batch.commit(noResult: true);

    // v11: ゲーミフィケーション基盤
    await _migrateToV11(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE tasks ADD COLUMN calendar_event_id TEXT');
    }
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE tasks ADD COLUMN estimated_time TEXT');
      await db.execute(
          'ALTER TABLE tasks ADD COLUMN importance INTEGER NOT NULL DEFAULT 1');
    }
    if (oldVersion < 4) {
      await db.execute('''
        CREATE TABLE ai_history (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          summary_ja TEXT,
          summary_en TEXT,
          result_json TEXT NOT NULL,
          task_count INTEGER NOT NULL,
          created_at TEXT NOT NULL
        )
      ''');
    }
    if (oldVersion < 5) {
      await db.execute(
          'ALTER TABLE tasks ADD COLUMN sort_order INTEGER NOT NULL DEFAULT 0');
    }
    if (oldVersion < 6) {
      await db.execute('ALTER TABLE tasks ADD COLUMN recommended_date TEXT');
    }
    if (oldVersion < 7) {
      await db.execute('ALTER TABLE tasks ADD COLUMN recommended_start TEXT');
      await db.execute('ALTER TABLE tasks ADD COLUMN recommended_end TEXT');
      await db.execute(
        'UPDATE tasks SET recommended_start = recommended_date, '
        'recommended_end = recommended_date WHERE recommended_date IS NOT NULL',
      );
    }
    if (oldVersion < 8) {
      await db.execute(
        'ALTER TABLE categories ADD COLUMN is_default INTEGER NOT NULL DEFAULT 0',
      );
      await db.execute(
        "UPDATE categories SET is_default = 1 WHERE name IN "
        "('categoryPayment','categoryPaperwork','categoryShopping',"
        "'categoryHousehold','categoryWork','categoryOther')",
      );
    }
    if (oldVersion < 9) {
      // recommended_dateカラムが存在しない場合は追加（v8で_onCreateされたDB対応）
      final cols = await db.rawQuery('PRAGMA table_info(tasks)');
      final hasRecDate = cols.any((c) => c['name'] == 'recommended_date');
      if (!hasRecDate) {
        await db.execute(
            'ALTER TABLE tasks ADD COLUMN recommended_date TEXT');
      }
      // recommended_start → recommended_date にデータ移行
      await db.execute(
        'UPDATE tasks SET recommended_date = recommended_start '
        'WHERE recommended_start IS NOT NULL',
      );
    }
    if (oldVersion < 10) {
      await db.execute(
        'ALTER TABLE tasks ADD COLUMN is_recommended_date_manual INTEGER NOT NULL DEFAULT 0',
      );
    }
    if (oldVersion < 11) {
      await _migrateToV11(db);
    }
    if (oldVersion < 12) {
      // tasks.xp_granted: 1 タスクにつき XP 付与は生涯 1 回のみ。
      // 既に完了済みのタスクは付与済みとして扱う (旧版で XP 付与済みと仮定)。
      await db.execute(
        'ALTER TABLE tasks ADD COLUMN xp_granted INTEGER NOT NULL DEFAULT 0',
      );
      await db.execute('UPDATE tasks SET xp_granted = 1 WHERE is_completed = 1');
    }
    if (oldVersion < 13) {
      // #3 タスク実行不可日
      await db.execute('''
        CREATE TABLE IF NOT EXISTS blocked_dates (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          date TEXT NOT NULL UNIQUE
        )
      ''');
    }
    if (oldVersion < 15) {
      // #2 events テーブル
      await db.execute('''
        CREATE TABLE IF NOT EXISTS events (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT NOT NULL,
          date TEXT NOT NULL,
          start_time TEXT,
          end_time TEXT,
          is_all_day INTEGER NOT NULL DEFAULT 1,
          memo TEXT,
          source TEXT NOT NULL DEFAULT 'manual',
          external_id TEXT,
          created_at TEXT NOT NULL
        )
      ''');
      try {
        await db.execute(
            'CREATE INDEX IF NOT EXISTS idx_events_date ON events(date)');
      } catch (_) {}
    }
    if (oldVersion < 14) {
      // #5 バッジ刷新 (41 個) + is_hidden カラム
      // 既存 is_earned は保持し、 新規 badge を追加 + is_hidden を埋める。
      try {
        await db.execute(
          'ALTER TABLE badges ADD COLUMN is_hidden INTEGER NOT NULL DEFAULT 0',
        );
      } catch (_) {/* 既に存在する場合は無視 */}

      final existing = await db.query('badges');
      final existingIds = existing.map((r) => r['id'] as String).toSet();
      final batch = db.batch();
      final now = DateTime.now().toIso8601String();

      // 集計の取り直し (タスク完了数 + AI 整理回数)
      final completedRow = await db.rawQuery(
          'SELECT COUNT(*) as cnt FROM tasks WHERE is_completed = 1');
      final totalCompleted = Sqflite.firstIntValue(completedRow) ?? 0;
      final aiSortRow =
          await db.rawQuery('SELECT COUNT(*) as cnt FROM ai_history');
      final totalAiSorts = Sqflite.firstIntValue(aiSortRow) ?? 0;

      for (final id in kBadgeIds) {
        if (!existingIds.contains(id)) {
          final retro =
              _shouldAutoEarnOnMigration(id, totalCompleted, totalAiSorts);
          batch.insert('badges', {
            'id': id,
            'is_hidden': kHiddenBadgeIds.contains(id) ? 1 : 0,
            'is_earned': retro ? 1 : 0,
            'earned_at': retro ? now : null,
          });
        } else {
          batch.update(
            'badges',
            {'is_hidden': kHiddenBadgeIds.contains(id) ? 1 : 0},
            where: 'id = ?',
            whereArgs: [id],
          );
        }
      }
      await batch.commit(noResult: true);
    }
  }

  // ====== Blocked dates (#3 タスク実行不可日) ======

  Future<List<DateTime>> getBlockedDates() async {
    final rows = await db.query('blocked_dates', orderBy: 'date ASC');
    return rows
        .map((r) => DateTime.parse(r['date'] as String))
        .toList(growable: false);
  }

  Future<void> addBlockedDate(DateTime date) async {
    final iso = DateTime(date.year, date.month, date.day).toIso8601String();
    await db.insert(
      'blocked_dates',
      {'date': iso},
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<void> removeBlockedDate(DateTime date) async {
    final iso = DateTime(date.year, date.month, date.day).toIso8601String();
    await db.delete('blocked_dates', where: 'date = ?', whereArgs: [iso]);
  }

  /// 起動時クリーンアップ: 今日より前の blocked_dates を削除する。
  /// 過去日が無限に残ると UI と AI 整理ロジックの両方が肥大化するため。
  Future<int> cleanupExpiredBlockedDates() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day).toIso8601String();
    return db.delete('blocked_dates', where: 'date < ?', whereArgs: [today]);
  }

  /// 一括置換 (#1 bulk save): 既存全削除 → 渡された dates を挿入。
  /// トランザクション内で実行し、 途中失敗時は元の状態を保つ。
  Future<void> replaceAllBlockedDates(List<DateTime> dates) async {
    await db.transaction((txn) async {
      await txn.delete('blocked_dates');
      for (final d in dates) {
        final iso = DateTime(d.year, d.month, d.day).toIso8601String();
        await txn.insert(
          'blocked_dates',
          {'date': iso},
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }
    });
  }

  // ====== Gamification: user_stats / badges / xp_history ======

  /// 単一のユーザーステータス行（id=1）を取得。
  Future<Map<String, dynamic>?> getUserStats() async {
    final rows = await db.query('user_stats', where: 'id = ?', whereArgs: [1]);
    return rows.isEmpty ? null : rows.first;
  }

  /// user_stats を部分更新（id=1）。
  Future<void> updateUserStats(Map<String, Object?> values) async {
    await db.update('user_stats', values, where: 'id = ?', whereArgs: [1]);
  }

  /// 全バッジ取得（is_earned/earned_at 含む）。
  Future<List<Map<String, dynamic>>> getAllBadges() async {
    return db.query('badges');
  }

  /// バッジを獲得済みにマーク（冪等）。
  Future<bool> markBadgeEarned(String id) async {
    final now = DateTime.now().toIso8601String();
    final updated = await db.update(
      'badges',
      {'is_earned': 1, 'earned_at': now},
      where: 'id = ? AND is_earned = 0',
      whereArgs: [id],
    );
    return updated > 0;
  }

  /// XP獲得を記録（履歴のみ。user_stats.total_xp の更新は呼び出し側）。
  Future<void> recordXp(int amount, String reason) async {
    await db.insert('xp_history', {
      'amount': amount,
      'reason': reason,
      'earned_at': DateTime.now().toIso8601String(),
    });
  }

  /// 過去N日間の日別アクティビティ件数（ヒートマップ用）。
  ///
  /// 戻り値は 'YYYY-MM-DD' → 件数のマップ。
  Future<Map<String, int>> getActivityCountByDay({required int days}) async {
    final since = DateTime.now().subtract(Duration(days: days - 1));
    final sinceDay = DateTime(since.year, since.month, since.day)
        .toIso8601String();
    final rows = await db.rawQuery(
      "SELECT substr(earned_at, 1, 10) as day, COUNT(*) as cnt "
      "FROM xp_history WHERE earned_at >= ? GROUP BY day",
      [sinceDay],
    );
    return {
      for (final r in rows) r['day'] as String: r['cnt'] as int,
    };
  }

  /// 最近のXP獲得履歴（実績画面の最近の活動表示用）。
  Future<List<Map<String, dynamic>>> getXpHistory({int limit = 50}) async {
    return db.query(
      'xp_history',
      orderBy: 'earned_at DESC',
      limit: limit,
    );
  }

  /// 今日獲得した XP 合計 (#2-B: 1 日 200 XP 上限チェック用)。
  Future<int> getTodayXpTotal() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day).toIso8601String();
    final rows = await db.rawQuery(
      'SELECT COALESCE(SUM(amount), 0) AS total FROM xp_history '
      'WHERE earned_at >= ?',
      [today],
    );
    return (rows.first['total'] as int?) ?? 0;
  }

  /// 今日 指定 reason の XP イベントが既にあるか (#2-E: all_today_done を 1 日 1 回保証)。
  Future<bool> hasXpReasonToday(String reason) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day).toIso8601String();
    final rows = await db.rawQuery(
      'SELECT COUNT(*) AS cnt FROM xp_history '
      'WHERE reason = ? AND earned_at >= ?',
      [reason, today],
    );
    return ((rows.first['cnt'] as int?) ?? 0) > 0;
  }

  // ====== 隠しバッジ判定用 query (#5 hidden badges) ======

  /// 当日に task_complete reason で記録された件数。
  Future<int> getTodayTaskCompleteCount() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day).toIso8601String();
    final rows = await db.rawQuery(
      "SELECT COUNT(*) AS cnt FROM xp_history "
      "WHERE reason = 'task_complete' AND earned_at >= ?",
      [today],
    );
    return (rows.first['cnt'] as int?) ?? 0;
  }

  /// 当月の task_complete 件数。
  Future<int> getThisMonthTaskCompleteCount() async {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1).toIso8601String();
    final rows = await db.rawQuery(
      "SELECT COUNT(*) AS cnt FROM xp_history "
      "WHERE reason = 'task_complete' AND earned_at >= ?",
      [monthStart],
    );
    return (rows.first['cnt'] as int?) ?? 0;
  }

  /// 今このタスクを除いた最後の completed_at (back_from_hibernation 用)。
  Future<DateTime?> getLastCompletedAt({int? excludingTaskId}) async {
    final rows = await db.query(
      'tasks',
      columns: ['completed_at'],
      where: excludingTaskId != null
          ? 'is_completed = 1 AND completed_at IS NOT NULL AND id != ?'
          : 'is_completed = 1 AND completed_at IS NOT NULL',
      whereArgs: excludingTaskId != null ? [excludingTaskId] : null,
      orderBy: 'completed_at DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final v = rows.first['completed_at'] as String?;
    return v == null ? null : DateTime.parse(v);
  }

  /// 完了済みタスクが属するユニークなカテゴリ数 (multi_tasker 用)。
  Future<int> getCompletedDistinctCategoryCount() async {
    final rows = await db.rawQuery(
      'SELECT COUNT(DISTINCT category_id) AS cnt FROM tasks '
      'WHERE is_completed = 1 AND category_id IS NOT NULL',
    );
    return (rows.first['cnt'] as int?) ?? 0;
  }

  /// 未完了で期限切れのタスク数 (zero_overdue 用)。
  Future<int> getOverdueIncompleteCount({DateTime? now}) async {
    final n = now ?? DateTime.now();
    final today = DateTime(n.year, n.month, n.day).toIso8601String();
    final rows = await db.rawQuery(
      'SELECT COUNT(*) AS cnt FROM tasks '
      'WHERE is_completed = 0 AND due_date < ?',
      [today],
    );
    return (rows.first['cnt'] as int?) ?? 0;
  }

  /// 直近 7 日のうち、 task_complete が 1 件以上あった日数 (perfect_week 用)。
  Future<int> getDistinctTaskCompleteDaysLast7Days() async {
    final now = DateTime.now();
    final since =
        DateTime(now.year, now.month, now.day - 6).toIso8601String();
    final rows = await db.rawQuery(
      "SELECT COUNT(DISTINCT substr(earned_at, 1, 10)) AS cnt "
      "FROM xp_history WHERE reason = 'task_complete' AND earned_at >= ?",
      [since],
    );
    return (rows.first['cnt'] as int?) ?? 0;
  }

  /// 直近 7 日の土日に completed (xp_history task_complete) があった件数の合計
  /// (weekend_warrior 用)。
  Future<int> getWeekendTaskCompleteCountLast7Days() async {
    final now = DateTime.now();
    final since =
        DateTime(now.year, now.month, now.day - 6).toIso8601String();
    final rows = await db.rawQuery(
      "SELECT earned_at FROM xp_history "
      "WHERE reason = 'task_complete' AND earned_at >= ?",
      [since],
    );
    var weekend = 0;
    for (final r in rows) {
      final iso = r['earned_at'] as String?;
      if (iso == null) continue;
      final dt = DateTime.parse(iso);
      if (dt.weekday == DateTime.saturday || dt.weekday == DateTime.sunday) {
        weekend++;
      }
    }
    return weekend;
  }

  /// カテゴリ総数 (category_master_5 用)。
  Future<int> getCategoryCount() async {
    final rows = await db.rawQuery('SELECT COUNT(*) AS cnt FROM categories');
    return (rows.first['cnt'] as int?) ?? 0;
  }

  /// 定期タスク (recurrence_type が NULL でない) 件数 (habit_demon 用)。
  Future<int> getRecurringTaskCount() async {
    final rows = await db.rawQuery(
      'SELECT COUNT(*) AS cnt FROM tasks WHERE recurrence_type IS NOT NULL',
    );
    return (rows.first['cnt'] as int?) ?? 0;
  }

  // --- Tasks CRUD ---

  Future<int> insertTask(Task task) async {
    return db.insert('tasks', task.toMap());
  }

  Future<int> updateTask(Task task) async {
    return db.update(
      'tasks',
      task.toMapForUpdate(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  /// #6 (rec==due 根本原因): notify_settings だけを更新する。
  /// updateTask は task.copyWith() で渡された古いスナップショットの
  /// 全フィールドを書き戻すため、 直前に updateTaskPriorities で書いた
  /// recommended_date を古い値で上書きしてしまっていた。
  /// 列指定 UPDATE に切り替えてこの「読込み-修正-書込み」 競合を排除する。
  Future<int> updateTaskNotifySettings(int id, String? notifySettings) async {
    return db.update(
      'tasks',
      {
        'notify_settings': notifySettings,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// 定期タスクを完了し、次回タスクを自動生成する
  Future<Task> completeRecurringTask(Task task) async {
    final now = DateTime.now();

    // recurrence_parent_id: 大元のIDを引き継ぐ（チェーンの先頭）
    final parentId = task.recurrenceParentId ?? task.id;

    final nextDueDate = calculateNextDueDate(
      currentDueDate: task.dueDate,
      recurrenceType: task.recurrenceType!,
      recurrenceValue: task.recurrenceValue!,
    );

    final newTask = Task(
      title: task.title,
      dueDate: nextDueDate,
      memo: task.memo,
      categoryId: task.categoryId,
      recurrenceType: task.recurrenceType,
      recurrenceValue: task.recurrenceValue,
      recurrenceParentId: parentId,
      notifySettings: task.notifySettings,
      estimatedTime: task.estimatedTime,
      importance: task.importance,
      createdAt: now,
      updatedAt: now,
    );

    late final int newTaskId;
    await db.transaction((txn) async {
      // 1. 現タスクを完了
      await txn.update(
        'tasks',
        {
          'is_completed': 1,
          'completed_at': now.toIso8601String(),
          'updated_at': now.toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [task.id],
      );
      // 2. 次回タスクを生成
      newTaskId = await txn.insert('tasks', newTask.toMap());
    });

    return newTask.copyWith(id: newTaskId);
  }

  /// #7: 現タスクの完了化だけを行う (次回タスクは別タイミングで生成)。
  /// 残タスクなしの「全完了演出」 → 5 秒後に次回生成、 という UX のため。
  Future<void> markRecurringTaskCompletedOnly(Task task) async {
    final now = DateTime.now().toIso8601String();
    await db.update(
      'tasks',
      {
        'is_completed': 1,
        'completed_at': now,
        'updated_at': now,
        'xp_granted': 1,
      },
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  /// #7: 定期タスクの「次回」 のみを生成。 completeRecurringTask の生成部分を流用。
  /// #8 dedup: 既に同 title + 同 due_date + 未完了のタスクが居れば再生成しない。
  /// connection の重複や race で同タスクが 2 件生成されるバグを防ぐ。
  Future<Task> generateNextRecurringTask(Task task) async {
    final now = DateTime.now();
    final parentId = task.recurrenceParentId ?? task.id;
    final nextDueDate = calculateNextDueDate(
      currentDueDate: task.dueDate,
      recurrenceType: task.recurrenceType!,
      recurrenceValue: task.recurrenceValue!,
    );
    final dueIso = DateTime(nextDueDate.year, nextDueDate.month, nextDueDate.day)
        .toIso8601String();
    // 既存重複チェック
    final existing = await db.query(
      'tasks',
      where:
          'title = ? AND date(due_date) = date(?) AND is_completed = 0',
      whereArgs: [task.title, dueIso],
      limit: 1,
    );
    if (existing.isNotEmpty) {
      final dup = Task.fromMap(existing.first);
      // 既に同名同日があれば、 それを返す (新規挿入しない)
      return dup;
    }
    final newTask = Task(
      title: task.title,
      dueDate: nextDueDate,
      memo: task.memo,
      categoryId: task.categoryId,
      recurrenceType: task.recurrenceType,
      recurrenceValue: task.recurrenceValue,
      recurrenceParentId: parentId,
      notifySettings: task.notifySettings,
      estimatedTime: task.estimatedTime,
      importance: task.importance,
      createdAt: now,
      updatedAt: now,
    );
    final newId = await db.insert('tasks', newTask.toMap());
    return newTask.copyWith(id: newId);
  }

  Future<int> deleteTask(int id) async {
    return db.delete('tasks', where: 'id = ?', whereArgs: [id]);
  }

  /// 完了済みタスクをすべて物理削除 (履歴の一括削除用)。 削除件数を返す。
  Future<int> deleteAllCompletedTasks() async {
    return db.delete('tasks', where: 'is_completed = 1');
  }

  Future<Task?> getTaskById(int id) async {
    final maps = await db.query('tasks', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Task.fromMap(maps.first);
  }

  Future<List<Task>> getAllTasks() async {
    final maps = await db.query('tasks', orderBy: 'due_date ASC');
    return maps.map(Task.fromMap).toList();
  }

  Future<List<Task>> getTasksByFilter(String filterType) async {
    final now = DateTime.now();
    final today = app_date.formatDateForDb(now);

    // 今週末の日付（日曜日）: weekday は月=1〜日=7
    // 日曜日の場合は今日自身が週末、それ以外は次の日曜日
    final daysUntilSunday = now.weekday == DateTime.sunday
        ? 0
        : DateTime.sunday - now.weekday;
    final endOfWeek = now.add(Duration(days: daysUntilSunday));
    final endOfWeekStr = app_date.formatDateForDb(endOfWeek);

    switch (filterType) {
      case 'today':
        final maps = await db.query(
          'tasks',
          where: 'due_date = ? AND is_completed = 0',
          whereArgs: [today],
          orderBy: 'priority ASC, due_date ASC',
        );
        return maps.map(Task.fromMap).toList();

      case 'thisWeek':
        final maps = await db.query(
          'tasks',
          where: 'due_date >= ? AND due_date <= ? AND is_completed = 0',
          whereArgs: [today, endOfWeekStr],
          orderBy: 'due_date ASC, priority ASC',
        );
        return maps.map(Task.fromMap).toList();

      case 'overdue':
        final maps = await db.query(
          'tasks',
          where: 'due_date < ? AND is_completed = 0',
          whereArgs: [today],
          orderBy: 'due_date ASC',
        );
        return maps.map(Task.fromMap).toList();

      case 'completed':
        final maps = await db.query(
          'tasks',
          where: 'is_completed = 1',
          orderBy: 'completed_at DESC',
        );
        return maps.map(Task.fromMap).toList();

      case 'all':
      default:
        final maps = await db.query(
          'tasks',
          where: 'is_completed = 0',
          orderBy: 'CASE WHEN sort_order > 0 THEN 0 ELSE 1 END, sort_order ASC, due_date ASC, priority ASC',
        );
        return maps.map(Task.fromMap).toList();
    }
  }

  /// ホーム画面 "今日やること" 定義の未完了タスクを返す。
  ///
  /// 条件: (期限切れ) OR (期限が今日) OR (priority=1) OR (recommended_date=今日)
  /// 完了済み (is_completed=1) は除外。
  Future<List<Task>> getActiveTodayTasksBroad() async {
    final now = DateTime.now();
    final todayKey = app_date.formatDateForDb(now);
    final maps = await db.rawQuery(
      'SELECT * FROM tasks WHERE is_completed = 0 AND '
      '(due_date < ? OR due_date = ? OR priority = 1 '
      'OR recommended_date = ?)',
      [todayKey, todayKey, todayKey],
    );
    return maps.map(Task.fromMap).toList();
  }

  /// 完了済みタスクの件数を返す
  Future<int> getCompletedTaskCount() async {
    final result = await db.rawQuery(
      'SELECT COUNT(*) as cnt FROM tasks WHERE is_completed = 1',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// 未完了タスクが1件以上あり、かつ全ての期限が過去かどうか
  Future<bool> areAllTasksOverdue() async {
    final today = app_date.formatDateForDb(DateTime.now());
    // 未完了タスクの総数
    final totalResult = await db.rawQuery(
      'SELECT COUNT(*) as cnt FROM tasks WHERE is_completed = 0',
    );
    final totalCount = Sqflite.firstIntValue(totalResult) ?? 0;
    if (totalCount == 0) return false;

    // 期限が今日以降の未完了タスクの数
    final notOverdueResult = await db.rawQuery(
      'SELECT COUNT(*) as cnt FROM tasks WHERE is_completed = 0 AND due_date >= ?',
      [today],
    );
    final notOverdueCount = Sqflite.firstIntValue(notOverdueResult) ?? 0;
    return notOverdueCount == 0;
  }

  /// 最も古い期限切れタスクを取得
  Future<Task?> getOldestOverdueTask() async {
    final today = app_date.formatDateForDb(DateTime.now());
    final maps = await db.query(
      'tasks',
      where: 'due_date < ? AND is_completed = 0',
      whereArgs: [today],
      orderBy: 'due_date ASC',
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Task.fromMap(maps.first);
  }

  // --- Categories ---

  Future<List<model.Category>> getAllCategories() async {
    final maps = await db.query('categories', orderBy: 'sort_order ASC');
    return maps.map(model.Category.fromMap).toList();
  }

  Future<int> addCategory(model.Category category) async {
    return db.insert('categories', category.toMap());
  }

  Future<int> updateCategory(model.Category category) async {
    return db.update(
      'categories',
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  /// カテゴリ削除。関連タスクのcategory_idをnullに更新。
  Future<void> deleteCategory(int id) async {
    await db.transaction((txn) async {
      await txn.update(
        'tasks',
        {'category_id': null},
        where: 'category_id = ?',
        whereArgs: [id],
      );
      await txn.delete('categories', where: 'id = ?', whereArgs: [id]);
    });
  }

  // --- AI Usage ---

  Future<void> recordAiUsage() async {
    final now = DateTime.now();
    final monthKey =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}';
    await db.insert('ai_usage', {
      'used_at': now.toIso8601String(),
      'month_key': monthKey,
    });
  }

  Future<int> getMonthlyAiUsageCount(String monthKey) async {
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM ai_usage WHERE month_key = ?',
      [monthKey],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> getDailyAiUsageCount(String dateStr) async {
    final result = await db.rawQuery(
      "SELECT COUNT(*) as count FROM ai_usage WHERE used_at LIKE ?",
      ['$dateStr%'],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// AI整理結果でタスクのpriority/ai_comment/recommended_dateを一括更新
  Future<void> updateTaskPriorities(
    Map<
            int,
            ({
              int priority,
              String? aiComment,
              DateTime? recommendedDate,
            })>
        updates, {
    Set<int> skipRecommendedDateIds = const {},
  }) async {
    final now = DateTime.now().toIso8601String();
    final batch = db.batch();
    for (final entry in updates.entries) {
      final skipDate = skipRecommendedDateIds.contains(entry.key);
      final values = <String, Object?>{
        'priority': entry.value.priority,
        'ai_comment': entry.value.aiComment,
        'updated_at': now,
      };
      if (!skipDate) {
        values['recommended_date'] = entry.value.recommendedDate != null
            ? app_date.formatDateForDb(entry.value.recommendedDate!)
            : null;
        values['is_recommended_date_manual'] = 0;
      }
      debugPrint('[DB-WRITE] id=${entry.key} priority=${entry.value.priority} '
          'rec_date=${values['recommended_date']} '
          'ai_comment=${(entry.value.aiComment ?? '').isNotEmpty ? 'あり' : 'なし'} '
          'skipDate=$skipDate');
      batch.update(
        'tasks',
        values,
        where: 'id = ?',
        whereArgs: [entry.key],
      );
    }
    await batch.commit(noResult: true);
  }

  // ====== Events (#2 カレンダー予定 — タスクと独立、 AI 整理対象外) ======

  Future<int> insertEvent(Event event) async {
    return db.insert('events', event.toMap());
  }

  Future<int> updateEvent(Event event) async {
    if (event.id == null) return 0;
    return db.update(
      'events',
      event.toMap()..remove('id'),
      where: 'id = ?',
      whereArgs: [event.id],
    );
  }

  Future<int> deleteEvent(int id) async {
    return db.delete('events', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Event>> getAllEvents() async {
    final rows = await db.query('events', orderBy: 'date ASC, start_time ASC');
    return rows.map(Event.fromMap).toList();
  }

  Future<List<Event>> getEventsInRange(
      DateTime from, DateTime to) async {
    final rows = await db.query(
      'events',
      where: 'date >= ? AND date <= ?',
      whereArgs: [
        app_date.formatDateForDb(from),
        app_date.formatDateForDb(to),
      ],
      orderBy: 'date ASC, start_time ASC',
    );
    return rows.map(Event.fromMap).toList();
  }

  /// iOS カレンダー同期前のクリア用: source='calendar_sync' の予定を全削除。
  Future<int> deleteSyncedEvents() async {
    return db.delete('events', where: "source = 'calendar_sync'");
  }

  /// 推奨実行日を手動更新
  Future<void> updateRecommendedDate(int taskId, DateTime date) async {
    await db.update(
      'tasks',
      {
        'recommended_date': app_date.formatDateForDb(date),
        'is_recommended_date_manual': 1,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [taskId],
    );
  }

  // --- AI History ---

  Future<int> insertAiHistory({
    required String? summaryJa,
    required String? summaryEn,
    required String resultJson,
    required int taskCount,
  }) async {
    return db.insert('ai_history', {
      'summary_ja': summaryJa,
      'summary_en': summaryEn,
      'result_json': resultJson,
      'task_count': taskCount,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getAiHistory() async {
    return db.query('ai_history', orderBy: 'created_at DESC');
  }

  /// #9: 最新の AI 整理履歴 1 件 (なければ null)。
  Future<Map<String, dynamic>?> getLatestAiHistory() async {
    final rows = await db.query('ai_history',
        orderBy: 'created_at DESC', limit: 1);
    return rows.isEmpty ? null : rows.first;
  }

  Future<Map<String, dynamic>?> getAiHistoryById(int id) async {
    final maps =
        await db.query('ai_history', where: 'id = ?', whereArgs: [id]);
    return maps.isNotEmpty ? maps.first : null;
  }

  /// タスクの並び順を一括更新
  Future<void> updateTaskSortOrders(List<({int id, int sortOrder})> orders) async {
    final batch = db.batch();
    for (final order in orders) {
      batch.update(
        'tasks',
        {'sort_order': order.sortOrder},
        where: 'id = ?',
        whereArgs: [order.id],
      );
    }
    await batch.commit(noResult: true);
  }

  /// 当月のAI使用回数をリセット
  Future<void> resetCurrentMonthAiUsage() async {
    final now = DateTime.now();
    final monthKey =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}';
    await db.delete('ai_usage', where: 'month_key = ?', whereArgs: [monthKey]);
  }

  /// 全データ削除（タスク + AI利用履歴 + AI整理履歴）
  Future<void> deleteAllData() async {
    await db.delete('tasks');
    await db.delete('ai_usage');
    await db.delete('ai_history');
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
