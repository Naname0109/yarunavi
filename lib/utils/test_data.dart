import 'dart:convert';
import 'dart:math';

import '../models/task.dart';
import '../services/database_service.dart';

/// AI整理テスト用の固定テストデータ（15件）をDBに投入する
Future<void> insertAiTestData(DatabaseService db) async {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  // カテゴリID: 1=支払い, 2=手続き, 3=買い物, 4=家事, 5=仕事, 6=その他
  final testTasks = <({String title, int dayOffset, int categoryId, String? recurrenceType, int? recurrenceValue, String? memo, String? estimatedTime, int importance})>[
    (title: '家賃振込', dayOffset: 1, categoryId: 1, recurrenceType: null, recurrenceValue: null, memo: '銀行振込またはネットバンキング', estimatedTime: '30min', importance: 2),
    (title: 'クレジットカード支払い', dayOffset: 3, categoryId: 1, recurrenceType: null, recurrenceValue: null, memo: '引き落とし口座の残高確認', estimatedTime: '5min', importance: 2),
    (title: '免許更新', dayOffset: 10, categoryId: 2, recurrenceType: null, recurrenceValue: null, memo: '平日のみ対応可。写真持参', estimatedTime: 'half_day', importance: 2),
    (title: '確定申告の書類準備', dayOffset: 20, categoryId: 2, recurrenceType: null, recurrenceValue: null, memo: '領収書整理、医療費控除の計算', estimatedTime: '1day', importance: 1),
    (title: '日用品買い出し', dayOffset: 5, categoryId: 3, recurrenceType: null, recurrenceValue: null, memo: '洗剤、ティッシュ、シャンプー', estimatedTime: '1hour', importance: 1),
    (title: 'プレゼント選び', dayOffset: 14, categoryId: 3, recurrenceType: null, recurrenceValue: null, memo: '友人の誕生日プレゼント。予算5000円', estimatedTime: '1hour', importance: 1),
    (title: '大掃除', dayOffset: 7, categoryId: 4, recurrenceType: null, recurrenceValue: null, memo: 'キッチン、浴室、リビング', estimatedTime: 'half_day', importance: 1),
    (title: 'エアコンフィルター掃除', dayOffset: 30, categoryId: 4, recurrenceType: null, recurrenceValue: null, memo: null, estimatedTime: '30min', importance: 0),
    (title: '企画書作成', dayOffset: 2, categoryId: 5, recurrenceType: null, recurrenceValue: null, memo: '来週の会議用。テンプレートあり', estimatedTime: 'half_day', importance: 2),
    (title: '週報提出', dayOffset: 0, categoryId: 5, recurrenceType: 'weekly', recurrenceValue: now.weekday, memo: '毎週提出', estimatedTime: '30min', importance: 1),
    (title: '歯医者予約', dayOffset: 8, categoryId: 6, recurrenceType: null, recurrenceValue: null, memo: '電話予約。平日午前希望', estimatedTime: '5min', importance: 1),
    (title: '本を読む', dayOffset: 21, categoryId: 6, recurrenceType: null, recurrenceValue: null, memo: null, estimatedTime: '1hour', importance: 0),
    (title: 'ジムに行く', dayOffset: 4, categoryId: 6, recurrenceType: null, recurrenceValue: null, memo: null, estimatedTime: '1hour', importance: 0),
    (title: '住民税支払い', dayOffset: 6, categoryId: 1, recurrenceType: null, recurrenceValue: null, memo: 'コンビニ払いまたは銀行窓口', estimatedTime: '30min', importance: 2),
    (title: 'パスポート更新', dayOffset: 45, categoryId: 2, recurrenceType: null, recurrenceValue: null, memo: '平日のみ。写真撮影が先に必要。戸籍謄本も取得', estimatedTime: '1day', importance: 1),
  ];

  for (final t in testTasks) {
    final dueDate = today.add(Duration(days: t.dayOffset));
    final createdAt = now.subtract(const Duration(days: 3));
    await db.insertTask(
      Task(
        title: t.title,
        dueDate: dueDate,
        categoryId: t.categoryId,
        importance: t.importance,
        memo: t.memo,
        estimatedTime: t.estimatedTime,
        recurrenceType: t.recurrenceType,
        recurrenceValue: t.recurrenceValue,
        notifySettings: jsonEncode(['ai_auto']),
        createdAt: createdAt,
        updatedAt: createdAt,
      ),
    );
  }
}

