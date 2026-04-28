import 'dart:convert';

import '../models/category.dart' as model;
import '../models/task.dart';
import '../services/database_service.dart';

DateTime _today() {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
}

int _nextSaturdayOffset() {
  final now = DateTime.now();
  final daysUntilSat = (DateTime.saturday - now.weekday) % 7;
  return daysUntilSat == 0 ? 7 : daysUntilSat;
}

/// パターン1: シンプルデータ（5件）
/// タスク名と期限のみ。一般ユーザーの初回利用を想定。
Future<void> insertSimpleTestData(DatabaseService db) async {
  await db.deleteAllData();
  final today = _today();
  final now = DateTime.now();

  final tasks = [
    (title: '家賃振込', days: 3),
    (title: '牛乳を買う', days: 1),
    (title: '歯医者予約する', days: 10),
    (title: '部屋の掃除', days: 7),
    (title: 'レポート提出', days: 5),
  ];

  for (final t in tasks) {
    await db.insertTask(Task(
      title: t.title,
      dueDate: today.add(Duration(days: t.days)),
      createdAt: now,
      updatedAt: now,
    ));
  }
}

/// パターン2: 詳細データ（10件）
/// 全フィールド活用。カテゴリ、メモ、定期タスク、所要時間、重要度を設定。
Future<void> insertDetailedTestData(DatabaseService db) async {
  await db.deleteAllData();
  final today = _today();
  final now = DateTime.now();

  final tasks = <({
    String title,
    int days,
    int? categoryId,
    String? memo,
    String? recurrenceType,
    int? recurrenceValue,
    String? estimatedTime,
    int importance,
  })>[
    (
      title: '家賃振込',
      days: 3,
      categoryId: 1,
      memo: '三井住友銀行 口座引き落とし',
      recurrenceType: 'monthly',
      recurrenceValue: today.add(const Duration(days: 3)).day,
      estimatedTime: '15min',
      importance: 2,
    ),
    (
      title: 'クレジットカード支払い',
      days: 5,
      categoryId: 1,
      memo: '楽天カード 限度額に注意',
      recurrenceType: 'monthly',
      recurrenceValue: today.add(const Duration(days: 5)).day,
      estimatedTime: '15min',
      importance: 2,
    ),
    (
      title: '免許更新',
      days: 14,
      categoryId: 2,
      memo: '府中運転免許試験場 写真持参',
      recurrenceType: null,
      recurrenceValue: null,
      estimatedTime: 'half_day',
      importance: 2,
    ),
    (
      title: '確定申告の書類準備',
      days: 30,
      categoryId: 2,
      memo: '領収書を整理してから',
      recurrenceType: null,
      recurrenceValue: null,
      estimatedTime: '4hour',
      importance: 1,
    ),
    (
      title: '日用品買��出し',
      days: 4,
      categoryId: 3,
      memo: 'シャンプー、洗剤、ティッシュ',
      recurrenceType: null,
      recurrenceValue: null,
      estimatedTime: '1hour',
      importance: 1,
    ),
    (
      title: 'プレゼント選び',
      days: 20,
      categoryId: 3,
      memo: '彼女の誕生日 予算1万円',
      recurrenceType: null,
      recurrenceValue: null,
      estimatedTime: '2hour',
      importance: 1,
    ),
    (
      title: '週報提出',
      days: 0,
      categoryId: 5,
      memo: 'Teamsで提出 テンプレあり',
      recurrenceType: 'weekly',
      recurrenceValue: now.weekday,
      estimatedTime: '30min',
      importance: 1,
    ),
    (
      title: '企画書作成',
      days: 2,
      categoryId: 5,
      memo: 'A社向け 10ページ程度',
      recurrenceType: null,
      recurrenceValue: null,
      estimatedTime: '3hour',
      importance: 2,
    ),
    (
      title: 'ジムに行く',
      days: 5,
      categoryId: 6,
      memo: '脚トレの日',
      recurrenceType: 'weekly',
      recurrenceValue: today.add(const Duration(days: 5)).weekday,
      estimatedTime: '1.5hour',
      importance: 0,
    ),
    (
      title: '本を読む',
      days: 45,
      categoryId: 6,
      memo: '「イシューからはじめよ」残り100ページ',
      recurrenceType: null,
      recurrenceValue: null,
      estimatedTime: '2hour',
      importance: 0,
    ),
  ];

  for (final t in tasks) {
    await db.insertTask(Task(
      title: t.title,
      dueDate: today.add(Duration(days: t.days)),
      categoryId: t.categoryId,
      importance: t.importance,
      memo: t.memo,
      estimatedTime: t.estimatedTime,
      recurrenceType: t.recurrenceType,
      recurrenceValue: t.recurrenceValue,
      notifySettings: jsonEncode(['ai_auto']),
      createdAt: now,
      updatedAt: now,
    ));
  }
}

/// パターン3: エッジケースデータ（8件）
/// 境界値やエラーが起きやすいパターンを網羅。
Future<void> insertEdgeCaseTestData(DatabaseService db) async {
  await db.deleteAllData();
  final today = _today();
  final now = DateTime.now();

  final customCatId = await db.addCategory(model.Category(
    name: 'テスト',
    icon: '🧪',
    sortOrder: 99,
    isDefault: false,
    createdAt: now,
  ));

  final longMemo = List.filled(5, 'これは非常に長いメモです。').join();

  final tasks = <({
    String title,
    int days,
    int? categoryId,
    String? memo,
  })>[
    (title: '期限が今日のタスク', days: 0, categoryId: null, memo: null),
    (title: '期限が昨日のタスク', days: -1, categoryId: null, memo: null),
    (title: '期限が1年後のタスク', days: 365, categoryId: null, memo: null),
    (
      title: 'とても長いタスク名のテストケースです。このタスク名は表示が切れるかどうかを確認するために意図的に長くしています',
      days: 7,
      categoryId: null,
      memo: null,
    ),
    (title: '絵文字タスク 🎉🏠💰', days: 10, categoryId: null, memo: null),
    (
      title: '期限が明日の土曜タスク',
      days: _nextSaturdayOffset(),
      categoryId: 2,
      memo: null,
    ),
    (title: 'メモが非���に長いタスク', days: 14, categoryId: null, memo: longMemo),
    (
      title: '全カテゴリ設定タスク',
      days: 7,
      categoryId: customCatId,
      memo: null,
    ),
  ];

  for (final t in tasks) {
    await db.insertTask(Task(
      title: t.title,
      dueDate: today.add(Duration(days: t.days)),
      categoryId: t.categoryId,
      memo: t.memo,
      createdAt: now,
      updatedAt: now,
    ));
  }
}
