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

  const AiSortResult({
    required this.taskId,
    required this.priority,
    this.commentJa,
    this.commentEn,
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
  static const _systemPrompt = '''あなたはタスク管理の専門家です。ユーザーのタスクリストを受け取り、
以下のルールに従って優先順位を整理してください。

## 分類ルール
- priority 1（緊急）: 期限切れ、または今日が期限
- priority 2（要注意）: 期限まで1-3日
- priority 3（通常）: 期限まで4-7日
- priority 4（余裕）: 期限まで8日以上

## 考慮事項
- 手続き・届出系は「営業日」を考慮（土日を挟む場合は前倒し）
- 支払い系は「引き落とし日の前日まで」に完了を推奨
- 買い物系は他のタスクと同日にまとめる提案可
- 定期タスクは次回発生日で判断

## 出力形式
JSON配列で返してください。各要素:
{
  "task_id": <int>,
  "priority": <1-4>,
  "comment_ja": "<日本語の1行コメント>",
  "comment_en": "<英語の1行コメント>"
}''';

  /// タスクリストをAIで整理する
  static Future<List<AiSortResult>> sortTasks(List<Task> tasks) async {
    if (AppConstants.anthropicApiKey.isEmpty) {
      // APIキー未設定: フォールバック
      return _fallbackSort(tasks);
    }

    final now = DateTime.now();
    final todayStr = app_date.formatDateForDb(now);
    final weekdays = ['月', '火', '水', '木', '金', '土', '日'];
    final dayOfWeek = weekdays[now.weekday - 1];

    final tasksJson = tasks.map((t) => {
          'id': t.id,
          'title': t.title,
          'due_date': app_date.formatDateForDb(t.dueDate),
          'category_id': t.categoryId,
          'recurrence_type': t.recurrenceType,
        }).toList();

    final requestBody = jsonEncode({
      'model': AppConstants.anthropicModel,
      'max_tokens': 1024,
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
      // パースエラー等: フォールバック
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

      // JSON配列を抽出（```で囲まれている場合も対応）
      var jsonStr = text.trim();
      if (jsonStr.contains('```')) {
        final match = RegExp(r'```(?:json)?\s*([\s\S]*?)```').firstMatch(jsonStr);
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
        );
      }).toList();
    } catch (_) {
      // パースエラー: フォールバック
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

      return AiSortResult(taskId: t.id!, priority: priority);
    }).toList();
  }
}
