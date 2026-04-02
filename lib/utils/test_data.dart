import 'dart:convert';

import '../models/task.dart';
import '../services/database_service.dart';

/// テストデータを生成してDBに投入する
Future<void> insertTestData(DatabaseService db) async {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  final tasks = [
    // 期限切れタスク
    Task(
      title: '電気代振込',
      dueDate: today.subtract(const Duration(days: 1)),
      categoryId: 1, // 支払い
      importance: 1,
      notifySettings: jsonEncode(['ai_auto']),
      createdAt: now.subtract(const Duration(days: 5)),
      updatedAt: now.subtract(const Duration(days: 5)),
    ),
    Task(
      title: '書類提出',
      dueDate: today.subtract(const Duration(days: 3)),
      categoryId: 2, // 手続き
      importance: 2,
      memo: '市役所の窓口へ直接持参',
      notifySettings: jsonEncode(['1_day_before']),
      createdAt: now.subtract(const Duration(days: 7)),
      updatedAt: now.subtract(const Duration(days: 7)),
    ),

    // 今日期限
    Task(
      title: '歯医者予約の電話',
      dueDate: today,
      categoryId: 6, // その他
      memo: '平日10-17時のみ',
      estimatedTime: '5min',
      importance: 1,
      notifySettings: jsonEncode(['ai_auto']),
      createdAt: now.subtract(const Duration(days: 3)),
      updatedAt: now.subtract(const Duration(days: 3)),
    ),

    // 明日期限
    Task(
      title: 'プレゼント購入',
      dueDate: today.add(const Duration(days: 1)),
      categoryId: 3, // 買い物
      importance: 2,
      notifySettings: jsonEncode(['ai_auto']),
      createdAt: now.subtract(const Duration(days: 2)),
      updatedAt: now.subtract(const Duration(days: 2)),
    ),

    // 今週中
    Task(
      title: '部屋の掃除',
      dueDate: today.add(const Duration(days: 4)),
      categoryId: 4, // 家事
      estimatedTime: 'half_day',
      importance: 1,
      notifySettings: jsonEncode(['ai_auto']),
      createdAt: now.subtract(const Duration(days: 1)),
      updatedAt: now.subtract(const Duration(days: 1)),
    ),
    Task(
      title: '確定申告の書類準備',
      dueDate: today.add(const Duration(days: 5)),
      categoryId: 2, // 手続き
      estimatedTime: '1day',
      importance: 2,
      memo: '領収書の整理→入力→確認の3ステップ',
      notifySettings: jsonEncode(['ai_auto']),
      createdAt: now.subtract(const Duration(days: 2)),
      updatedAt: now.subtract(const Duration(days: 2)),
    ),

    // 来週以降
    Task(
      title: 'パスポート更新',
      dueDate: today.add(const Duration(days: 10)),
      categoryId: 2, // 手続き
      memo: '写真撮影が先に必要',
      importance: 1,
      notifySettings: jsonEncode(['ai_auto']),
      createdAt: now,
      updatedAt: now,
    ),
    Task(
      title: '健康診断の予約',
      dueDate: today.add(const Duration(days: 14)),
      categoryId: 6, // その他
      estimatedTime: '5min',
      importance: 0,
      notifySettings: jsonEncode(['ai_auto']),
      createdAt: now,
      updatedAt: now,
    ),
    Task(
      title: '本棚の整理',
      dueDate: today.add(const Duration(days: 12)),
      categoryId: 4, // 家事
      estimatedTime: '1hour',
      importance: 0,
      notifySettings: jsonEncode(['1_day_before', '3_days_before']),
      createdAt: now,
      updatedAt: now,
    ),

    // 1ヶ月後
    Task(
      title: '車検',
      dueDate: today.add(const Duration(days: 30)),
      categoryId: 6, // その他
      estimatedTime: '1day',
      importance: 2,
      memo: 'ディーラーに事前予約が必要',
      notifySettings: jsonEncode(['ai_auto']),
      createdAt: now,
      updatedAt: now,
    ),

    // 定期タスク
    Task(
      title: '家賃振込',
      dueDate: _nextMonthDay(today, 25),
      categoryId: 1, // 支払い
      recurrenceType: 'monthly',
      recurrenceValue: 25,
      importance: 2,
      estimatedTime: '5min',
      notifySettings: jsonEncode(['ai_auto']),
      createdAt: now.subtract(const Duration(days: 30)),
      updatedAt: now.subtract(const Duration(days: 30)),
    ),
    Task(
      title: 'ジム会費',
      dueDate: _nextMonthDay(today, 1),
      categoryId: 1, // 支払い
      recurrenceType: 'monthly',
      recurrenceValue: 1,
      importance: 1,
      estimatedTime: '5min',
      notifySettings: jsonEncode(['1_day_before']),
      createdAt: now.subtract(const Duration(days: 30)),
      updatedAt: now.subtract(const Duration(days: 30)),
    ),

    // 完了済み
    Task(
      title: '引越し届け出',
      dueDate: today.subtract(const Duration(days: 5)),
      categoryId: 2, // 手続き
      isCompleted: true,
      completedAt: today.subtract(const Duration(days: 3)),
      importance: 2,
      createdAt: now.subtract(const Duration(days: 10)),
      updatedAt: today.subtract(const Duration(days: 3)),
    ),
  ];

  for (final task in tasks) {
    await db.insertTask(task);
  }
}

DateTime _nextMonthDay(DateTime today, int day) {
  var target = DateTime(today.year, today.month, day);
  if (target.isBefore(today) || target.isAtSameMomentAs(today)) {
    target = DateTime(today.year, today.month + 1, day);
  }
  return target;
}
