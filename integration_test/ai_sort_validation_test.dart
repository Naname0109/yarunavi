import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:yarunavi/app.dart';
import 'package:yarunavi/models/task.dart';
import 'package:yarunavi/providers/settings_provider.dart';
import 'package:yarunavi/providers/task_provider.dart';
import 'package:yarunavi/services/ai_service.dart';
import 'package:yarunavi/services/database_service.dart';
import 'package:yarunavi/services/notification_service.dart';
import 'package:yarunavi/services/purchase_service.dart';
import 'package:yarunavi/services/calendar_service.dart';
import 'package:yarunavi/services/secure_storage_service.dart';
import 'package:yarunavi/providers/purchase_provider.dart';
import 'package:yarunavi/providers/secure_storage_provider.dart';
import 'package:yarunavi/providers/dev_mode_provider.dart';
import 'package:yarunavi/utils/constants.dart';
import 'package:yarunavi/utils/test_data.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late DatabaseService db;

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'is_onboarding_completed': true,
      'coachmarks_shown': true,
    });
    db = DatabaseService();
    await db.initialize();
  });

  tearDown(() async {
    await db.close();
  });

  group('AI整理の機能検証', () {
    testWidgets('テストデータ15件でAI整理を実行し結果を検証', (tester) async {
      // アプリ起動（API key取得のため）
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseServiceProvider.overrideWithValue(db),
            notificationServiceProvider
                .overrideWithValue(NotificationService()),
            calendarServiceProvider.overrideWithValue(CalendarService()),
            purchaseServiceProvider
                .overrideWithValue(PurchaseService.instance),
            secureStorageServiceProvider
                .overrideWithValue(SecureStorageService()),
            initialLocaleProvider.overrideWithValue(const Locale('ja')),
            initialThemeModeProvider.overrideWithValue(ThemeMode.light),
            initialDevAiUnlimitedProvider.overrideWithValue(false),
            initialDevPremiumProvider.overrideWithValue(false),
          ],
          child: const YaruNaviApp(),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // ─── Step 1: テストデータ投入 ───
      await db.deleteAllData();
      await insertAiTestData(db);
      final allTasks = await db.getAllTasks();
      final incompleteTasks =
          allTasks.where((t) => !t.isCompleted).toList();

      debugPrint('');
      debugPrint('═══════════════════════════════════════════');
      debugPrint('  AI整理 機能検証テスト');
      debugPrint('═══════════════════════════════════════════');
      debugPrint('');
      debugPrint('■ テストデータ: ${incompleteTasks.length}件');
      for (final t in incompleteTasks) {
        final now = DateTime.now();
        final diff = DateTime(t.dueDate.year, t.dueDate.month, t.dueDate.day)
            .difference(DateTime(now.year, now.month, now.day))
            .inDays;
        debugPrint(
            '  ${t.title} | 残$diff日 | imp=${t.importance} | cat=${t.categoryId}');
      }

      // ─── Step 2: APIキーチェック ───
      final hasApiKey = AppConstants.anthropicApiKey.isNotEmpty;
      debugPrint('');
      debugPrint('■ APIキー: ${hasApiKey ? "設定済み" : "未設定（フォールバック）"}');

      // ─── Step 3: カテゴリ名取得 ───
      final categories = await db.getAllCategories();
      final categoryNames = <int, String>{};
      for (final c in categories) {
        if (c.id != null) categoryNames[c.id!] = c.name;
      }

      // ─── Step 4: AI整理実行 ───
      debugPrint('');
      debugPrint('■ AI整理を実行中...');
      final response = await AiService.sortTasks(
        incompleteTasks,
        categoryNames: categoryNames,
      );

      debugPrint('');
      debugPrint('═══════════════════════════════════════════');
      debugPrint('  結果分析');
      debugPrint('═══════════════════════════════════════════');

      // ─── Step 5: フォールバック判定 ───
      debugPrint('');
      debugPrint('■ フォールバック: ${response.isFallback ? "YES（APIエラー）" : "NO（API成功）"}');

      // ─── Step 6: サマリー確認 ───
      debugPrint('');
      debugPrint('■ サマリー:');
      debugPrint('  ja: ${response.summaryJa ?? "(なし)"}');
      debugPrint('  en: ${response.summaryEn ?? "(なし)"}');

      // ─── Step 7: 各タスクの結果 ───
      debugPrint('');
      debugPrint('■ 各タスクの結果:');
      debugPrint('${'タスク名'.padRight(20)}| P | start      | end        | notify     | コメント');
      debugPrint('${'─' * 20}|---|${'─' * 12}|${'─' * 12}|${'─' * 12}|${'─' * 30}');

      final taskMap = <int, Task>{};
      for (final t in incompleteTasks) {
        if (t.id != null) taskMap[t.id!] = t;
      }

      // priority分布
      final priorityCounts = <int, int>{1: 0, 2: 0, 3: 0, 4: 0};

      for (final r in response.tasks) {
        final task = taskMap[r.taskId];
        final name = (task?.title ?? '?').padRight(18);
        priorityCounts[r.priority] = (priorityCounts[r.priority] ?? 0) + 1;

        debugPrint(
          '  $name| ${r.priority} | ${(r.recommendedStart ?? "-").padRight(10)} | '
          '${(r.recommendedEnd ?? "-").padRight(10)} | '
          '${(r.notifyDate ?? "-").padRight(10)} | '
          '${r.commentJa ?? "(なし)"}',
        );
      }

      // ─── Step 8: priority分布 ───
      debugPrint('');
      debugPrint('■ Priority分布:');
      for (final p in [1, 2, 3, 4]) {
        debugPrint('  P$p: ${priorityCounts[p] ?? 0}件');
      }

      // ─── Step 9: 自動バリデーション ───
      debugPrint('');
      debugPrint('═══════════════════════════════════════════');
      debugPrint('  自動バリデーション');
      debugPrint('═══════════════════════════════════════════');

      final issues = <String>[];
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      for (final r in response.tasks) {
        final task = taskMap[r.taskId];
        if (task == null) continue;
        final title = task.title;
        final dueDate =
            DateTime(task.dueDate.year, task.dueDate.month, task.dueDate.day);
        final daysLeft = dueDate.difference(today).inDays;

        // A. 優先度の妥当性
        if (daysLeft <= 0 && r.priority != 1) {
          issues.add('[$title] 今日期限だがP${r.priority}（P1であるべき）');
        }
        if (daysLeft == 1 && task.importance == 2 && r.priority > 2) {
          issues.add('[$title] 明日期限+重要度高だがP${r.priority}');
        }
        if (daysLeft >= 30 && r.priority <= 2) {
          issues.add('[$title] 残$daysLeft日だがP${r.priority}（P3-4であるべき）');
        }

        // B. コメント品質
        if (r.commentJa == null || r.commentJa!.isEmpty) {
          issues.add('[$title] AIコメントが空');
        } else {
          final c = r.commentJa!;
          if (c.contains('期限が近い') && !c.contains('ネット') && !c.contains('窓口')) {
            issues.add('[$title] コメントが汎用的: "$c"');
          }
          if (c == '重要なタスクです' || c == '早めに対応しましょう') {
            issues.add('[$title] 禁止コメント: "$c"');
          }
        }

        // C. 推奨実行期間
        if (r.recommendedStart != null) {
          final start = DateTime.tryParse(r.recommendedStart!);
          if (start != null && start.isBefore(today)) {
            issues.add('[$title] recommended_startが過去: ${r.recommendedStart}');
          }
        }
        if (r.recommendedEnd != null) {
          final end = DateTime.tryParse(r.recommendedEnd!);
          if (end != null && end.isAfter(dueDate)) {
            issues.add('[$title] recommended_endがdue_date超過: ${r.recommendedEnd}');
          }
        }
        if (r.recommendedStart != null && r.recommendedEnd != null) {
          final start = DateTime.tryParse(r.recommendedStart!);
          final end = DateTime.tryParse(r.recommendedEnd!);
          if (start != null && end != null && start.isAfter(end)) {
            issues.add('[$title] start > end: ${r.recommendedStart} > ${r.recommendedEnd}');
          }
        }

        // D. 通知日
        if (r.notifyDate != null) {
          final nd = DateTime.tryParse(r.notifyDate!);
          if (nd != null && nd.isBefore(today)) {
            issues.add('[$title] notify_dateが過去: ${r.notifyDate}');
          }
          if (nd != null && nd.isAfter(dueDate)) {
            issues.add('[$title] notify_dateがdue_date超過: ${r.notifyDate}');
          }
        }
        if (r.notifyReasonJa == null || r.notifyReasonJa!.isEmpty) {
          issues.add('[$title] notify_reasonが空');
        }
      }

      // priority分布チェック
      final p1Count = priorityCounts[1] ?? 0;
      final p4Count = priorityCounts[4] ?? 0;
      if (p1Count > 4) {
        issues.add('[分布] P1が$p1Count件で多すぎ（理想2-3件）');
      }
      if (p4Count == 0) {
        issues.add('[分布] P4が0件（最低2件あるべき）');
      }

      // 特定タスクのチェック
      for (final r in response.tasks) {
        final task = taskMap[r.taskId];
        if (task == null) continue;
        if (task.title == '週報提出' && r.priority != 1) {
          issues.add('[週報提出] 今日期限の定期タスクがP${r.priority}');
        }
        if (task.title == '家賃振込' && r.priority > 2) {
          issues.add('[家賃振込] 明日期限+重要度高がP${r.priority}');
        }
        if (task.title == 'パスポート更新' && r.priority < 3) {
          issues.add('[パスポート更新] 45日後がP${r.priority}');
        }
        if (task.title == '本を読む' && r.priority < 3) {
          issues.add('[本を読む] 21日後+低重要度がP${r.priority}');
        }
      }

      // 結果出力
      if (issues.isEmpty) {
        debugPrint('');
        debugPrint('  ✅ 全チェック通過! 問題なし');
      } else {
        debugPrint('');
        debugPrint('  ⚠️ ${issues.length}件の問題を検出:');
        for (final issue in issues) {
          debugPrint('    - $issue');
        }
      }

      // 質問の確認
      if (response.questionsJa.isNotEmpty) {
        debugPrint('');
        debugPrint('■ AIからの質問:');
        for (final q in response.questionsJa) {
          debugPrint('  - $q');
        }
      }

      debugPrint('');
      debugPrint('═══════════════════════════════════════════');
      debugPrint('  テスト完了');
      debugPrint('═══════════════════════════════════════════');

      // テスト判定: フォールバックでない場合のみ厳密チェック
      if (!response.isFallback) {
        expect(response.tasks.length, greaterThanOrEqualTo(10),
            reason: 'AI整理結果が10件未満');
        expect(response.summaryJa, isNotNull,
            reason: 'サマリーが空');

        // 致命的な問題がないこと
        final criticalIssues = issues
            .where((i) =>
                i.contains('過去') ||
                i.contains('超過') ||
                i.contains('start > end') ||
                i.contains('禁止コメント'))
            .toList();
        expect(criticalIssues, isEmpty,
            reason: '致命的な問題: $criticalIssues');
      }
    });
  });
}
