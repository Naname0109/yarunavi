import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:go_router/go_router.dart';

import 'package:yarunavi/main.dart' as app;

/// App Store スクリーンショット全自動撮影テスト
///
/// 使用方法:
///   flutter drive \
///     --driver=test_driver/screenshot_driver.dart \
///     --target=integration_test/screenshot_test.dart \
///     -d "iPhone 17 Pro Max"
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  /// スクショ撮影ヘルパー: simctl用にGPUレンダリング完了を待つ
  Future<void> takeScreenshot(String name) async {
    // GPU描画がシミュレータ表示に反映されるのを待つ
    await Future.delayed(const Duration(milliseconds: 800));
    await binding.takeScreenshot(name);
  }

  testWidgets('App Store screenshots - fully automated', (tester) async {
    // レイアウト警告を抑制
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      final msg = details.exceptionAsString();
      if (msg.contains('ParentData') || msg.contains('overflowed')) return;
      originalOnError?.call(details);
    };

    // --- アプリ起動 ---
    app.main();
    debugPrint('[SS] Waiting for app to initialize...');
    await Future.delayed(const Duration(seconds: 5));
    await tester.pumpAndSettle(const Duration(seconds: 5));
    debugPrint('[SS] Post-init settle done');

    // スプラッシュ → オンボーディング/ホーム遷移を待つ
    await Future.delayed(const Duration(seconds: 3));
    await tester.pumpAndSettle(const Duration(seconds: 3));
    debugPrint('[SS] App launched');

    // =============================================
    // 1. オンボーディング → スクショ → スキップ
    // =============================================
    for (var i = 0; i < 20; i++) {
      if (find.byKey(const Key('onboarding_next')).evaluate().isNotEmpty) break;
      if (find.byKey(const Key('settings_button')).evaluate().isNotEmpty) break;
      await tester.pump(const Duration(milliseconds: 500));
    }

    final nextBtn = find.byKey(const Key('onboarding_next'));
    if (nextBtn.evaluate().isNotEmpty) {
      await tester.tap(nextBtn);
      await tester.pumpAndSettle();
      debugPrint('[SS] Onboarding page 2');

      await takeScreenshot('raw_05_onboarding');
      debugPrint('[SS] ✓ raw_05_onboarding');

      // スキップしてホームへ
      await tester.tap(find.byKey(const Key('onboarding_skip')));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      debugPrint('[SS] Onboarding skipped → Home');
    }

    // コーチマークが表示されたら閉じる（showGeneralDialogで表示）
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 300));
      final coachNext = find.text('次へ');
      final coachDone = find.text('OK');
      if (coachNext.evaluate().isNotEmpty) {
        await tester.tap(coachNext.first);
        await tester.pumpAndSettle();
        debugPrint('[SS] Coach mark dismissed (次へ)');
      } else if (coachDone.evaluate().isNotEmpty) {
        await tester.tap(coachDone.first);
        await tester.pumpAndSettle();
        debugPrint('[SS] Coach mark dismissed (OK)');
      } else {
        final barrier = find.byType(ModalBarrier);
        if (barrier.evaluate().length > 1) {
          await tester.tapAt(const Offset(200, 400));
          await tester.pumpAndSettle();
          debugPrint('[SS] Coach mark dismissed (tap barrier)');
        } else {
          break;
        }
      }
    }
    await tester.pumpAndSettle();

    // =============================================
    // 2. 設定 → 開発者モード有効化 → プレミアムON → テストデータ投入
    // =============================================
    for (var i = 0; i < 30; i++) {
      if (find.byKey(const Key('settings_button')).evaluate().isNotEmpty) break;
      await tester.pump(const Duration(milliseconds: 500));
    }
    debugPrint('[SS] Settings button found: ${find.byKey(const Key("settings_button")).evaluate().length}');
    expect(find.byKey(const Key('settings_button')), findsOneWidget,
        reason: 'ホーム画面の設定ボタンが見つかりません');

    // 設定画面に遷移（直接タップ）
    debugPrint('[SS] Tapping settings button...');
    await tester.tap(find.byKey(const Key('settings_button')));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // 設定画面が開いたか確認
    final settingsTitle = find.text('設定');
    debugPrint('[SS] Settings title found: ${settingsTitle.evaluate().length}');
    debugPrint('[SS] Settings screen opened');

    // バージョン情報を7回タップして開発者モード解放
    final appInfoTile = find.byKey(const Key('app_info_tile'));
    debugPrint('[SS] app_info_tile found: ${appInfoTile.evaluate().length}');

    // scrollUntilVisible で表示させてから7回タップ
    try {
      await tester.scrollUntilVisible(
        appInfoTile, 200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      for (var i = 0; i < 7; i++) {
        await tester.tap(appInfoTile);
        await tester.pump(const Duration(milliseconds: 200));
      }
      await tester.pumpAndSettle(const Duration(seconds: 1));
      debugPrint('[SS] Dev mode activated');
    } catch (e) {
      debugPrint('[SS] WARNING: app_info_tile scroll failed: $e');
    }

    // SnackBarを閉じる
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // プレミアムトグルをON
    try {
      final premiumToggle = find.byKey(const Key('premium_mode_toggle'));
      await tester.scrollUntilVisible(
        premiumToggle, 200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      debugPrint('[SS] premium_mode_toggle visible');
      final switchWidget = find.descendant(
        of: premiumToggle,
        matching: find.byType(Switch),
      );
      if (switchWidget.evaluate().isNotEmpty) {
        final sw = tester.widget<Switch>(switchWidget);
        if (!sw.value) {
          await tester.tap(premiumToggle);
          await tester.pumpAndSettle();
          debugPrint('[SS] Premium ON');
        } else {
          debugPrint('[SS] Premium already ON');
        }
      }
    } catch (e) {
      debugPrint('[SS] WARNING: premium toggle failed: $e');
    }

    // AI固定テストデータ投入（家賃振込、週報提出、企画書作成 等のデモ用データ）
    try {
      final aiTestData = find.byKey(const Key('debug_ai_test_data'));
      await tester.scrollUntilVisible(
        aiTestData, 200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(aiTestData);
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // 確認ダイアログの「OK」ボタンをタップ
      final dialogOk = find.widgetWithText(FilledButton, 'OK');
      if (dialogOk.evaluate().isNotEmpty) {
        await tester.tap(dialogOk);
        await tester.pumpAndSettle(const Duration(seconds: 3));
        debugPrint('[SS] AI test data inserted (dialog confirmed)');
      } else {
        debugPrint('[SS] WARNING: Insert dialog OK button not found');
      }
    } catch (e) {
      debugPrint('[SS] WARNING: AI test data insertion failed: $e');
    }

    // ホームに戻る（GoRouterで確実に遷移）
    GoRouter.of(tester.element(find.byType(Scaffold).first)).go('/home');
    await tester.pumpAndSettle(const Duration(seconds: 3));
    // タスクがDBから読み込まれるのを待つ
    for (var i = 0; i < 20; i++) {
      final cards = find.byType(Card);
      if (cards.evaluate().isNotEmpty) {
        debugPrint('[SS] Tasks loaded: ${cards.evaluate().length} cards');
        break;
      }
      await tester.pump(const Duration(milliseconds: 500));
    }
    await tester.pumpAndSettle();
    debugPrint('[SS] Back to home');

    // =============================================
    // 3. AI整理実行
    // =============================================
    final aiButton = find.byKey(const Key('ai_sort_button'));
    debugPrint('[SS] ai_sort_button found: ${aiButton.evaluate().length}');
    if (aiButton.evaluate().isNotEmpty) {
      await tester.tap(aiButton);
      debugPrint('[SS] AI sort started');

      // AI整理完了を待つ（最大30秒）
      for (var i = 0; i < 60; i++) {
        await tester.pump(const Duration(milliseconds: 500));
        final loading = find.byType(CircularProgressIndicator);
        if (loading.evaluate().isEmpty) break;
      }
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // バックグラウンドダイアログが出ていたら閉じる
      final bgBtn = find.text('バックグラウンドで実行');
      if (bgBtn.evaluate().isNotEmpty) {
        await tester.tap(bgBtn);
        await tester.pumpAndSettle();
        for (var i = 0; i < 60; i++) {
          await tester.pump(const Duration(milliseconds: 500));
        }
        await tester.pumpAndSettle(const Duration(seconds: 2));
      }

      debugPrint('[SS] AI sort completed');
    }

    // AI結果画面に遷移
    final aiResultBtn = find.textContaining('AI整理結果');
    if (aiResultBtn.evaluate().isNotEmpty) {
      await tester.tap(aiResultBtn.first);
      await tester.pumpAndSettle(const Duration(seconds: 2));
    }

    // AI結果画面でスクショ
    final aiResultTitle = find.textContaining('整理しました');
    if (aiResultTitle.evaluate().isNotEmpty) {
      await takeScreenshot('raw_02_ai_result');
      debugPrint('[SS] ✓ raw_02_ai_result');
      GoRouter.of(tester.element(find.byType(Scaffold).first)).go('/home');
      await tester.pumpAndSettle(const Duration(seconds: 2));
    } else {
      GoRouter.of(tester.element(find.byType(Scaffold).first)).push('/ai-result');
      await tester.pumpAndSettle(const Duration(seconds: 2));
      await takeScreenshot('raw_02_ai_result');
      debugPrint('[SS] ✓ raw_02_ai_result');
      GoRouter.of(tester.element(find.byType(Scaffold).first)).go('/home');
      await tester.pumpAndSettle(const Duration(seconds: 2));
    }

    // =============================================
    // 4. ホーム画面スクショ
    // =============================================
    // ダイアログ/SnackBarを閉じる
    for (var i = 0; i < 3; i++) {
      final okBtn = find.text('OK');
      if (okBtn.evaluate().isNotEmpty) {
        await tester.tap(okBtn.first);
        await tester.pumpAndSettle();
      } else {
        break;
      }
    }

    // タスクが表示されるまで待つ
    for (var i = 0; i < 10; i++) {
      final anyTask = find.byType(Card);
      if (anyTask.evaluate().isNotEmpty) break;
      await tester.pump(const Duration(milliseconds: 500));
    }
    await tester.pumpAndSettle();
    debugPrint('[SS] Home task cards: ${find.byType(Card).evaluate().length}');

    await takeScreenshot('raw_01_home');
    debugPrint('[SS] ✓ raw_01_home');

    // =============================================
    // 5. タスク展開（AIコメント）スクショ — ホーム画面上で直接タップ
    // =============================================
    bool taskTapped = false;
    for (final name in ['週報提出', '家賃振込', '企画書', '日用品', '免許']) {
      final taskFinder = find.textContaining(name);
      if (taskFinder.evaluate().isNotEmpty) {
        await tester.tap(taskFinder.first);
        await tester.pumpAndSettle(const Duration(seconds: 1));
        taskTapped = true;
        debugPrint('[SS] Tapped task: $name');
        break;
      }
    }
    if (!taskTapped) {
      final cards = find.byType(Card);
      if (cards.evaluate().isNotEmpty) {
        await tester.tap(cards.first);
        await tester.pumpAndSettle(const Duration(seconds: 1));
        debugPrint('[SS] Tapped first card');
      } else {
        debugPrint('[SS] WARNING: No task cards found for AI comment screenshot');
      }
    }

    await takeScreenshot('raw_04_ai_comment');
    debugPrint('[SS] ✓ raw_04_ai_comment');

    // =============================================
    // 6. カレンダー画面スクショ
    // =============================================
    final calendarTab = find.byKey(const Key('filter_tab_1'));
    if (calendarTab.evaluate().isNotEmpty) {
      await tester.tap(calendarTab);
      await tester.pumpAndSettle(const Duration(seconds: 2));
    }

    // 「期限日」モードに切り替え
    final dueModeBtn = find.text('期限日');
    if (dueModeBtn.evaluate().isNotEmpty) {
      await tester.tap(dueModeBtn);
      await tester.pumpAndSettle(const Duration(seconds: 1));
      debugPrint('[SS] Calendar switched to 期限日 mode');
    }

    // ダイアログを閉じる
    final okBtn2 = find.text('OK');
    if (okBtn2.evaluate().isNotEmpty) {
      await tester.tap(okBtn2.first);
      await tester.pumpAndSettle();
    }

    await takeScreenshot('raw_03_calendar');
    debugPrint('[SS] ✓ raw_03_calendar');

    // =============================================
    // 7. ストア画面スクショ
    // =============================================
    GoRouter.of(tester.element(find.byType(Navigator).last)).go('/store');
    await tester.pumpAndSettle(const Duration(seconds: 3));

    await takeScreenshot('raw_iap');
    debugPrint('[SS] ✓ raw_iap');

    // エラーハンドラ復元
    FlutterError.onError = originalOnError;

    debugPrint('[SS] === All 6 screenshots captured! ===');
  });
}
