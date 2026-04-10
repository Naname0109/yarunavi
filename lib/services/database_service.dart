import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

import '../models/task.dart';
import '../models/category.dart' as model;
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

    _db = await openDatabase(
      path,
      version: 8,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
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
        recommended_start TEXT,
        recommended_end TEXT,
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

  Future<int> deleteTask(int id) async {
    return db.delete('tasks', where: 'id = ?', whereArgs: [id]);
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

  /// AI整理結果でタスクのpriority/ai_comment/recommended_start/endを一括更新
  Future<void> updateTaskPriorities(
    Map<
            int,
            ({
              int priority,
              String? aiComment,
              DateTime? recommendedStart,
              DateTime? recommendedEnd,
            })>
        updates,
  ) async {
    final now = DateTime.now().toIso8601String();
    final batch = db.batch();
    for (final entry in updates.entries) {
      batch.update(
        'tasks',
        {
          'priority': entry.value.priority,
          'ai_comment': entry.value.aiComment,
          'recommended_start': entry.value.recommendedStart != null
              ? app_date.formatDateForDb(entry.value.recommendedStart!)
              : null,
          'recommended_end': entry.value.recommendedEnd != null
              ? app_date.formatDateForDb(entry.value.recommendedEnd!)
              : null,
          'updated_at': now,
        },
        where: 'id = ?',
        whereArgs: [entry.key],
      );
    }
    await batch.commit(noResult: true);
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
