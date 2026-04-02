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

  Map<String, dynamic> toJson() => {
        'task_id': taskId,
        'priority': priority,
        'comment_ja': commentJa,
        'comment_en': commentEn,
        'recommended_notify_dates': recommendedNotifyDates,
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

  const AiSortResponse({
    this.summaryJa,
    this.summaryEn,
    required this.tasks,
    this.questionsJa = const [],
    this.questionsEn = const [],
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
      '''あなたはタスク管理の専門家であり、ユーザーの生活をサポートするパーソナルアシスタントです。
ユーザーのタスクリストを受け取り、優先順位の整理、実用的なアドバイス、通知日の提案を行ってください。

## 分類ルール
- priority 1（今日これだけやろう）: 今日最優先で着手すべき1-3件に限定
  - 期限切れ・今日期限でも、重要度「低」や所要時間「5分」はpriority 2に
  - 1日にpriority 1は最大3件まで
  - 所要時間の合計が8時間を超えないよう配慮
- priority 2（今週のうちに片付けよう）: 期限まで1-7日
- priority 3（来週以降でOK）: 期限まで8日以上
- priority 4（忘れずにキープ）: 余裕がある、または定期タスクの将来分

## 重要度の考慮
- importance=2（高）: priorityを1段階上げる（最高は1）
- importance=0（低）: priorityを1段階下げる（最低は4）

## 1日のタスク配分ルール
- 5分タスク5件+1時間タスク1件=十分こなせる
- 半日タスク2件=1件は明日に回す提案をする
- コメントで「午前にA、午後にB」のように時間帯を提案

## コメントのルール（最も重要）
comment_ja/comment_enには、実用的で具体的なアドバイスを1-2文で書いてください。
- 行動提案: 「市役所は平日17時まで。明日の午前中に行くのがおすすめ」
- 分割提案: 「半日かかります。今日書類準備、明日提出の2段階で」
- まとめ提案: 「買い物系が3件。週末にまとめて回ると効率的」
- 着手提案: 「写真撮影が先に必要。来週前半に撮影を」
- メモ活用: メモに「平日のみ」→「明後日は土曜。明日中に対応を」
- 時間考慮: 所要時間1日+期限3日後→「明日1日使って片付けましょう」
- キャパ超え時: 「今日は他の優先タスクがあるので、明日に回しても大丈夫です」
機械的な「期限が近いです」は避けてください。

## 通知日の決定ルール
recommended_notify_datesにユーザーに思い出してほしい日を設定:
- 緊急(priority 1): 当日のみ
- 手続き・届出系: 期限の3営業日前+前営業日
- 支払い系: 引き落とし3日前+前日
- 半日/1日タスク: 着手推奨日(期限2-3日前)+期限前日
- 重要度「高」: 1週間前にも追加
- 通常: 期限1日前
- 余裕あり: 1週間前+3日前
- 過去の日付は含めない

## タスク分割の提案ルール
- 所要時間「1日」かつメモに複数ステップがある場合のみ
- 半日以下は原則分割しない
- 大型タスク(引越し等)は積極的に分割
- 分割不要なタスクは空配列[]
- 全タスクの2割以下に抑える

## 質問ルール
タスクの情報が不十分で適切な判断ができない場合、questionsに質問を入れてください。
- 最大3件まで
- 場所、予算、方法など具体的な判断に必要な情報を聞く
- 質問不要なら空配列[]

## 全体サマリルール
summary_ja/summary_enに、今日のプランを1-2文でまとめてください。
例: 「今日は3件に集中。電気代の振込と歯医者の電話を午前中に、午後は書類準備に取りかかりましょう。」

## 出力形式
JSONオブジェクトで返してください:
{
  "summary_ja": "<日本語の全体サマリ>",
  "summary_en": "<英語の全体サマリ>",
  "tasks": [
    {
      "task_id": <int>,
      "priority": <1-4>,
      "comment_ja": "<日本語アドバイス>",
      "comment_en": "<英語アドバイス>",
      "recommended_notify_dates": ["yyyy-MM-dd", ...],
      "suggested_subtasks_ja": [...],
      "suggested_subtasks_en": [...]
    }
  ],
  "questions_ja": ["<質問1>", ...],
  "questions_en": ["<question 1>", ...]
}''';

  /// タスクリストをAIで整理する
  static Future<AiSortResponse> sortTasks(
    List<Task> tasks, {
    Map<int, String> categoryNames = const {},
    String? additionalContext,
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

    var userPrompt =
        '今日の日付: $todayStr\n曜日: $dayOfWeek\n\nタスクリスト:\n${jsonEncode(tasksJson)}';
    if (additionalContext != null) {
      userPrompt += '\n\n追加情報:\n$additionalContext';
    }

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
        {'role': 'user', 'content': userPrompt}
      ],
    });

    // リトライ付きAPI呼び出し（最大2回）
    for (var attempt = 0; attempt < 2; attempt++) {
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
            .timeout(const Duration(seconds: 60));

        if (response.statusCode == 429) {
          throw const AiServiceException(
              AiErrorType.rateLimit, 'Rate limited');
        }

        if (response.statusCode != 200) {
          throw AiServiceException(
              AiErrorType.network, 'API error: ${response.statusCode}');
        }

        return _parseResponse(response.body, tasks);
      } on AiServiceException {
        rethrow;
      } on TimeoutException {
        if (attempt == 0) {
          await Future.delayed(const Duration(seconds: 3));
          continue;
        }
        throw const AiServiceException(AiErrorType.network, 'Timeout');
      } on SocketException {
        if (attempt == 0) {
          await Future.delayed(const Duration(seconds: 3));
          continue;
        }
        throw const AiServiceException(
            AiErrorType.network, 'Network error');
      } catch (e) {
        debugPrint('AI service error: $e');
        if (attempt == 0) {
          await Future.delayed(const Duration(seconds: 3));
          continue;
        }
        return _fallbackSort(tasks);
      }
    }

    return _fallbackSort(tasks);
  }

  /// APIレスポンスをパースする
  static AiSortResponse _parseResponse(
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

      final parsed = jsonDecode(jsonStr) as Map<String, dynamic>;

      final taskResults = (parsed['tasks'] as List).map((r) {
        final map = r as Map<String, dynamic>;
        return AiSortResult(
          taskId: map['task_id'] as int,
          priority: (map['priority'] as int).clamp(1, 4),
          commentJa: map['comment_ja'] as String?,
          commentEn: map['comment_en'] as String?,
          recommendedNotifyDates:
              (map['recommended_notify_dates'] as List?)?.cast<String>() ??
                  [],
          suggestedSubtasksJa:
              (map['suggested_subtasks_ja'] as List?)?.cast<String>() ?? [],
          suggestedSubtasksEn:
              (map['suggested_subtasks_en'] as List?)?.cast<String>() ?? [],
        );
      }).toList();

      return AiSortResponse(
        summaryJa: parsed['summary_ja'] as String?,
        summaryEn: parsed['summary_en'] as String?,
        tasks: taskResults,
        questionsJa:
            (parsed['questions_ja'] as List?)?.cast<String>() ?? [],
        questionsEn:
            (parsed['questions_en'] as List?)?.cast<String>() ?? [],
      );
    } catch (_) {
      return _fallbackSort(tasks);
    }
  }

  /// 期限日ベースのフォールバック
  static AiSortResponse _fallbackSort(List<Task> tasks) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    var p1Count = 0;

    final results = tasks.where((t) => t.id != null).map((t) {
      final due = DateTime(t.dueDate.year, t.dueDate.month, t.dueDate.day);
      final diff = due.difference(today).inDays;

      int priority;
      if (diff <= 0) {
        priority = p1Count < 3 ? 1 : 2;
        if (priority == 1) p1Count++;
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

      return AiSortResult(
        taskId: t.id!,
        priority: priority,
        recommendedNotifyDates: notifyDates,
      );
    }).toList();

    return AiSortResponse(
      summaryJa: '期限日に基づいて自動整理しました',
      summaryEn: 'Auto-sorted by due date',
      tasks: results,
    );
  }
}
