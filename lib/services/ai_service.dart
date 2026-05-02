import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/task.dart';
import '../utils/constants.dart';
import '../utils/date_utils.dart' as app_date;

/// AI整理の結果1件
class AiSortResult {
  final int taskId;
  final int priority;
  final String? commentJa;
  final String? commentEn;
  final List<String> recommendedNotifyDates;
  final String? notifyDate;
  final String? notifyReasonJa;
  final String? notifyReasonEn;
  final String? recommendedDate;
  final List<String> suggestedSubtasksJa;
  final List<String> suggestedSubtasksEn;

  const AiSortResult({
    required this.taskId,
    required this.priority,
    this.commentJa,
    this.commentEn,
    this.recommendedNotifyDates = const [],
    this.notifyDate,
    this.notifyReasonJa,
    this.notifyReasonEn,
    this.recommendedDate,
    this.suggestedSubtasksJa = const [],
    this.suggestedSubtasksEn = const [],
  });

  Map<String, dynamic> toJson() => {
        'task_id': taskId,
        'priority': priority,
        'comment_ja': commentJa,
        'comment_en': commentEn,
        'recommended_notify_dates': recommendedNotifyDates,
        'notify_date': notifyDate,
        'notify_reason_ja': notifyReasonJa,
        'notify_reason_en': notifyReasonEn,
        'recommended_date': recommendedDate,
        'suggested_subtasks_ja': suggestedSubtasksJa,
        'suggested_subtasks_en': suggestedSubtasksEn,
      };
}

/// AI整理のレスポンス全体
class AiSortResponse {
  final String? summaryJa;
  final String? summaryEn;
  final List<AiSortResult> tasks;
  final List<String> questionsJa;
  final List<String> questionsEn;
  final bool isFallback;

  const AiSortResponse({
    this.summaryJa,
    this.summaryEn,
    required this.tasks,
    this.questionsJa = const [],
    this.questionsEn = const [],
    this.isFallback = false,
  });

  Map<String, dynamic> toJson() => {
        'summary_ja': summaryJa,
        'summary_en': summaryEn,
        'tasks': tasks.map((t) => t.toJson()).toList(),
        'questions_ja': questionsJa,
        'questions_en': questionsEn,
      };

  factory AiSortResponse.fromJson(Map<String, dynamic> json) {
    return AiSortResponse(
      summaryJa: json['summary_ja'] as String?,
      summaryEn: json['summary_en'] as String?,
      tasks: (json['tasks'] as List?)?.map((r) {
            final map = r as Map<String, dynamic>;
            return AiSortResult(
              taskId: map['task_id'] as int,
              priority: (map['priority'] as int).clamp(1, 4),
              commentJa: map['comment_ja'] as String?,
              commentEn: map['comment_en'] as String?,
              recommendedNotifyDates:
                  (map['recommended_notify_dates'] as List?)?.cast<String>() ??
                      [],
              notifyDate: map['notify_date'] as String?,
              notifyReasonJa: map['notify_reason_ja'] as String?,
              notifyReasonEn: map['notify_reason_en'] as String?,
              recommendedDate: map['recommended_date'] as String?,
              suggestedSubtasksJa:
                  (map['suggested_subtasks_ja'] as List?)?.cast<String>() ??
                      [],
              suggestedSubtasksEn:
                  (map['suggested_subtasks_en'] as List?)?.cast<String>() ??
                      [],
            );
          }).toList() ??
          [],
      questionsJa:
          (json['questions_ja'] as List?)?.cast<String>() ?? [],
      questionsEn:
          (json['questions_en'] as List?)?.cast<String>() ?? [],
    );
  }
}

/// AI整理で発生しうるエラー種別
enum AiErrorType { network, parse, rateLimit }

class AiServiceException implements Exception {
  final AiErrorType type;
  final String message;
  const AiServiceException(this.type, this.message);
}

