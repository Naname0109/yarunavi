import 'dart:async';
import 'dart:convert';
import 'dart:io';

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
  final List<String> suggestedSubtasksJa;
  final List<String> suggestedSubtasksEn;

  const AiSortResult({
    required this.taskId,
    required this.priority,
    this.commentJa,
    this.commentEn,
    this.recommendedNotifyDates = const [],
    this.suggestedSubtasksJa = const [],
    this.suggestedSubtasksEn = const [],
  });
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
      '''あなたはタスク管理の専門家であり、ユーザーの生活をサポートするパーソナルアシスタントです。
ユーザーのタスクリストを受け取り、以下のルールに従って優先順位の整理、実用的なアドバイス、通知日の提案を行ってください。

## 分類ルール
- priority 1（緊急）: 期限切れ、または今日が期限
- priority 2（要注意）: 期限まで1-3日
- priority 3（通常）: 期限まで4-7日
- priority 4（余裕）: 期限まで8日以上

## 重要度の考慮
- importance=2（高）のタスクはpriorityを1段階上げる（最高は1）
- importance=0（低）のタスクはpriorityを1段階下げる（最低は4）

## コメントのルール（最も重要）
comment_jaとcomment_enには、ユーザーにとって実用的で具体的なアドバイスを1-2文で書いてください。
以下のようなアドバイスを心がけてください:

- タスクの性質に応じた具体的な行動提案
  例: 「市役所は平日17時まで。明日の午前中に行くのがおすすめです」
  例: 「引き落とし日の前日です。残高を確認しておきましょう」
- 時間のかかるタスクには分割の提案
  例: 「半日かかるタスクです。今日書類を準備し、明日提出する2段階がおすすめ」
- 関連タスクのまとめ提案
  例: 「買い物系が3件あります。週末にまとめて回ると効率的です」
- 期限に余裕がある場合の着手タイミング提案
  例: 「期限まで2週間ありますが、写真撮影が先に必要です。来週前半に撮影を」
- メモの内容を活用した判断
  例: メモに「平日のみ」→「明後日は土曜なので、明日中に対応しましょう」
- 所要時間を考慮した提案
  例: 所要時間1日+期限3日後→「明日1日使って片付けると余裕が持てます」

単に「期限が近いです」のような機械的なコメントは避け、
ユーザーが「なるほど、そうしよう」と思えるような具体的なアドバイスにしてください。

## 通知日の決定ルール
recommended_notify_datesには、そのタスクについてユーザーに思い出してほしい日を設定してください。
- 緊急タスク（priority 1）: 当日のみ
- 手続き・届出系: 期限の3営業日前 + 前営業日（土日を避ける）
- 支払い系: 引き落とし日の3日前 + 前日
- 所要時間が「半日」「1日」: 着手推奨日（期限の2-3日前）+ 期限前日
- 重要度「高」: 通常より1段階早く通知（例: 1週間前にも追加）
- 通常タスク: 期限の1日前
- 余裕があるタスク: 期限の1週間前 + 3日前
- 過去の日付は含めないでください

## タスク分割の提案ルール
suggested_subtasksには、タスクを分割して進めた方がよい場合に具体的なサブタスク名を提案してください。
基本方針は「1日でやり切る」。分割はあくまで例外的な提案です。
- 所要時間が「1日」かつメモに複数ステップが読み取れる場合のみ分割を提案
- 所要時間が「半日」以下のタスクは原則分割しない
- 明らかに数日にわたる大型タスク（引越し、確定申告、大掃除等）は積極的に分割
- 分割不要な大多数のタスクは空配列[]
- サブタスクは2-4個程度、具体的なアクション名にする
- 分割タスクだらけにならないよう、全タスクの2割以下に抑える意識で

## 出力形式
JSON配列で返してください。各要素:
{
  "task_id": <int>,
  "priority": <1-4>,
  "comment_ja": "<日本語の実用的アドバイス>",
  "comment_en": "<英語の実用的アドバイス>",
  "recommended_notify_dates": ["yyyy-MM-dd", ...],
  "suggested_subtasks_ja": ["<サブタスク1>", ...],
  "suggested_subtasks_en": ["<subtask 1>", ...]
}''';

  /// タスクリストをAIで整理する
  /// [categories] はカテゴリID→名前のマップ（コンテキスト情報としてAIに渡す）
  static Future<List<AiSortResult>> sortTasks(
    List<Task> tasks, {
    Map<int, String> categoryNames = const {},
  }) async {
    if (AppConstants.anthropicApiKey.isEmpty) {
      return _fallbackSort(tasks);
    }

    final now = DateTime.now();
    final todayStr = app_date.formatDateForDb(now);
    final weekdays = ['月', '火', '水', '木', '金', '土', '日'];
    final dayOfWeek = weekdays[now.weekday - 1];

    final tasksJson = tasks.map((t) {
      return {
        'id': t.id,
        'title': t.title,
        'due_date': app_date.formatDateForDb(t.dueDate),
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

    final requestBody = jsonEncode({
      'model': AppConstants.anthropicModel,
      'max_tokens': 4096,
      'system': [
        {
          'type': 'text',
          'text': _systemPrompt,
          'cache_control': {'type': 'ephemeral'},
        }
      ],
      'messages': [
        {
          'role': 'user',
          'content':
              '今日の日付: $todayStr\n曜日: $dayOfWeek\n\nタスクリスト:\n${jsonEncode(tasksJson)}',
        }
      ],
    });

    try {
      final response = await http
          .post(
            Uri.parse(AppConstants.anthropicApiUrl),
            headers: {
              'Content-Type': 'application/json',
              'x-api-key': AppConstants.anthropicApiKey,
              'anthropic-version': AppConstants.anthropicVersion,
            },
            body: requestBody,
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 429) {
        throw const AiServiceException(
          AiErrorType.rateLimit,
          'Rate limited',
        );
      }

      if (response.statusCode != 200) {
        throw AiServiceException(
          AiErrorType.network,
          'API error: ${response.statusCode}',
        );
      }

      return _parseResponse(response.body, tasks);
    } on AiServiceException {
      rethrow;
    } on TimeoutException {
      throw const AiServiceException(AiErrorType.network, 'Timeout');
    } on SocketException {
      throw const AiServiceException(AiErrorType.network, 'Network error');
    } catch (_) {
      return _fallbackSort(tasks);
    }
  }

  /// APIレスポンスをパースする
  static List<AiSortResult> _parseResponse(
      String responseBody, List<Task> tasks) {
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

      final results = jsonDecode(jsonStr) as List;
      return results.map((r) {
        final map = r as Map<String, dynamic>;
        return AiSortResult(
          taskId: map['task_id'] as int,
          priority: (map['priority'] as int).clamp(1, 4),
          commentJa: map['comment_ja'] as String?,
          commentEn: map['comment_en'] as String?,
          recommendedNotifyDates: (map['recommended_notify_dates'] as List?)
                  ?.cast<String>() ??
              [],
          suggestedSubtasksJa: (map['suggested_subtasks_ja'] as List?)
                  ?.cast<String>() ??
              [],
          suggestedSubtasksEn: (map['suggested_subtasks_en'] as List?)
                  ?.cast<String>() ??
              [],
        );
      }).toList();
    } catch (_) {
      return _fallbackSort(tasks);
    }
  }

  /// 期限日ベースのフォールバック優先度計算
  static List<AiSortResult> _fallbackSort(List<Task> tasks) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return tasks.map((t) {
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

      // 重要度による調整
      if (t.importance == 2 && priority > 1) priority--;
      if (t.importance == 0 && priority < 4) priority++;

      // フォールバック通知日
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

      return AiSortResult(
        taskId: t.id!,
        priority: priority,
        recommendedNotifyDates: notifyDates,
      );
    }).toList();
  }
}
