import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:go_router/go_router.dart';

import 'package:yarunavi/main.dart' as app;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> takeScreenshot(String name) async {
    await Future.delayed(const Duration(milliseconds: 800));
    await binding.takeScreenshot(name);
  }

  Future<void> dismissOverlays(WidgetTester tester) async {
    for (var i = 0; i < 5; i++) {
      final ok = find.text('OK');
      if (ok.evaluate().isNotEmpty) {
        await tester.tap(ok.first);
        await tester.pumpAndSettle();
      } else {
        break;
      }
    }
    // Dismiss any bottom sheets by tapping on the scrim
    final barriers = find.byType(ModalBarrier);
    if (barriers.evaluate().length > 1) {
      await tester.tapAt(const Offset(200, 200));
      await tester.pumpAndSettle();
    }
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
      final testDataBtn = find.byKey(const Key('debug_detailed_data'));
      await tester.scrollUntilVisible(
        testDataBtn, 200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(testDataBtn);
      await tester.pumpAndSettle(const Duration(seconds: 1));

      final dialogOk = find.widgetWithText(FilledButton, '投入する');
      if (dialogOk.evaluate().isNotEmpty) {
        await tester.tap(dialogOk);
        await tester.pumpAndSettle(const Duration(seconds: 3));
        debugPrint('[SS] Test data inserted');
      } else {
        debugPrint('[SS] WARNING: confirm button not found');
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
    await dismissOverlays(tester);
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
    } else {
      GoRouter.of(tester.element(find.byType(Scaffold).first)).push('/ai-result');
      await tester.pumpAndSettle(const Duration(seconds: 2));
      await takeScreenshot('raw_02_ai_result');
      debugPrint('[SS] raw_02_ai_result (pushed)');
    }

    // Go back to home and dismiss any overlays/sheets
    GoRouter.of(tester.element(find.byType(Scaffold).first)).go('/home');
    await tester.pumpAndSettle(const Duration(seconds: 3));
    await dismissOverlays(tester);

    // --- Screenshot 1: Home (clean, no bottom sheet) ---
    for (var i = 0; i < 10; i++) {
      if (find.byType(Card).evaluate().isNotEmpty) break;
      await tester.pump(const Duration(milliseconds: 500));
    }
    await tester.pumpAndSettle();

    await takeScreenshot('raw_01_home');
    debugPrint('[SS] raw_01_home');

    // --- Screenshot 4: Task detail (expand card to show AI comment) ---
    bool taskExpanded = false;
    // Try tapping the expand chevron on a card
    final expandIcons = find.byIcon(Icons.expand_more);
    if (expandIcons.evaluate().isNotEmpty) {
      await tester.tap(expandIcons.first);
      await tester.pumpAndSettle(const Duration(seconds: 1));
      taskExpanded = true;
      debugPrint('[SS] Task expanded via chevron');
    } else {
      // Fallback: tap any Card
      final cards = find.byType(Card);
      if (cards.evaluate().isNotEmpty) {
        await tester.tap(cards.first);
        await tester.pumpAndSettle(const Duration(seconds: 1));
        taskExpanded = true;
        debugPrint('[SS] Task tapped');
      }
    }
    await takeScreenshot('raw_04_ai_comment');
    debugPrint('[SS] raw_04_ai_comment');

    // --- Screenshot 3: Calendar ---
    // Tap "カレンダー" text in the filter chips
    final calLabel = find.text('カレンダー');
    if (calLabel.evaluate().isNotEmpty) {
      await tester.tap(calLabel.first, warnIfMissed: false);
      await tester.pumpAndSettle(const Duration(seconds: 2));
      debugPrint('[SS] Calendar tab selected');
    } else {
      debugPrint('[SS] WARNING: Calendar tab not found');
    }
    await dismissOverlays(tester);
    await takeScreenshot('raw_03_calendar');
    debugPrint('[SS] raw_03_calendar');

    // --- Screenshot 5: Simple input (task add form) ---
    // Switch back to todo tab
    final todoLabel = find.text('やること');
    if (todoLabel.evaluate().isNotEmpty) {
      await tester.tap(todoLabel.first, warnIfMissed: false);
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
