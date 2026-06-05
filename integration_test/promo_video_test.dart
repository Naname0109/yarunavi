import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:yarunavi/main.dart' as app;
import 'package:yarunavi/providers/task_provider.dart';
import 'package:yarunavi/utils/test_data.dart';

/// 15 秒の PR 動画用シナリオを Simulator 上で自動再生する。
/// `xcrun simctl io recordVideo` で並行録画する想定。
///
///   0:00-0:05 ホーム画面 (テストデータ 10 件) + 上下スクロール
///   0:05-0:07 AI 整理ボタンタップ
///   0:07-0:09 ローディング (Tips が見える)
///   0:09-0:13 結果画面 (priority 1-3 のカラーバッジ表示)
///   0:13-0:15 結果画面のスクロール + 静止
///
/// 注意: AI 整理は実 API (Cloudflare Worker proxy) を呼ぶため、
/// 実行時に `--dart-define=AI_PROXY_URL=... --dart-define=AI_APP_TOKEN=...`
/// が必要 (record_promo.sh が ios/fastlane/.env.local から渡す)。
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> waitVisible({
    required WidgetTester tester,
    required Finder finder,
    Duration timeout = const Duration(seconds: 8),
  }) async {
    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      if (finder.evaluate().isNotEmpty) return;
      await tester.pump(const Duration(milliseconds: 200));
    }
  }

  testWidgets('PR promo video scenario (15s)', (tester) async {
    // 例外で動画が止まらないように overflow / parent-data 系のみ抑制
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      final msg = details.exceptionAsString();
      if (msg.contains('ParentData') || msg.contains('overflowed')) return;
      originalOnError?.call(details);
    };

    // クリーン状態 (onboarding/コーチマーク済み + ダークモード)
    SharedPreferences.setMockInitialValues({
      'is_onboarding_completed': true,
      'coachmarks_shown': true,
      'app_theme_mode': 'dark',
    });

    // アプリ起動
    app.main();
    await Future.delayed(const Duration(seconds: 4));
    await tester.pumpAndSettle(const Duration(seconds: 4));

    // ProviderContainer 経由でテストデータを programmatic に投入
    final ctx = tester.element(find.byType(MaterialApp));
    final container = ProviderScope.containerOf(ctx);
    final db = container.read(databaseServiceProvider);
    await insertDetailedTestData(db);
    container.invalidate(tasksProvider);
    await tester.pumpAndSettle(const Duration(seconds: 2));
    debugPrint('[PROMO] test data inserted');

    // -------------------------------------------------------------------
    // 0:00-0:05 ホーム画面 + 上下スクロール
    // -------------------------------------------------------------------
    await Future.delayed(const Duration(seconds: 2));
    final scrollable = find.byType(Scrollable);
    if (scrollable.evaluate().isNotEmpty) {
      await tester.fling(scrollable.first, const Offset(0, -260), 700);
      await tester.pumpAndSettle();
      await Future.delayed(const Duration(milliseconds: 800));
      await tester.fling(scrollable.first, const Offset(0, 260), 700);
      await tester.pumpAndSettle();
      await Future.delayed(const Duration(milliseconds: 500));
    }

    // -------------------------------------------------------------------
    // 0:05-0:07 AI 整理ボタンタップ
    // -------------------------------------------------------------------
    // ARB: aiSortHeroCta = 'タスクをAIで整理'
    final aiBtn = find.text('タスクをAIで整理');
    await waitVisible(tester: tester, finder: aiBtn);
    if (aiBtn.evaluate().isNotEmpty) {
      await tester.ensureVisible(aiBtn.first);
      await tester.pumpAndSettle();
      await Future.delayed(const Duration(milliseconds: 600));
      await tester.tap(aiBtn.first);
      await tester.pump();
      debugPrint('[PROMO] AI sort tapped');
    } else {
      debugPrint('[PROMO] WARN: AI sort button not found');
    }

    // -------------------------------------------------------------------
    // 0:07-0:09 ローディング (Tips ちらりと表示)
    // -------------------------------------------------------------------
    // 最大 12 秒待機 (実 API の応答待ち)
    for (var i = 0; i < 24; i++) {
      await tester.pump(const Duration(milliseconds: 500));
      // 結果画面に遷移したかは AppBar の戻るボタンや AI コメントの有無で判定。
      // ここではシンプルに「タスクをAIで整理」ボタンが消えたかをトリガに。
      if (find.text('タスクをAIで整理').evaluate().isEmpty &&
          find.text('整理中…').evaluate().isEmpty) {
        debugPrint('[PROMO] result screen detected after ${i * 500}ms');
        break;
      }
    }
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // -------------------------------------------------------------------
    // 0:09-0:13 結果画面 (priority カラーバッジ)
    // -------------------------------------------------------------------
    await Future.delayed(const Duration(seconds: 4));

    // -------------------------------------------------------------------
    // 0:13-0:15 結果画面をスクロール (priority 2-3 を見せる) + 静止
    // -------------------------------------------------------------------
    final resultScroll = find.byType(Scrollable);
    if (resultScroll.evaluate().isNotEmpty) {
      await tester.fling(resultScroll.first, const Offset(0, -300), 600);
      await tester.pumpAndSettle();
    }
    await Future.delayed(const Duration(seconds: 2));

    debugPrint('[PROMO] scenario done');
  }, timeout: const Timeout(Duration(minutes: 2)));
}
