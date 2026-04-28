import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:go_router/go_router.dart';

import 'package:yarunavi/main.dart' as app;

/// App Store screenshot capture (5 + IAP)
///
///   flutter drive \
///     --no-enable-impeller \
///     --driver=test_driver/screenshot_driver.dart \
///     --target=integration_test/screenshot_test.dart \
///     -d "iPhone 17 Pro Max"
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> takeScreenshot(String name) async {
    await Future.delayed(const Duration(milliseconds: 800));
    await binding.takeScreenshot(name);
  }

  testWidgets('App Store screenshots', (tester) async {
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      final msg = details.exceptionAsString();
      if (msg.contains('ParentData') || msg.contains('overflowed')) return;
      originalOnError?.call(details);
    };

    // --- App launch ---
    app.main();
    debugPrint('[SS] Waiting for app...');
    await Future.delayed(const Duration(seconds: 5));
    await tester.pumpAndSettle(const Duration(seconds: 5));
    await Future.delayed(const Duration(seconds: 3));
    await tester.pumpAndSettle(const Duration(seconds: 3));
    debugPrint('[SS] App launched');

    // --- Skip onboarding ---
    for (var i = 0; i < 20; i++) {
      if (find.byKey(const Key('onboarding_next')).evaluate().isNotEmpty) break;
      if (find.byKey(const Key('settings_button')).evaluate().isNotEmpty) break;
      await tester.pump(const Duration(milliseconds: 500));
    }

    final nextBtn = find.byKey(const Key('onboarding_next'));
    if (nextBtn.evaluate().isNotEmpty) {
      await tester.tap(nextBtn);
      await tester.pumpAndSettle();
      final skipBtn = find.byKey(const Key('onboarding_skip'));
      if (skipBtn.evaluate().isNotEmpty) {
        await tester.tap(skipBtn);
        await tester.pumpAndSettle(const Duration(seconds: 2));
      }
      debugPrint('[SS] Onboarding skipped');
    }

    // --- Dismiss coach marks ---
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 300));
      final coachNext = find.text('次へ');
      final coachDone = find.text('OK');
      if (coachNext.evaluate().isNotEmpty) {
        await tester.tap(coachNext.first);
        await tester.pumpAndSettle();
      } else if (coachDone.evaluate().isNotEmpty) {
        await tester.tap(coachDone.first);
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

    // --- Settings: dev mode + premium + test data ---
    for (var i = 0; i < 30; i++) {
      if (find.byKey(const Key('settings_button')).evaluate().isNotEmpty) break;
      await tester.pump(const Duration(milliseconds: 500));
    }

    await tester.tap(find.byKey(const Key('settings_button')));
    await tester.pumpAndSettle(const Duration(seconds: 2));
    debugPrint('[SS] Settings opened');

    // Dev mode (7 taps)
    final appInfoTile = find.byKey(const Key('app_info_tile'));
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
      debugPrint('[SS] Dev mode ON');
    } catch (e) {
      debugPrint('[SS] WARNING: dev mode: $e');
    }
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // Premium toggle
    try {
      final premiumToggle = find.byKey(const Key('premium_mode_toggle'));
      await tester.scrollUntilVisible(
        premiumToggle, 200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      final sw = find.descendant(
        of: premiumToggle,
        matching: find.byType(Switch),
      );
      if (sw.evaluate().isNotEmpty && !tester.widget<Switch>(sw).value) {
        await tester.tap(premiumToggle);
        await tester.pumpAndSettle();
        debugPrint('[SS] Premium ON');
      }
    } catch (e) {
      debugPrint('[SS] WARNING: premium: $e');
    }

    // Insert test data
    try {
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
        debugPrint('[SS] Test data inserted');
      }
    } catch (e) {
      debugPrint('[SS] WARNING: test data: $e');
    }

    // Back to home
    GoRouter.of(tester.element(find.byType(Scaffold).first)).go('/home');
    await tester.pumpAndSettle(const Duration(seconds: 3));
    for (var i = 0; i < 20; i++) {
      if (find.byType(Card).evaluate().isNotEmpty) break;
      await tester.pump(const Duration(milliseconds: 500));
    }
    await tester.pumpAndSettle();
    debugPrint('[SS] Home ready');

    // --- AI sort ---
    final aiButton = find.byKey(const Key('ai_sort_button'));
    if (aiButton.evaluate().isNotEmpty) {
      await tester.tap(aiButton);
      debugPrint('[SS] AI sort started');

      for (var i = 0; i < 60; i++) {
        await tester.pump(const Duration(milliseconds: 500));
        final loading = find.byType(CircularProgressIndicator);
        if (loading.evaluate().isEmpty) break;
      }
      await tester.pumpAndSettle(const Duration(seconds: 2));

      final bgBtn = find.text('バックグラウンドで実行');
      if (bgBtn.evaluate().isNotEmpty) {
        await tester.tap(bgBtn);
        await tester.pumpAndSettle();
        for (var i = 0; i < 60; i++) {
          await tester.pump(const Duration(milliseconds: 500));
        }
        await tester.pumpAndSettle(const Duration(seconds: 2));
      }
      debugPrint('[SS] AI sort done');
    }

    // --- Screenshot 2: AI result ---
    final aiResultTitle = find.textContaining('整理しました');
    if (aiResultTitle.evaluate().isNotEmpty) {
      await takeScreenshot('raw_02_ai_result');
      debugPrint('[SS] raw_02_ai_result');
      GoRouter.of(tester.element(find.byType(Scaffold).first)).go('/home');
      await tester.pumpAndSettle(const Duration(seconds: 2));
    } else {
      GoRouter.of(tester.element(find.byType(Scaffold).first)).push('/ai-result');
      await tester.pumpAndSettle(const Duration(seconds: 2));
      await takeScreenshot('raw_02_ai_result');
      debugPrint('[SS] raw_02_ai_result');
      GoRouter.of(tester.element(find.byType(Scaffold).first)).go('/home');
      await tester.pumpAndSettle(const Duration(seconds: 2));
    }

    // --- Screenshot 1: Home ---
    for (var i = 0; i < 3; i++) {
      final okBtn = find.text('OK');
      if (okBtn.evaluate().isNotEmpty) {
        await tester.tap(okBtn.first);
        await tester.pumpAndSettle();
      } else {
        break;
      }
    }
    for (var i = 0; i < 10; i++) {
      if (find.byType(Card).evaluate().isNotEmpty) break;
      await tester.pump(const Duration(milliseconds: 500));
    }
    await tester.pumpAndSettle();

    await takeScreenshot('raw_01_home');
    debugPrint('[SS] raw_01_home');

    // --- Screenshot 4: Task detail (AI comment + notification) ---
    bool taskTapped = false;
    for (final name in ['週報提出', '家賃振込', '企画書', '日用品', '免許']) {
      final f = find.textContaining(name);
      if (f.evaluate().isNotEmpty) {
        await tester.tap(f.first);
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
      }
    }
    await takeScreenshot('raw_04_ai_comment');
    debugPrint('[SS] raw_04_ai_comment');

    // --- Screenshot 3: Calendar ---
    final calTab = find.byKey(const Key('filter_tab_1'));
    if (calTab.evaluate().isNotEmpty) {
      await tester.tap(calTab);
      await tester.pumpAndSettle(const Duration(seconds: 2));
    }
    final dueModeBtn = find.text('期限日');
    if (dueModeBtn.evaluate().isNotEmpty) {
      await tester.tap(dueModeBtn);
      await tester.pumpAndSettle(const Duration(seconds: 1));
    }
    for (var i = 0; i < 3; i++) {
      final ok = find.text('OK');
      if (ok.evaluate().isNotEmpty) {
        await tester.tap(ok.first);
        await tester.pumpAndSettle();
      } else {
        break;
      }
    }
    await takeScreenshot('raw_03_calendar');
    debugPrint('[SS] raw_03_calendar');

    // --- Screenshot 5: Simple input (task add form) ---
    // Switch back to todo tab
    final todoTab = find.byKey(const Key('filter_tab_0'));
    if (todoTab.evaluate().isNotEmpty) {
      await tester.tap(todoTab);
      await tester.pumpAndSettle(const Duration(seconds: 1));
    }

    final fab = find.byType(FloatingActionButton);
    if (fab.evaluate().isNotEmpty) {
      await tester.tap(fab);
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Enter sample text
      final titleField = find.byType(TextFormField).first;
      await tester.enterText(titleField, '買い物リスト');
      await tester.pumpAndSettle();

      // Dismiss keyboard
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle(const Duration(seconds: 1));

      await takeScreenshot('raw_05_simple_input');
      debugPrint('[SS] raw_05_simple_input');

      // Close form
      final cancelBtn = find.text('キャンセル');
      if (cancelBtn.evaluate().isNotEmpty) {
        await tester.tap(cancelBtn);
        await tester.pumpAndSettle(const Duration(seconds: 1));
      }
    }

    // --- IAP screenshot ---
    GoRouter.of(tester.element(find.byType(Navigator).last)).go('/store');
    await tester.pumpAndSettle(const Duration(seconds: 3));
    await takeScreenshot('raw_iap');
    debugPrint('[SS] raw_iap');

    FlutterError.onError = originalOnError;
    debugPrint('[SS] === All screenshots captured ===');
  });
}