class AiService {
  static const _systemPrompt =
      '''あなたはタスク管理の専門家であり、ユーザーの日常生活をサポートするパーソナルアシスタントです。
ユーザーのタスクリストを受け取り、優先順位付け・具体的アドバイス・通知日の提案を行ってください。
必ず以下のルールに厳密に従ってください。

## 分類ルール（priority 1〜4）
まず期限日(due_date)と今日の日付の差分(残日数)で基本priorityを決め、その後importanceで調整する。

基本priority（残日数ベース）:
- 残0日以下(今日期限・期限切れ) → priority 1
- 残1〜2日 → priority 1（重要度高または所要時間長い）またはpriority 2
- 残3〜7日 → priority 2
- 残8〜14日 → priority 3
- 残15日以上 → priority 4

importance調整:
- importance=2（高）: priorityを1段階上げる（最高は1）
- importance=0（低）: priorityを1段階下げる（最低は4）

priority分布の目安（15件の場合）:
- priority 1: 2〜3件（今日中に着手すべきもの）
- priority 2: 3〜5件（今週中）
- priority 3: 3〜5件（来週以降）
- priority 4: 2〜4件（余裕あり）
- 偏りすぎないように分布を意識すること

追加ルール:
- priority 1は最大3件に抑える。4件以上になる場合は重要度「低」や所要時間「5min」をpriority 2に下げる
- 定期タスク(recurrence_type非null)の今日期限分は必ずpriority 1
- 1日のpriority 1タスクは現実的にこなせる量に（目安: 合計所要時間4時間以内）

## カテゴリ別コメントガイドライン（最も重要）
comment_ja/comment_enには、カテゴリとタスクの性質に応じた具体的・実用的なアドバイスを1-2文で書く。
機械的な「期限が近いです」「重要なタスクです」「早めに対応しましょう」は絶対に禁止。

### 支払い・お金カテゴリ:
- 銀行振込: 「ネットバンキングなら今日中に完了できます。窓口は15時までなので午前中がおすすめ」
- クレジットカード: 「引き落とし口座の残高を確認し、不足なら前日までに入金を」
- 税金(住民税等): 「コンビニ払いなら24時間対応。期限日が土曜なので金曜までに済ませましょう」
- 共通: 振込手数料、引き落とし日、口座残高への言及を含める

### 手続き・届出カテゴリ:
- 免許更新・パスポート: 「窓口は平日のみ、混雑を避けて午前中がおすすめ。必要書類を事前確認」
- 確定申告: 「書類準備に時間がかかります。領収書整理→計算→記入の順で進めましょう」
- 共通: 営業日・窓口時間・必要書類・事前準備への言及を含める

### 買い物カテゴリ:
- 同カテゴリの買い物タスクが複数ある場合: 「日用品とプレゼント選びをまとめて週末に買い物に行くと効率的」
- 日用品: 「リストを事前に作成して買い忘れ防止。近所のお店でまとめ買いが効率的」
- プレゼント: 「予算と相手の好みを整理してから探すと迷いません」

### 家事カテゴリ:
- 大掃除: 「一度にやらず、場所ごとに分けて数日かけると負担が軽い」
- 掃除系: 「所要時間は短め。他のタスクの合間に片付けられます」

### 仕事カテゴリ:
- 企画書・資料作成: 「テンプレートがあれば構成から着手。集中できる午前中がおすすめ」
- 週報・定期提出物: 「ルーティン化して毎週同じ時間帯に処理するのがコツ」

### その他カテゴリ:
- 予約系(歯医者等): 「電話予約は診療時間内に。平日午前が繋がりやすい」
- 読書・運動: 「気軽に始められるタスク。スキマ時間を活用しましょう」

### メモ活用ルール:
- メモに「平日のみ」→ 期限日が土日なら「○日は△曜日です。前日の金曜までに対応を」
- メモに「事前予約が必要」→ 「先に予約を入れてから当日に備えましょう」
- メモに予算情報 → コメントに予算への言及を含める
- メモに具体的な手順 → 手順に沿ったアドバイスを提供

## 推奨実行日 (recommended_date) の決定ルール
- 形式: yyyy-MM-dd（1日だけ返す）
- 制約: today ≤ recommended_date ≤ due_date（厳守）
- 過去日にならないこと（最低でもtoday）
- 【最重要】recommended_dateはdue_dateより前の日を設定すること。due_dateと同じ日は原則禁止。唯一の例外はpriority 1かつdue_dateがtodayの場合のみ。
- 「いつ着手すべきか」を示す日付であり、「いつまでに終わらせるか」ではない

priority別の基準:
- priority 1(緊急): today（due_dateが今日の場合のみdue_dateと一致してよい）
- priority 2(要注意): due_dateの1〜2日前（例: due=4/30なら4/28〜4/29）
- priority 3(通常): due_dateの3〜5日前（例: due=5/10なら5/5〜5/7）
- priority 4(余裕): todayから1〜2週間後（例: today=4/28, due=6/30なら5/5〜5/12）

特殊ルール:
- 手続き系(窓口必要): 平日(月〜金)に設定。土日は避ける
- 支払い系: 引き落とし日の前日以前（前営業日が理想）
- recommended_date == due_dateの出力は不正とみなす（priority 1かつdue==today除く）

## 通知日 (notify_date) の決定ルール
- 形式: yyyy-MM-dd（1つだけ設定）
- 通知理由を notify_reason_ja / notify_reason_en に1行で記載
- 過去の日付は絶対に設定しない（最低でもtoday）

カテゴリ別基準:
- 支払い系: 引き落とし日の2日前（口座残高確認のため）
- 手続き系: 期限の前営業日（窓口が平日のみのため）
- priority 1(今日期限): today（当日通知）
- priority 2(今週中): 期限の1〜2日前
- priority 3(来週以降): 期限の3日前
- priority 4(余裕あり): 期限の5〜7日前

## recommended_notify_dates (補助的な複数日)
- 緊急(priority 1): [today] のみ
- 手続き・届出系: [期限の3営業日前, 前営業日]
- 支払い系: [引き落とし3日前, 前日]
- 重要度「高」(importance=2): 上記に加え1週間前も追加
- 通常: [期限1日前]
- 余裕あり: [1週間前, 3日前]
- 過去の日付は含めない

## タスク分割の提案ルール
- 所要時間「1day」以上かつメモに複数ステップがあるタスクのみ
- 半日以下のタスクは原則分割しない
- 分割不要なタスクは空配列[]
- 全タスクの2割以下に抑える

## 質問ルール
- 情報不足で判断が困難な場合のみ、最大3件まで
- 質問不要なら空配列[]

## 全体サマリルール
summary_ja/summary_enに今日のアクションプランを1-2文で具体的にまとめる。
例: 「今日は家賃振込と週報提出を午前中に済ませ、午後は企画書作成に集中しましょう。」

## 出力形式
以下のJSON形式で返してください。マークダウンの```で囲まないでください。
{
  "summary_ja": "<日本語の全体サマリ>",
  "summary_en": "<英語の全体サマリ>",
  "tasks": [
    {
      "task_id": <int>,
      "priority": <1-4>,
      "comment_ja": "<日本語アドバイス1-2文>",
      "comment_en": "<英語アドバイス1-2文>",
      "recommended_notify_dates": ["yyyy-MM-dd", ...],
      "notify_date": "yyyy-MM-dd",
      "notify_reason_ja": "<通知理由1行>",
      "notify_reason_en": "<notify reason one line>",
      "recommended_date": "yyyy-MM-dd",
      "suggested_subtasks_ja": [],
      "suggested_subtasks_en": []
    }
  ],
  "questions_ja": [],
  "questions_en": []
}

## 良い出力例（few-shot）

例1: 家賃振込（明日期限、カテゴリ: お金、importance: 2）
→ priority: 1
→ comment_ja: "明日が振込期限です。ネットバンキングなら今日中に完了できます。窓口は15時までなので午前中がおすすめ。"
→ recommended_date: today
→ notify_date: today, notify_reason_ja: "明日の振込期限に備えて今日中に対応"

例2: 免許更新（10日後期限、カテゴリ: 手続き、メモ: 平日のみ対応可）
→ priority: 3
→ comment_ja: "免許センターは平日のみ営業。混雑を避けて午前中に行くのがおすすめです。写真持参を忘れずに。"
→ recommended_date: 期限3日前の平日
→ notify_date: 期限3日前, notify_reason_ja: "免許更新の窓口訪問を来週中に"

例3: 住民税支払い（6日後の土曜期限、カテゴリ: お金）
→ priority: 2
→ comment_ja: "期限日は土曜です。銀行窓口は平日15時まで。コンビニ払いなら土曜でもOKですが、余裕を持って金曜までに。"
→ recommended_date: 期限前日の金曜
→ notify_date: 期限2日前, notify_reason_ja: "住民税の支払い期限が土曜のため金曜までに"

例4: パスポート更新（45日後期限、カテゴリ: 手続き、importance: 1）
→ priority: 4
→ comment_ja: "写真撮影と戸籍謄本の取得が先に必要です。来月前半に窓口訪問の予定を立てましょう。"
→ recommended_date: 2週間後の平日
→ notify_date: 期限7日前, notify_reason_ja: "パスポート更新の準備開始時期"

例5: 本を読む（21日後期限、カテゴリ: その他、importance: 0）
→ priority: 4
→ comment_ja: "急ぎではありません。週末や通勤時間などスキマ時間を活用しましょう。"
→ recommended_date: 期限5日前
→ notify_date: 期限5日前, notify_reason_ja: "読書の時間を確保するリマインド"

## 悪い出力例（これらは禁止）
- "期限が近いので早めに対応しましょう" → 具体性がない
- "重要なタスクです" → 当たり前すぎる
- "頑張りましょう" → アドバイスになっていない
- "注意が必要です" → 何に注意するか不明''';

