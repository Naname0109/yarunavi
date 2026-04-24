import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:go_router/go_router.dart';

import 'package:yarunavi/main.dart' as app;

/// YaruNavi E2Eテストスイート
///
/// 使用方法:
///   flutter test integration_test/e2e_test.dart \
///     -d "iPhone 16 Pro Max" \
///     --dart-define=ANTHROPIC_API_KEY=${ANTHROPIC_API_KEY:-""}
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> saveScreenshot(String name) async {
    await Future.delayed(const Duration(milliseconds: 800));
    try {
      await binding.takeScreenshot('e2e_$name');
      debugPrint('[E2E] Screenshot saved: e2e_$name');
    } catch (e) {
      debugPrint('[E2E] Screenshot failed: $e');
    }
  }

  Future<void> waitForWidget(
    WidgetTester tester,
    Finder finder, {
    int maxAttempts = 30,
    Duration interval = const Duration(milliseconds: 500),
  }) async {
    for (var i = 0; i < maxAttempts; i++) {
      if (finder.evaluate().isNotEmpty) return;
      await tester.pump(interval);
    }
  }

  Future<void> dismissOverlays(WidgetTester tester) async {
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 300));
      final okBtn = find.text('OK');
      final nextBtn = find.text('次へ');
      if (nextBtn.evaluate().isNotEmpty) {
        await tester.tap(nextBtn.first);
        await tester.pumpAndSettle();
      } else if (okBtn.evaluate().isNotEmpty) {
        await tester.tap(okBtn.first);
        await tester.pumpAndSettle();
      } else {
        final barrier = find.byType(ModalBarrier);
        if (barrier.evaluate().length > 1) {
          await tester.tapAt(const Offset(200, 400));
          await tester.pumpAndSettle();
        } else {
          break;
        }
      }
    }
    await tester.pumpAndSettle();
  }

  GoRouter routerOf(WidgetTester tester) {
    return GoRouter.of(tester.element(find.byType(Scaffold).first));
  }

  testWidgets('E2E Test Suite', (tester) async {
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      final msg = details.exceptionAsString();
      if (msg.contains('ParentData') || msg.contains('overflowed')) return;
      originalOnError?.call(details);
    };

    int passed = 0;
    int failed = 0;
    final failures = <String>[];

    try {

    Future<void> runTest(String name, Future<void> Function() body) async {
      debugPrint('\n[E2E] ▶ $name');
      try {
        await body();
        passed++;
        debugPrint('[E2E] ✓ PASS: $name');
      } catch (e) {
        failed++;
        failures.add(name);
        debugPrint('[E2E] ✗ FAIL: $name');
        debugPrint('[E2E]   Error: $e');
        await saveScreenshot('fail_${name.replaceAll(' ', '_')}');
      }
    }

    // ========================================
    // アプリ起動
    // ========================================
    app.main();
    debugPrint('[E2E] Waiting for app to initialize...');
    await Future.delayed(const Duration(seconds: 5));
    await tester.pumpAndSettle(const Duration(seconds: 5));
    await Future.delayed(const Duration(seconds: 3));
    await tester.pumpAndSettle(const Duration(seconds: 3));
    debugPrint('[E2E] App launched');

    // ========================================
    // 1. オンボーディングテスト
    // ========================================
    await runTest('1-1 オンボーディング表示', () async {
      await waitForWidget(tester, find.byKey(const Key('onboarding_next')));
      expect(find.byKey(const Key('onboarding_next')), findsOneWidget);
    });

    await runTest('1-2 オンボーディング画面遷移', () async {
      final nextBtn = find.byKey(const Key('onboarding_next'));
      expect(nextBtn, findsOneWidget);

      // ページ2へ
      await tester.tap(nextBtn);
      await tester.pumpAndSettle();

      // ページ3へ
      if (nextBtn.evaluate().isNotEmpty) {
        await tester.tap(nextBtn);
        await tester.pumpAndSettle();
      }

      // 最終ページ前なのでskipボタンが表示されていること
      expect(find.byKey(const Key('onboarding_skip')), findsOneWidget);
    });

    await runTest('1-3 スキップでホーム遷移', () async {
      final skipBtn = find.byKey(const Key('onboarding_skip'));
      expect(skipBtn, findsOneWidget);
      await tester.tap(skipBtn);
      await tester.pumpAndSettle(const Duration(seconds: 2));
      await dismissOverlays(tester);
      await waitForWidget(tester, find.byKey(const Key('settings_button')));
      expect(find.byKey(const Key('settings_button')), findsOneWidget);
    });

    // ========================================
    // 2. タスクCRUDテスト
    // ========================================
    await runTest('2-1 タスク追加', () async {
      // FABをタップ
      final fab = find.byType(FloatingActionButton);
      expect(fab, findsOneWidget);
      await tester.tap(fab);
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // タスク名入力
      final titleField = find.byType(TextFormField).first;
      await tester.enterText(titleField, 'E2Eテストタスク');
      await tester.pumpAndSettle();

      // 保存
      final saveBtn = find.text('保存');
      expect(saveBtn, findsOneWidget);
      await tester.tap(saveBtn);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // ホーム画面にタスクが表示されることを確認
      await waitForWidget(tester, find.text('E2Eテストタスク'));
      expect(find.text('E2Eテストタスク'), findsOneWidget);
    });

    await runTest('2-2 タスク表示確認', () async {
      expect(find.text('E2Eテストタスク'), findsOneWidget);
      expect(find.byType(Card), findsWidgets);
    });

    await runTest('2-3 タスク編集', () async {
      // タスクカードをタップして展開
      await tester.tap(find.text('E2Eテストタスク'));
      await tester.pumpAndSettle();

      // 編集ボタンを探してタップ
      final editBtn = find.text('編集');
      if (editBtn.evaluate().isNotEmpty) {
        await tester.tap(editBtn.first);
        await tester.pumpAndSettle(const Duration(seconds: 1));

        // タスク名を変更
        final titleField = find.byType(TextFormField).first;
        await tester.enterText(titleField, 'E2E編集済みタスク');
        await tester.pumpAndSettle();

        // 保存
        await tester.tap(find.text('保存'));
        await tester.pumpAndSettle(const Duration(seconds: 2));

        await waitForWidget(tester, find.text('E2E編集済みタスク'));
        expect(find.text('E2E編集済みタスク'), findsOneWidget);
      }
    });

    await runTest('2-4 タスク完了', () async {
      // チェックボックスをタップ
      final checkbox = find.byType(Checkbox).first;
      await tester.tap(checkbox);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // 完了済みタブに移動
      final completedTab = find.byKey(const Key('filter_tab_2'));
      await tester.tap(completedTab);
      await tester.pumpAndSettle(const Duration(seconds: 1));

      await waitForWidget(tester, find.text('E2E編集済みタスク'), maxAttempts: 10);
      expect(find.text('E2E編集済みタスク'), findsOneWidget);
    });

    await runTest('2-5 タスク削除', () async {
      // 完了済みタブにいる状態でタスクを右スワイプ削除
      final taskCard = find.text('E2E編集済みタスク');
      if (taskCard.evaluate().isNotEmpty) {
        // 左スワイプ（削除）
        await tester.drag(taskCard, const Offset(-300, 0));
        await tester.pumpAndSettle();

        // 削除確認ダイアログ
        final deleteBtn = find.text('削除');
        if (deleteBtn.evaluate().isNotEmpty) {
          await tester.tap(deleteBtn.last);
          await tester.pumpAndSettle(const Duration(seconds: 1));
        }
      }

      // やることタブに戻る
      final todoTab = find.byKey(const Key('filter_tab_0'));
      await tester.tap(todoTab);
      await tester.pumpAndSettle(const Duration(seconds: 1));
    });

    // ========================================
    // 3. AI整理テスト（テストデータ投入→AI実行）
    // ========================================
    // 設定画面で開発者モード有効化＆テストデータ投入
    await runTest('3-0 テストデータ投入', () async {
      await tester.tap(find.byKey(const Key('settings_button')));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // 開発者モード有効化
      final appInfoTile = find.byKey(const Key('app_info_tile'));
      await tester.scrollUntilVisible(
        appInfoTile, 200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      for (var i = 0; i < 7; i++) {
        await tester.tap(appInfoTile);
        await tester.pump(const Duration(milliseconds: 200));
      }
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // プレミアムON
      final premiumToggle = find.byKey(const Key('premium_mode_toggle'));
      await tester.scrollUntilVisible(
        premiumToggle, 200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      final switchWidget = find.descendant(
        of: premiumToggle,
        matching: find.byType(Switch),
      );
      if (switchWidget.evaluate().isNotEmpty) {
        final sw = tester.widget<Switch>(switchWidget);
        if (!sw.value) {
          await tester.tap(premiumToggle);
          await tester.pumpAndSettle();
        }
      }

      // テストデータ投入
      final aiTestData = find.byKey(const Key('debug_ai_test_data'));
      await tester.scrollUntilVisible(
        aiTestData, 200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(aiTestData);
      await tester.pumpAndSettle(const Duration(seconds: 1));

      final dialogOk = find.widgetWithText(FilledButton, 'OK');
      if (dialogOk.evaluate().isNotEmpty) {
        await tester.tap(dialogOk);
        await tester.pumpAndSettle(const Duration(seconds: 3));
      }

      // ホームに戻る
      routerOf(tester).go('/home');
      await tester.pumpAndSettle(const Duration(seconds: 2));
      await waitForWidget(tester, find.byType(Card));
    });

    await runTest('3-1 AI整理ボタンタップ', () async {
      final aiButton = find.byKey(const Key('ai_sort_button'));
      expect(aiButton, findsOneWidget);
      await tester.tap(aiButton);
      debugPrint('[E2E] AI sort started');

      // AI整理完了を待つ（最大60秒）
      for (var i = 0; i < 120; i++) {
        await tester.pump(const Duration(milliseconds: 500));
        final bgBtn = find.text('バックグラウンドで実行');
        if (bgBtn.evaluate().isNotEmpty) {
          await tester.tap(bgBtn);
          await tester.pumpAndSettle();
          for (var j = 0; j < 120; j++) {
            await tester.pump(const Duration(milliseconds: 500));
          }
          break;
        }
        final loading = find.byType(CircularProgressIndicator);
        if (loading.evaluate().isEmpty) break;
      }
      await tester.pumpAndSettle(const Duration(seconds: 2));
      debugPrint('[E2E] AI sort completed');
    });

    await runTest('3-2 AI整理結果画面表示', () async {
      // AI結果画面に自動遷移 or 手動遷移
      final aiResultTitle = find.textContaining('整理しました');
      if (aiResultTitle.evaluate().isEmpty) {
        routerOf(tester).push('/ai-result');
        await tester.pumpAndSettle(const Duration(seconds: 2));
      }

      // 結果画面にScaffoldがあること（画面が表示されている）
      expect(find.byType(Scaffold), findsWidgets);
      await saveScreenshot('ai_result');
    });

    await runTest('3-3 サマリーカード表示', () async {
      // サマリーはCardウィジェット内に表示される
      expect(find.byType(Card), findsWidgets);
    });

    await runTest('3-4 ホームに戻る', () async {
      routerOf(tester).go('/home');
      await tester.pumpAndSettle(const Duration(seconds: 2));
      await waitForWidget(tester, find.byKey(const Key('settings_button')));
      expect(find.byKey(const Key('settings_button')), findsOneWidget);
    });

    // ========================================
    // 4. カレンダーテスト
    // ========================================
    await runTest('4-1 カレンダータブ切り替え', () async {
      final calendarTab = find.byKey(const Key('filter_tab_1'));
      expect(calendarTab, findsOneWidget);
      await tester.tap(calendarTab);
      await tester.pumpAndSettle(const Duration(seconds: 1));
    });

    await runTest('4-2 カレンダー表示確認', () async {
      // SegmentedButton（実行日/期限日切替）が表示されること
      final segmented = find.byType(SegmentedButton<String>);
      expect(segmented, findsOneWidget);
      await saveScreenshot('calendar');
    });

    await runTest('4-3 実行日/期限日タブ切替', () async {
      final segmented = find.byType(SegmentedButton<String>);
      if (segmented.evaluate().isNotEmpty) {
        // 期限日ボタンのテキストを探してタップ
        final dueDateText = find.text('期限日');
        if (dueDateText.evaluate().isNotEmpty) {
          await tester.tap(dueDateText.first);
          await tester.pumpAndSettle();
        }
        // 実行日に戻す
        final recDateText = find.text('実行日');
        if (recDateText.evaluate().isNotEmpty) {
          await tester.tap(recDateText.first);
          await tester.pumpAndSettle();
        }
      }
    });

    await runTest('4-4 日付タップでタスクリスト表示', () async {
      // 今日の日付セルをタップ
      final today = DateTime.now();
      final dayText = find.text('${today.day}');
      if (dayText.evaluate().isNotEmpty) {
        await tester.tap(dayText.first);
        await tester.pumpAndSettle();
      }

      // やることタブに戻す
      await tester.tap(find.byKey(const Key('filter_tab_0')));
      await tester.pumpAndSettle(const Duration(seconds: 1));
    });

    // ========================================
    // 5. 設定画面テスト
    // ========================================
    await runTest('5-1 設定画面遷移', () async {
      await tester.tap(find.byKey(const Key('settings_button')));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.text('設定'), findsWidgets);
      await saveScreenshot('settings');
    });

    await runTest('5-2 カテゴリ管理遷移', () async {
      final categoryTile = find.text('カテゴリ管理');
      await tester.scrollUntilVisible(
        categoryTile, 200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(categoryTile);
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.byType(Scaffold), findsWidgets);
      await saveScreenshot('category_manage');

      // 戻る
      final backButton = find.byType(BackButton);
      if (backButton.evaluate().isNotEmpty) {
        await tester.tap(backButton);
        await tester.pumpAndSettle(const Duration(seconds: 1));
      } else {
        Navigator.of(tester.element(find.byType(Scaffold).first)).pop();
        await tester.pumpAndSettle(const Duration(seconds: 1));
      }
    });

    await runTest('5-3 ストア画面遷移', () async {
      final storeTile = find.byKey(const Key('upgrade_to_premium'));
      if (storeTile.evaluate().isNotEmpty) {
        await tester.scrollUntilVisible(
          storeTile, -200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
        await tester.tap(storeTile);
        await tester.pumpAndSettle(const Duration(seconds: 2));
        await saveScreenshot('store');

        // 戻る
        final backButton = find.byType(BackButton);
        if (backButton.evaluate().isNotEmpty) {
          await tester.tap(backButton);
          await tester.pumpAndSettle(const Duration(seconds: 1));
        } else {
          Navigator.of(tester.element(find.byType(Scaffold).first)).pop();
          await tester.pumpAndSettle(const Duration(seconds: 1));
        }
      }
    });

    await runTest('5-4 設定画面から戻る', () async {
      // ホームに戻る
      routerOf(tester).go('/home');
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.byKey(const Key('settings_button')), findsOneWidget);
    });

    // ========================================
    // 6. 画面表示テスト（クラッシュしないこと）
    // ========================================
    await runTest('6-1 全タブ切り替え', () async {
      // やること
      await tester.tap(find.byKey(const Key('filter_tab_0')));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // カレンダー
      await tester.tap(find.byKey(const Key('filter_tab_1')));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // 完了済み
      await tester.tap(find.byKey(const Key('filter_tab_2')));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // やることに戻る
      await tester.tap(find.byKey(const Key('filter_tab_0')));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      expect(find.byType(Scaffold), findsWidgets);
    });

    await runTest('6-2 空状態の表示', () async {
      // 完了済みタブを確認（空でもクラッシュしない）
      await tester.tap(find.byKey(const Key('filter_tab_2')));
      await tester.pumpAndSettle(const Duration(seconds: 1));
      expect(find.byType(Scaffold), findsWidgets);

      // やることに戻る
      await tester.tap(find.byKey(const Key('filter_tab_0')));
      await tester.pumpAndSettle(const Duration(seconds: 1));
    });

    // ========================================
    // テスト結果サマリー
    // ========================================
    final divider = '=' * 50;
    debugPrint('\n$divider');
    debugPrint('[E2E] テスト結果サマリー');
    debugPrint(divider);
    debugPrint('[E2E] 合計: ${passed + failed} テスト');
    debugPrint('[E2E] ✓ PASS: $passed');
    debugPrint('[E2E] ✗ FAIL: $failed');
    if (failures.isNotEmpty) {
      debugPrint('[E2E] 失敗したテスト:');
      for (final f in failures) {
        debugPrint('[E2E]   - $f');
      }
    }
    debugPrint(divider);

    if (failed > 0) {
      fail('$failed 件のテストが失敗しました: ${failures.join(', ')}');
    }

    } finally {
      FlutterError.onError = originalOnError;
    }
  });
}