/// テストデータをランダムに生成してDBに投入する
Future<void> insertTestData(
  DatabaseService db, {
  String languageCode = 'ja',
}) async {
  final random = Random();
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final isJa = languageCode == 'ja';

  // カテゴリID: 1=支払い, 2=手続き, 3=買い物, 4=家事, 5=仕事, 6=その他
  final pools = isJa ? _titlePoolsJa : _titlePoolsEn;
  final memoPool = isJa ? _memoPoolJa : _memoPoolEn;

  final categoryIds = [1, 2, 3, 4, 5, 6];
  final estimatedTimes = [
    null,
    '5min',
    '30min',
    '1hour',
    'half_day',
    '1day',
  ];
  final notifyOptions = [
    ['ai_auto'],
    ['1_day_before'],
    ['3_days_before'],
    ['1_day_before', '3_days_before'],
    ['on_due'],
  ];

  // 8〜15件
  final count = 8 + random.nextInt(8);
  final tasks = <Task>[];

  for (var i = 0; i < count; i++) {
    // カテゴリ: 10%でnull
    int? categoryId;
    List<String> titlePool;
    if (random.nextInt(10) == 0) {
      categoryId = null;
      // nullのときはランダムなカテゴリのプールから拾う
      titlePool = pools[categoryIds[random.nextInt(categoryIds.length)]]!;
    } else {
      categoryId = categoryIds[random.nextInt(categoryIds.length)];
      titlePool = pools[categoryId]!;
    }

    final title = titlePool[random.nextInt(titlePool.length)];

    // 期限日: -3日 〜 +30日
    final dayOffset = -3 + random.nextInt(34);
    final dueDate = today.add(Duration(days: dayOffset));

    final importance = random.nextInt(3); // 0-2
    final priority = random.nextInt(5); // 0-4

    String? memo;
    if (random.nextInt(10) < 3) {
      memo = memoPool[random.nextInt(memoPool.length)];
    }

    String? recurrenceType;
    int? recurrenceValue;
    if (random.nextInt(10) < 3) {
      recurrenceType = 'monthly';
      recurrenceValue = 1 + random.nextInt(28);
    }

    // 期限切れの30%は完了済み
    bool isCompleted = false;
    DateTime? completedAt;
    if (dayOffset < 0 && random.nextInt(10) < 3) {
      isCompleted = true;
      completedAt = today.add(Duration(days: dayOffset + 1));
    }

    final estimatedTime = estimatedTimes[random.nextInt(estimatedTimes.length)];
    final notifySettings = notifyOptions[random.nextInt(notifyOptions.length)];

    final createdOffset = random.nextInt(10) + 1;
    tasks.add(
      Task(
        title: title,
        dueDate: dueDate,
        categoryId: categoryId,
        importance: importance,
        priority: priority,
        memo: memo,
        estimatedTime: estimatedTime,
        recurrenceType: recurrenceType,
        recurrenceValue: recurrenceValue,
        isCompleted: isCompleted,
        completedAt: completedAt,
        notifySettings: jsonEncode(notifySettings),
        createdAt: now.subtract(Duration(days: createdOffset)),
        updatedAt: now.subtract(Duration(days: createdOffset)),
      ),
    );
  }

  for (final task in tasks) {
    await db.insertTask(task);
  }
}

// ---- タイトルプール（カテゴリID別） ----

const Map<int, List<String>> _titlePoolsJa = {
  1: [
    '家賃振込', 'クレカ支払い', '電気代支払い', 'ふるさと納税', '保険料振込',
    '奨学金返済', '駐車場代', 'NHK受信料', '住民税', '年金',
    'ガス代支払い', '水道代支払い', 'スマホ料金', 'ネット回線料金',
  ],
  2: [
    '確定申告', '免許更新', 'パスポート更新', '転出届', '銀行口座開設',
    'マイナンバー受取', '健康診断予約', '歯医者予約', '住所変更手続き',
    '保険切り替え', '年末調整書類提出',
  ],
  3: [
    '日用品買い出し', 'プレゼント選び', '家具買い替え', 'スーツクリーニング',
    'コンタクト注文', '靴の修理', '本を注文', 'プリンターインク補充',
    '電池購入', '洗剤まとめ買い',
  ],
  4: [
    '大掃除', '洗濯機フィルター掃除', 'エアコンフィルター掃除', '布団乾燥',
    '冷蔵庫整理', '排水溝掃除', 'ゴミ出し', 'シーツ交換', '観葉植物の水やり',
    '玄関掃除',
  ],
  5: [
    '企画書作成', '週報提出', '1on1準備', '勉強会資料作成', '経費精算',
    'クライアント返信', '議事録まとめ', '見積書作成', 'KPI整理',
    '採用面談準備',
  ],
  6: [
    '映画を観る', '本を読む', 'ジム行く', '歯ブラシ交換', 'プラン見直し',
    '友達に連絡', '写真整理', 'カフェで作業', '散歩する', '献血',
  ],
};

const Map<int, List<String>> _titlePoolsEn = {
  1: [
    'Pay rent', 'Credit card payment', 'Electricity bill', 'Insurance premium',
    'Student loan', 'Parking fee', 'Property tax', 'Pension payment',
    'Gas bill', 'Water bill', 'Phone bill', 'Internet bill',
  ],
  2: [
    'Tax filing', 'Renew license', 'Renew passport', 'Change of address',
    'Open bank account', 'Pick up ID card', 'Book health checkup',
    'Dentist appointment', 'Switch insurance', 'Submit year-end forms',
  ],
  3: [
    'Buy groceries', 'Pick a gift', 'Replace furniture', 'Dry clean suit',
    'Order contacts', 'Shoe repair', 'Order books', 'Refill printer ink',
    'Buy batteries', 'Stock up detergent',
  ],
  4: [
    'Deep cleaning', 'Clean washer filter', 'Clean AC filter', 'Air futon',
    'Tidy fridge', 'Clean drains', 'Take out trash', 'Change sheets',
    'Water plants', 'Sweep entrance',
  ],
  5: [
    'Write proposal', 'Submit weekly report', 'Prepare 1on1', 'Make slides',
    'Expense report', 'Reply to client', 'Write meeting notes',
    'Draft estimate', 'Review KPIs', 'Prep interview',
  ],
  6: [
    'Watch a movie', 'Read a book', 'Go to gym', 'Replace toothbrush',
    'Review plans', 'Text a friend', 'Sort photos', 'Cafe work',
    'Take a walk', 'Donate blood',
  ],
};

const List<String> _memoPoolJa = [
  '平日のみ対応可',
  '午前中に終わらせたい',
  '事前予約が必要',
  '領収書を忘れずに',
  '近所のお店でOK',
  '混むので早めに',
  '前日までに準備',
];

const List<String> _memoPoolEn = [
  'Weekdays only',
  'Finish in the morning',
  'Booking required',
  'Bring receipt',
  'Local store is fine',
  'Go early to avoid crowds',
  'Prep the day before',
];