  /// タスクリストをAIで整理する
  static Future<AiSortResponse> sortTasks(
    List<Task> tasks, {
    Map<int, String> categoryNames = const {},
    String? additionalContext,
    double executionTimingFactor = 0.5,
  }) async {
    debugPrint('[PROXY-DEBUG] AI_PROXY_URL: "${AppConstants.aiProxyUrl}"');
    debugPrint('[PROXY-DEBUG] AI_APP_TOKEN: ${AppConstants.aiAppToken.isNotEmpty ? "設定済み(${AppConstants.aiAppToken.length}文字)" : "未設定"}');
    debugPrint('[PROXY-DEBUG] ANTHROPIC_API_KEY: ${AppConstants.anthropicApiKey.isNotEmpty ? "設定済み" : "未設定"}');
    debugPrint('[PROXY-DEBUG] kDebugMode: $kDebugMode');

    if (AppConstants.aiProxyUrl.isEmpty &&
        (!kDebugMode || AppConstants.anthropicApiKey.isEmpty)) {
      debugPrint('[PROXY-DEBUG] → フォールバック実行（API設定なし）');
      return _fallbackSort(tasks, executionTimingFactor: executionTimingFactor);
    }

    final now = DateTime.now();
    final todayStr = app_date.formatDateForDb(now);
    final weekdays = ['月', '火', '水', '木', '金', '土', '日'];
    final dayOfWeek = weekdays[now.weekday - 1];

    final tasksJson = tasks.map((t) {
      final dueDow = weekdays[t.dueDate.weekday - 1];
      final daysLeft = DateTime(t.dueDate.year, t.dueDate.month, t.dueDate.day)
          .difference(DateTime(now.year, now.month, now.day))
          .inDays;
      return {
        'id': t.id,
        'title': t.title,
        'due_date': app_date.formatDateForDb(t.dueDate),
        'due_day_of_week': dueDow,
        'days_left': daysLeft,
        'memo': t.memo,
        'estimated_time': t.estimatedTime,
        'importance': t.importance,
        'category_name': t.categoryId != null
            ? categoryNames[t.categoryId] ?? ''
            : '',
        'recurrence_type': t.recurrenceType,
        'is_completed': t.isCompleted,
      };
    }).toList();

    var userPrompt =
        '今日の日付: $todayStr\n曜日: $dayOfWeek\n\nタスクリスト:\n${jsonEncode(tasksJson)}';
    userPrompt +=
        '\n\nユーザーの実行日傾向: ${executionTimingFactor.toStringAsFixed(1)}'
        '（0.0=期限直前、0.5=バランス、1.0=かなり早め）。'
        'この値に応じてrecommended_dateを調整してください。'
        '値が低いほど期限に近い日を、高いほど余裕を持った日を推奨してください。';
    if (additionalContext != null) {
      userPrompt += '\n\n追加情報:\n$additionalContext';
    }

    final requestBody = jsonEncode({
      'model': AppConstants.anthropicModel,
      'max_tokens': 4096,
      'temperature': 0.2,
      'system': [
        {
          'type': 'text',
          'text': _systemPrompt,
          'cache_control': {'type': 'ephemeral'},
        }
      ],
      'messages': [
        {'role': 'user', 'content': userPrompt}
      ],
    });

    debugPrint('[AI] リクエスト送信: ${tasks.length}件, model=${AppConstants.anthropicModel}');

    // リトライ付きAPI呼び出し（最大2回）
    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        final response = await _callAiApi(requestBody)
            .timeout(const Duration(seconds: 60));

        debugPrint('[AI] レスポンス受信: status=${response.statusCode}');

        if (response.statusCode == 429) {
          throw const AiServiceException(
              AiErrorType.rateLimit, 'Rate limited');
        }

        if (response.statusCode != 200) {
          debugPrint('[AI] APIエラー: ${response.body}');
          throw AiServiceException(
              AiErrorType.network, 'API error: ${response.statusCode}');
        }

        final result = _parseResponse(response.body, tasks, executionTimingFactor);
        debugPrint('[AI] パース完了: ${result.tasks.length}件');
        return result;
      } on AiServiceException {
        rethrow;
      } on TimeoutException {
        debugPrint('[AI] タイムアウト (attempt $attempt)');
        if (attempt == 0) {
          await Future.delayed(const Duration(seconds: 3));
          continue;
        }
        throw const AiServiceException(AiErrorType.network, 'Timeout');
      } on SocketException catch (e) {
        debugPrint('[AI] ネットワークエラー: $e (attempt $attempt)');
        if (attempt == 0) {
          await Future.delayed(const Duration(seconds: 3));
          continue;
        }
        throw const AiServiceException(
            AiErrorType.network, 'Network error');
      } catch (e) {
        debugPrint('[AI] 予期しないエラー: $e (attempt $attempt)');
        if (attempt == 0) {
          await Future.delayed(const Duration(seconds: 3));
          continue;
        }
        debugPrint('[AI] フォールバック: 予期しないエラーのため');
        return _fallbackSort(tasks, executionTimingFactor: executionTimingFactor);
      }
    }

    debugPrint('[AI] フォールバック: リトライ上限到達');
    return _fallbackSort(tasks, executionTimingFactor: executionTimingFactor);
  }

  /// APIレスポンスをパースする
  static AiSortResponse _parseResponse(
      String responseBody, List<Task> tasks, [double executionTimingFactor = 0.5]) {
    try {
      final json = jsonDecode(responseBody) as Map<String, dynamic>;
      final content = json['content'] as List;
      final text = content[0]['text'] as String;

      var jsonStr = text.trim();
      if (jsonStr.contains('```')) {
        final match =
            RegExp(r'```(?:json)?\s*([\s\S]*?)```').firstMatch(jsonStr);
        if (match != null) {
          jsonStr = match.group(1)!.trim();
        }
      }

      final parsed = jsonDecode(jsonStr) as Map<String, dynamic>;
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final validTaskIds = tasks.map((t) => t.id).toSet();
      final taskDueDates = <int, DateTime>{};
      for (final t in tasks) {
        if (t.id != null) taskDueDates[t.id!] = t.dueDate;
      }

      if (kDebugMode) {
        debugPrint('[AI] レスポンスJSON: $jsonStr');
      }

      final taskNames = <int, String>{};
      for (final t in tasks) {
        if (t.id != null) taskNames[t.id!] = t.title;
      }

      final taskResults = (parsed['tasks'] as List).map((r) {
        final map = r as Map<String, dynamic>;

        // task_idの型安全なパース（AIがstringで返す場合への対応）
        final rawId = map['task_id'];
        final taskId = rawId is int ? rawId : int.tryParse('$rawId') ?? -1;

        // priorityの型安全なパース
        final rawPriority = map['priority'];
        final priority = rawPriority is int
            ? rawPriority.clamp(1, 4)
            : (int.tryParse('$rawPriority') ?? 2).clamp(1, 4);

        // 日付バリデーション
        final dueDate = taskDueDates[taskId];
        final rawRecommendedDate = map['recommended_date'] as String?;

        final dateResult = _validateDate(rawRecommendedDate, today, dueDate);
        final dateStr = dateResult?.$2;

        final notifyResult = _validateDate(
            map['notify_date'] as String?, today, dueDate);
        final notifyDate = notifyResult?.$2;

        final rawNotifyDates =
            (map['recommended_notify_dates'] as List?)?.cast<String>() ?? [];
        final validNotifyDates = rawNotifyDates
            .map((d) => _validateDate(d, today, dueDate)?.$2)
            .where((d) => d != null)
            .cast<String>()
            .toList();

        // 空コメントのフォールバック
        final commentJa = (map['comment_ja'] as String?)?.trim();
        final commentEn = (map['comment_en'] as String?)?.trim();

        // recommended_date == due_date の防止
        final fixedDateStr = _enforceRecommendedBeforeDue(
            dateStr, priority, today, dueDate, executionTimingFactor);

        if (kDebugMode) {
          debugPrint('[AI-DEBUG] タスク: ${taskNames[taskId] ?? taskId}');
          debugPrint('[AI-DEBUG]   due_date: ${taskDueDates[taskId]}');
          debugPrint('[AI-DEBUG]   AIが返したrecommended_date: $rawRecommendedDate');
          debugPrint('[AI-DEBUG]   パース後recommended_date: $dateStr');
          debugPrint('[AI-DEBUG]   enforce後recommended_date: $fixedDateStr');
        }

        return AiSortResult(
          taskId: taskId,
          priority: priority,
          commentJa: (commentJa != null && commentJa.isNotEmpty)
              ? commentJa
              : null,
          commentEn: (commentEn != null && commentEn.isNotEmpty)
              ? commentEn
              : null,
          recommendedNotifyDates: validNotifyDates,
          notifyDate: notifyDate,
          notifyReasonJa: map['notify_reason_ja'] as String?,
          notifyReasonEn: map['notify_reason_en'] as String?,
          recommendedDate: fixedDateStr,
          suggestedSubtasksJa:
              (map['suggested_subtasks_ja'] as List?)?.cast<String>() ?? [],
          suggestedSubtasksEn:
              (map['suggested_subtasks_en'] as List?)?.cast<String>() ?? [],
        );
      }).where((r) => validTaskIds.contains(r.taskId)).toList();

      return AiSortResponse(
        summaryJa: parsed['summary_ja'] as String?,
        summaryEn: parsed['summary_en'] as String?,
        tasks: taskResults,
        questionsJa:
            (parsed['questions_ja'] as List?)?.cast<String>() ?? [],
        questionsEn:
            (parsed['questions_en'] as List?)?.cast<String>() ?? [],
      );
    } catch (e) {
      debugPrint('AI response parse error: $e');
      return _fallbackSort(tasks);
    }
  }

  /// 日付文字列をバリデーションし、(正規化DateTime, フォーマット済み文字列)を返す。
  /// 無効な入力にはnullを返す。過去日はtodayに、dueDate超過はdueDateに補正。
  static (DateTime, String)? _validateDate(
      String? dateStr, DateTime today, DateTime? dueDate) {
    if (dateStr == null || dateStr.isEmpty) return null;
    final dt = DateTime.tryParse(dateStr);
    if (dt == null) return null;

    var validated = DateTime(dt.year, dt.month, dt.day);
    if (validated.isBefore(today)) {
      validated = today;
    }
    if (dueDate != null) {
      final dueDateNorm =
          DateTime(dueDate.year, dueDate.month, dueDate.day);
      if (validated.isAfter(dueDateNorm)) {
        validated = dueDateNorm;
      }
    }
    return (validated, app_date.formatDateForDb(validated));
  }

  /// recommended_dateがdue_dateと同じ場合、前倒しする（priority 1 & due==today除く）
  static String? _enforceRecommendedBeforeDue(
    String? recDateStr,
    int priority,
    DateTime today,
    DateTime? dueDate,
    double executionTimingFactor,
  ) {
    if (recDateStr == null || dueDate == null) return recDateStr;
    final recDt = DateTime.tryParse(recDateStr);
    if (recDt == null) return recDateStr;

    final recNorm = DateTime(recDt.year, recDt.month, recDt.day);
    final dueNorm = DateTime(dueDate.year, dueDate.month, dueDate.day);

    if (recNorm != dueNorm) return recDateStr;

    // priority 1 かつ due == today は例外
    if (priority == 1 && dueNorm == today) return recDateStr;

    final diff = dueNorm.difference(today).inDays;
    if (diff <= 0) return recDateStr;
    if (diff == 1) {
      // due is tomorrow: recommend starting today
      debugPrint('[AI] recommended_date補正(diff=1): $recDateStr → ${app_date.formatDateForDb(today)} (due=$dueNorm)');
      return app_date.formatDateForDb(today);
    }

    int baseDays;
    if (diff <= 3) {
      baseDays = 1;
    } else if (diff <= 7) {
      baseDays = 2;
    } else if (diff <= 14) {
      baseDays = 4;
    } else {
      baseDays = 7;
    }
    final adjusted = (baseDays * (0.3 + executionTimingFactor * 1.4)).round().clamp(1, diff - 1);
    var fixed = dueNorm.subtract(Duration(days: adjusted));
    if (fixed.isBefore(today)) fixed = today;
    debugPrint('[AI] recommended_date補正: $recDateStr → ${app_date.formatDateForDb(fixed)} (due=$dueNorm)');
    return app_date.formatDateForDb(fixed);
  }

  static Future<http.Response> _callAiApi(String requestBody) async {
    if (AppConstants.aiProxyUrl.isNotEmpty) {
      debugPrint('[PROXY-DEBUG] → プロキシ経由でリクエスト: ${AppConstants.aiProxyUrl}');
      return await http.post(
        Uri.parse(AppConstants.aiProxyUrl),
        headers: {
          'Content-Type': 'application/json',
          'X-App-Token': AppConstants.aiAppToken,
        },
        body: requestBody,
      );
    } else if (kDebugMode && AppConstants.anthropicApiKey.isNotEmpty) {
      debugPrint('[PROXY-DEBUG] → 直接APIキーでリクエスト');
      return await http.post(
        Uri.parse(AppConstants.anthropicApiUrl),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': AppConstants.anthropicApiKey,
          'anthropic-version': AppConstants.anthropicVersion,
        },
        body: requestBody,
      );
    } else {
      debugPrint('[PROXY-DEBUG] → 設定なし: AiServiceException送出');
      throw const AiServiceException(
        AiErrorType.network,
        'AI API configuration missing',
      );
    }
  }

  /// 期限日ベースのフォールバック
  static AiSortResponse _fallbackSort(
    List<Task> tasks, {
    double executionTimingFactor = 0.5,
  }) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final results = tasks.where((t) => t.id != null).map((t) {
      final due = DateTime(t.dueDate.year, t.dueDate.month, t.dueDate.day);
      final diff = due.difference(today).inDays;

      int priority;
      if (diff <= 0) {
        priority = 1;
      } else if (diff <= 3) {
        priority = 2;
      } else if (diff <= 7) {
        priority = 3;
      } else {
        priority = 4;
      }

      if (t.importance == 2 && priority > 1) priority--;
      if (t.importance == 0 && priority < 4) priority++;

      final notifyDates = <String>[];
      if (diff > 0) {
        final oneDayBefore = due.subtract(const Duration(days: 1));
        if (oneDayBefore.isAfter(today)) {
          notifyDates.add(app_date.formatDateForDb(oneDayBefore));
        }
      }
      if (diff >= 7) {
        final oneWeekBefore = due.subtract(const Duration(days: 7));
        if (oneWeekBefore.isAfter(today)) {
          notifyDates.add(app_date.formatDateForDb(oneWeekBefore));
        }
      }
      if (diff <= 0) {
        notifyDates.add(app_date.formatDateForDb(today));
      }

      // 期限までの日数に応じたベース前倒し日数
      int baseDays;
      if (diff <= 1) {
        baseDays = 0;
      } else if (diff <= 3) {
        baseDays = 1;
      } else if (diff <= 7) {
        baseDays = 3;
      } else if (diff <= 14) {
        baseDays = 5;
      } else {
        baseDays = 7;
      }
      final adjustedDays =
          (baseDays * (0.3 + executionTimingFactor * 1.4)).round();
      var recDate = due.subtract(Duration(days: adjustedDays));
      if (recDate.isBefore(today)) recDate = today;
      // due == rec かつ余裕がある場合は最低1日前倒し
      if (recDate == due && diff > 1) {
        recDate = due.subtract(const Duration(days: 1));
        if (recDate.isBefore(today)) recDate = today;
      }

      // フォールバック用コメント生成
      String commentJa;
      String commentEn;
      if (diff <= 0) {
        commentJa = '期限を過ぎています。最優先で取り組みましょう。';
        commentEn = 'Past due. Prioritize this task immediately.';
      } else if (diff == 1) {
        commentJa = '明日が期限です。今日中に完了させましょう。';
        commentEn = 'Due tomorrow. Complete it today.';
      } else if (diff <= 3) {
        commentJa = '期限まであと$diff日。早めに着手しましょう。';
        commentEn = '$diff days until due. Start soon.';
      } else if (diff <= 7) {
        commentJa = '今週中が期限です。計画的に進めましょう。';
        commentEn = 'Due this week. Plan accordingly.';
      } else {
        commentJa = '余裕があります。他の緊急タスクを先に片付けましょう。';
        commentEn = 'You have time. Focus on urgent tasks first.';
      }

      return AiSortResult(
        taskId: t.id!,
        priority: priority,
        commentJa: commentJa,
        commentEn: commentEn,
        recommendedNotifyDates: notifyDates,
        notifyDate: notifyDates.isNotEmpty ? notifyDates.first : null,
        notifyReasonJa: '期限日に基づく自動推奨',
        notifyReasonEn: 'Auto-suggested based on due date',
        recommendedDate: app_date.formatDateForDb(recDate),
      );
    }).toList();

    return AiSortResponse(
      summaryJa: '期限日に基づいて自動整理しました',
      summaryEn: 'Auto-sorted by due date',
      tasks: results,
      isFallback: true,
    );
  }
}
