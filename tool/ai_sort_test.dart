// ignore_for_file: avoid_print
/// AI整理の機能検証スクリプト
/// 実行: dart run tool/ai_sort_test.dart
///
/// --dart-defineは使えないため、.envから直接読み込む
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

void main() async {
  // .envからAPIキー読み込み
  final envFile = File('.env');
  if (!envFile.existsSync()) {
    print('ERROR: .env ファイルが見つかりません');
    exit(1);
  }
  final envLines = envFile.readAsLinesSync();
  String apiKey = '';
  for (final line in envLines) {
    if (line.startsWith('ANTHROPIC_API_KEY=')) {
      apiKey = line.substring('ANTHROPIC_API_KEY='.length).trim();
    }
  }
  if (apiKey.isEmpty) {
    print('ERROR: ANTHROPIC_API_KEY が .env に設定されていません');
    exit(1);
  }

  print('');
  print('═══════════════════════════════════════════');
  print('  YaruNavi AI整理 機能検証テスト');
  print('═══════════════════════════════════════════');
  print('');

  // テストデータ（15件）
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final weekdays = ['月', '火', '水', '木', '金', '土', '日'];
  final dayOfWeek = weekdays[now.weekday - 1];
  final todayStr =
      '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

  // 次の土曜を計算
  final daysUntilSat = (DateTime.saturday - now.weekday) % 7;
  var satOffset = daysUntilSat == 0 ? 7 : daysUntilSat;
  if (satOffset < 4) satOffset += 7;

  final testTasks = <Map<String, dynamic>>[
    {'id': 1, 'title': '家賃振込', 'dayOffset': 1, 'category_name': 'お金・支払い', 'importance': 2, 'memo': '銀行振込またはネットバンキング', 'estimated_time': '30min', 'recurrence_type': null},
    {'id': 2, 'title': 'クレジットカード支払い', 'dayOffset': 3, 'category_name': 'お金・支払い', 'importance': 2, 'memo': '引き落とし口座の残高確認', 'estimated_time': '5min', 'recurrence_type': null},
    {'id': 3, 'title': '免許更新', 'dayOffset': 10, 'category_name': '手続き・届出', 'importance': 2, 'memo': '平日のみ対応可。写真持参', 'estimated_time': 'half_day', 'recurrence_type': null},
    {'id': 4, 'title': '確定申告の書類準備', 'dayOffset': 20, 'category_name': '手続き・届出', 'importance': 1, 'memo': '領収書整理、医療費控除の計算', 'estimated_time': '1day', 'recurrence_type': null},
    {'id': 5, 'title': '日用品買い出し', 'dayOffset': 5, 'category_name': '買い物', 'importance': 1, 'memo': '洗剤、ティッシュ、シャンプー', 'estimated_time': '1hour', 'recurrence_type': null},
    {'id': 6, 'title': 'プレゼント選び', 'dayOffset': 14, 'category_name': '買い物', 'importance': 1, 'memo': '友人の誕生日プレゼント。予算5000円', 'estimated_time': '1hour', 'recurrence_type': null},
    {'id': 7, 'title': '大掃除', 'dayOffset': 7, 'category_name': '家事・生活', 'importance': 1, 'memo': 'キッチン、浴室、リビング', 'estimated_time': 'half_day', 'recurrence_type': null},
    {'id': 8, 'title': 'エアコンフィルター掃除', 'dayOffset': 30, 'category_name': '家事・生活', 'importance': 0, 'memo': null, 'estimated_time': '30min', 'recurrence_type': null},
    {'id': 9, 'title': '企画書作成', 'dayOffset': 2, 'category_name': '仕事', 'importance': 2, 'memo': '来週の会議用。テンプレートあり', 'estimated_time': 'half_day', 'recurrence_type': null},
    {'id': 10, 'title': '週報提出', 'dayOffset': 0, 'category_name': '仕事', 'importance': 1, 'memo': '毎週提出', 'estimated_time': '30min', 'recurrence_type': 'weekly'},
    {'id': 11, 'title': '歯医者予約', 'dayOffset': 8, 'category_name': 'その他', 'importance': 1, 'memo': '電話予約。平日午前希望', 'estimated_time': '5min', 'recurrence_type': null},
    {'id': 12, 'title': '本を読む', 'dayOffset': 21, 'category_name': 'その他', 'importance': 0, 'memo': null, 'estimated_time': '1hour', 'recurrence_type': null},
    {'id': 13, 'title': 'ジムに行く', 'dayOffset': 4, 'category_name': 'その他', 'importance': 0, 'memo': null, 'estimated_time': '1hour', 'recurrence_type': null},
    {'id': 14, 'title': '住民税支払い', 'dayOffset': satOffset, 'category_name': 'お金・支払い', 'importance': 2, 'memo': 'コンビニ払いまたは銀行窓口。期限日は土曜', 'estimated_time': '30min', 'recurrence_type': null},
    {'id': 15, 'title': 'パスポート更新', 'dayOffset': 45, 'category_name': '手続き・届出', 'importance': 1, 'memo': '平日のみ。写真撮影が先に必要。戸籍謄本も取得', 'estimated_time': '1day', 'recurrence_type': null},
  ];

  // タスクJSON作成
  final tasksJson = testTasks.map((t) {
    final dueDate = today.add(Duration(days: t['dayOffset'] as int));
    final dueDow = weekdays[dueDate.weekday - 1];
    final dueDateStr =
        '${dueDate.year}-${dueDate.month.toString().padLeft(2, '0')}-${dueDate.day.toString().padLeft(2, '0')}';
    return {
      'id': t['id'],
      'title': t['title'],
      'due_date': dueDateStr,
      'due_day_of_week': dueDow,
      'days_left': t['dayOffset'],
      'memo': t['memo'],
      'estimated_time': t['estimated_time'],
      'importance': t['importance'],
      'category_name': t['category_name'],
      'recurrence_type': t['recurrence_type'],
      'is_completed': false,
    };
  }).toList();

  print('■ テストデータ: ${testTasks.length}件');
  for (final t in testTasks) {
    print('  ${t['title']} | 残${t['dayOffset']}日 | imp=${t['importance']} | ${t['category_name']}');
  }

  // システムプロンプトを読み込み（ai_service.dartから抽出は面倒なので直接API呼び出し）
  // ai_service.dartのプロンプトをそのまま使う
  final systemPromptFile = File('lib/services/ai_service.dart');
  final sourceCode = systemPromptFile.readAsStringSync();
  final promptMatch = RegExp(
          r"static const _systemPrompt =\s*'''([\s\S]*?)''';")
      .firstMatch(sourceCode);
  if (promptMatch == null) {
    print('ERROR: システムプロンプトの抽出に失敗');
    exit(1);
  }
  final systemPrompt = promptMatch.group(1)!;

  final userPrompt =
      '今日の日付: $todayStr\n曜日: $dayOfWeek\n\nタスクリスト:\n${jsonEncode(tasksJson)}';

  print('');
  print('■ API呼び出し中...');

  final requestBody = jsonEncode({
    'model': 'claude-haiku-4-5-20251001',
    'max_tokens': 4096,
    'temperature': 0.2,
    'system': [
      {'type': 'text', 'text': systemPrompt}
    ],
    'messages': [
      {'role': 'user', 'content': userPrompt}
    ],
  });

  final response = await http.post(
    Uri.parse('https://api.anthropic.com/v1/messages'),
    headers: {
      'Content-Type': 'application/json',
      'x-api-key': apiKey,
      'anthropic-version': '2023-06-01',
    },
    body: requestBody,
  );

  print('  ステータス: ${response.statusCode}');

  if (response.statusCode != 200) {
    print('ERROR: APIエラー');
    print(response.body);
    exit(1);
  }

  final json = jsonDecode(response.body) as Map<String, dynamic>;
  final content = json['content'] as List;
  var text = (content[0]['text'] as String).trim();

  // JSON抽出: テキストの先頭/末尾の```を除去
  text = text.replaceAll(RegExp(r'^```json\s*\n?'), '');
  text = text.replaceAll(RegExp(r'\n?```\s*$'), '');
  text = text.trim();

  Map<String, dynamic> parsed;
  try {
    parsed = jsonDecode(text) as Map<String, dynamic>;
  } catch (e) {
    print('ERROR: JSONパース失敗: $e');
    print('レスポンステキスト（先頭300文字）:');
    print(text.substring(0, text.length > 300 ? 300 : text.length));
    exit(1);
  }

  // 結果表示
  print('');
  print('═══════════════════════════════════════════');
  print('  AI整理結果');
  print('═══════════════════════════════════════════');

  print('');
  print('■ サマリー: ${parsed['summary_ja']}');

  print('');
  final tasks = parsed['tasks'] as List;
  final priorityCounts = <int, int>{1: 0, 2: 0, 3: 0, 4: 0};

  // ヘッダー
  print('┌──────────────────────┬───┬────────────┬────────────┬────────────┐');
  print('│ タスク名             │ P │ start      │ end        │ notify     │');
  print('├──────────────────────┼───┼────────────┼────────────┼────────────┤');

  for (final r in tasks) {
    final p = r['priority'] as int;
    priorityCounts[p] = (priorityCounts[p] ?? 0) + 1;
    final name = (r['task_id'] as int) <= testTasks.length
        ? testTasks.firstWhere((t) => t['id'] == r['task_id'])['title'] as String
        : '?';
    final padName = name.padRight(18);
    print(
        '│ $padName │ $p │ ${(r['recommended_date'] ?? '-').toString().padRight(10)} │ ${(r['notify_date'] ?? '-').toString().padRight(10)} │');
  }
  print('└──────────────────────┴───┴────────────┴────────────┴────────────┘');

  // コメント表示
  print('');
  print('■ AIコメント:');
  for (final r in tasks) {
    final id = r['task_id'] as int;
    final name = id <= testTasks.length
        ? testTasks.firstWhere((t) => t['id'] == id)['title']
        : '?';
    print('  [$name] ${r['comment_ja'] ?? '(なし)'}');
  }

  // 通知理由
  print('');
  print('■ 通知理由:');
  for (final r in tasks) {
    final id = r['task_id'] as int;
    final name = id <= testTasks.length
        ? testTasks.firstWhere((t) => t['id'] == id)['title']
        : '?';
    print('  [$name] ${r['notify_date'] ?? '-'}: ${r['notify_reason_ja'] ?? '(なし)'}');
  }

  // Priority分布
  print('');
  print('■ Priority分布:');
  for (final p in [1, 2, 3, 4]) {
    final bar = '█' * (priorityCounts[p] ?? 0);
    print('  P$p: ${priorityCounts[p] ?? 0}件 $bar');
  }

  // バリデーション
  print('');
  print('═══════════════════════════════════════════');
  print('  自動バリデーション');
  print('═══════════════════════════════════════════');

  final issues = <String>[];

  for (final r in tasks) {
    final id = r['task_id'] as int;
    if (id > testTasks.length) continue;
    final t = testTasks.firstWhere((t) => t['id'] == id);
    final title = t['title'] as String;
    final daysLeft = t['dayOffset'] as int;
    final priority = r['priority'] as int;
    final dueDate = today.add(Duration(days: daysLeft));

    // 優先度チェック
    if (daysLeft <= 0 && priority != 1) {
      issues.add('❌ [$title] 今日期限なのにP$priority（P1であるべき）');
    }
    if (daysLeft == 1 && (t['importance'] as int) == 2 && priority > 2) {
      issues.add('❌ [$title] 明日期限+重要度高なのにP$priority');
    }
    if (daysLeft >= 30 && priority <= 2) {
      issues.add('⚠️ [$title] 残${daysLeft}日なのにP$priority（P3-4が適切）');
    }

    // コメント品質
    final comment = r['comment_ja'] as String?;
    if (comment == null || comment.isEmpty) {
      issues.add('❌ [$title] AIコメントが空');
    } else if (comment == '重要なタスクです' ||
        comment == '早めに対応しましょう' ||
        comment == '頑張りましょう') {
      issues.add('❌ [$title] 禁止コメント: "$comment"');
    }

    // 日付チェック
    final recDate = r['recommended_date'] as String?;
    if (recDate != null) {
      final recDt = DateTime.parse(recDate);
      if (recDt.isBefore(today)) {
        issues.add('❌ [$title] recommended_dateが過去: $recDate');
      }
      if (recDt.isAfter(dueDate)) {
        issues.add('❌ [$title] recommended_dateがdue_date超過: $recDate > $dueDate');
      }
    }

    final notifyDate = r['notify_date'] as String?;
    if (notifyDate != null) {
      final nd = DateTime.parse(notifyDate);
      if (nd.isBefore(today)) {
        issues.add('❌ [$title] notify_dateが過去: $notifyDate');
      }
      if (nd.isAfter(dueDate)) {
        issues.add('❌ [$title] notify_dateが期限超過: $notifyDate');
      }
    }
    if (r['notify_reason_ja'] == null ||
        (r['notify_reason_ja'] as String).isEmpty) {
      issues.add('⚠️ [$title] notify_reasonが空');
    }
  }

  // 分布チェック
  final p1 = priorityCounts[1] ?? 0;
  final p4 = priorityCounts[4] ?? 0;
  if (p1 > 4) issues.add('⚠️ [分布] P1が$p1件（理想2-3件）');
  if (p1 == 0) issues.add('❌ [分布] P1が0件');
  if (p4 == 0) issues.add('⚠️ [分布] P4が0件（最低2件が理想）');

  // 特定タスクチェック
  for (final r in tasks) {
    final id = r['task_id'] as int;
    if (id > testTasks.length) continue;
    final t = testTasks.firstWhere((t) => t['id'] == id);
    final title = t['title'] as String;
    final p = r['priority'] as int;
    if (title == '週報提出' && p != 1) issues.add('❌ [週報提出] 今日期限の定期タスクがP$p');
    if (title == '家賃振込' && p > 2) issues.add('❌ [家賃振込] 明日期限+重要度高がP$p');
    if (title == 'パスポート更新' && p < 3) issues.add('⚠️ [パスポート更新] 45日後がP$p');
    if (title == '本を読む' && p < 3) issues.add('⚠️ [本を読む] 21日後+低重要度がP$p');
  }

  // 質問
  final questions = parsed['questions_ja'] as List? ?? [];
  if (questions.isNotEmpty) {
    print('');
    print('■ AIからの質問:');
    for (final q in questions) {
      print('  - $q');
    }
  }

  // 結果
  print('');
  if (issues.isEmpty) {
    print('✅ 全チェック通過! 問題なし');
  } else {
    final critical = issues.where((i) => i.startsWith('❌')).length;
    final warnings = issues.where((i) => i.startsWith('⚠️')).length;
    print('検出: ❌ $critical件 ⚠️ $warnings件');
    for (final issue in issues) {
      print('  $issue');
    }
  }

  print('');
  print('═══════════════════════════════════════════');
  print('  テスト完了');
  print('═══════════════════════════════════════════');
}
