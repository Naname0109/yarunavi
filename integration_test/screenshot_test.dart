import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:yarunavi/main.dart' as app;
import 'package:yarunavi/providers/settings_provider.dart';
import 'package:yarunavi/providers/task_provider.dart';
import 'package:yarunavi/services/ai_service.dart';
import 'package:yarunavi/widgets/ai_sort_button.dart';
import 'package:yarunavi/widgets/v2/task_card.dart';

// 撮影時にダーク版を撮るかを dart-define で受け取る (--dart-define=THEME_MODE=dark)
const _envThemeMode = String.fromEnvironment('THEME_MODE');
const _isDarkShot = _envThemeMode == 'dark';

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
    // v1: AppBar の歯車アイコン (`settings_button`)
    // v2: ボトムナビ「設定」ラベル (useNewUi デフォルト true なので v2 が初期表示)
    for (var i = 0; i < 30; i++) {
      if (find.byKey(const Key('settings_button')).evaluate().isNotEmpty) break;
      if (find.text('設定').evaluate().isNotEmpty) break;
      await tester.pump(const Duration(milliseconds: 500));
    }

    final settingsBtnV1 = find.byKey(const Key('settings_button'));
    if (settingsBtnV1.evaluate().isNotEmpty) {
      await tester.tap(settingsBtnV1);
    } else {
      // v2: ボトムナビの「設定」(最後の「設定」 = ボトムナビ)
      final settingsLabels = find.text('設定');
      if (settingsLabels.evaluate().isNotEmpty) {
        await tester.tap(settingsLabels.last, warnIfMissed: false);
      } else {
        debugPrint('[SS] WARNING: settings entry not found, skip setup');
      }
    }
    await tester.pumpAndSettle(const Duration(seconds: 2));
    debugPrint('[SS] Settings opened');

    // Dark テーマ切り替え (--dart-define=THEME_MODE=dark のとき)
    // ProviderContainer 直接操作: UI tap よりも確実。
    debugPrint('[SS] THEME_MODE=$_envThemeMode (dark=$_isDarkShot)');
    if (_isDarkShot) {
      try {
        final ctx = tester.element(find.byType(MaterialApp));
        final container = ProviderScope.containerOf(ctx);
        container
            .read(themeModeProvider.notifier)
            .setThemeMode(ThemeMode.dark);
        await tester.pumpAndSettle(const Duration(seconds: 1));
        final actual = container.read(themeModeProvider);
        debugPrint('[SS] Dark theme applied (themeMode=$actual)');
      } catch (e) {
        debugPrint('[SS] WARNING: dark theme switch: $e');
      }
    }

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

    // 新UIトグル ON (App Store スクリーンショットは新UIで撮影)
    try {
      final newUiToggle = find.byKey(const Key('use_new_ui_toggle'));
      await tester.scrollUntilVisible(
        newUiToggle, 200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      final sw = find.descendant(
        of: newUiToggle,
        matching: find.byType(Switch),
      );
      if (sw.evaluate().isNotEmpty && !tester.widget<Switch>(sw).value) {
        await tester.tap(newUiToggle);
        await tester.pumpAndSettle(const Duration(seconds: 1));
        debugPrint('[SS] New UI ON');
      }
    } catch (e) {
      debugPrint('[SS] WARNING: new UI: $e');
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
    // v1: GoRouter.go('/home') で十分。
    // v2: V2HomeShell の IndexedStack は state を保持するため、
    //     go('/home') だけでは _index が 3 (設定) のまま残る。
    //     ボトムナビの「ホーム」を再タップして _index=0 にリセット。
    GoRouter.of(tester.element(find.byType(Scaffold).first)).go('/home');
    await tester.pumpAndSettle(const Duration(seconds: 2));
    final homeTabLabel = find.text('ホーム');
    if (homeTabLabel.evaluate().isNotEmpty) {
      await tester.tap(homeTabLabel.last, warnIfMissed: false);
      await tester.pumpAndSettle(const Duration(seconds: 1));
    }
    await tester.pumpAndSettle(const Duration(seconds: 1));
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
    // AI 整理 API call が dart-define で API key 渡されていないと空応答になり、
    // /ai-result が「整理するタスクがありません」 placeholder で固定される。
    // → ProviderContainer 直接操作でダミー response を仕込んでから push する。
    {
      final ctx = tester.element(find.byType(MaterialApp));
      final container = ProviderScope.containerOf(ctx);
      final current = container.read(aiSortResponseProvider);
      if (current == null || current.tasks.isEmpty) {
        final allTasksAsync = container.read(tasksProvider);
        final allTasks = allTasksAsync.valueOrNull ?? const [];
        final pickable = allTasks
            .where((t) => t.id != null && t.completedAt == null)
            .take(8)
            .toList();
        final comments = [
          '締切が近く、 影響範囲が広いので最優先',
          '短時間で片付くため早めに着手',
          '関係者依存。 先に連絡だけ済ませる',
          'まとまった集中時間が必要',
          '体力に余裕のあるうちに',
          '同カテゴリでまとめて処理',
          '今週中に終われば OK',
          '余裕があれば前倒し',
        ];
        final dummyTasks = <AiSortResult>[];
        for (var i = 0; i < pickable.length; i++) {
          dummyTasks.add(AiSortResult(
            taskId: pickable[i].id!,
            priority: (i ~/ 2 + 1).clamp(1, 4),
            commentJa: comments[i % comments.length],
            commentEn: 'AI suggested ordering for this task',
          ));
        }
        container.read(aiSortResponseProvider.notifier).state = AiSortResponse(
          summaryJa: '今日の最優先 3件から着手し、 集中力が必要なものは午前中に。',
          summaryEn: 'Start with the 3 highest priorities; tackle deep-focus work in the morning.',
          tasks: dummyTasks,
        );
        debugPrint('[SS] aiSortResponse injected (${dummyTasks.length} tasks)');
      }
    }
    final hasResultScreen =
        find.textContaining('整理しました').evaluate().isNotEmpty ||
            find.textContaining('整理完了').evaluate().isNotEmpty;
    if (!hasResultScreen) {
      GoRouter.of(tester.element(find.byType(Scaffold).first)).push('/ai-result');
      await tester.pumpAndSettle(const Duration(seconds: 2));
    }
    // hero オーブ + sparkle badge + 統計バー + AIコメント の登場アニメーションを
    // 完全に流し切ってからベストフレームを撮るため、 settle 後に追加で 1.6秒 wait。
    for (var i = 0; i < 16; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.pumpAndSettle();
    await takeScreenshot('raw_02_ai_result');
    debugPrint('[SS] raw_02_ai_result');

    // Go back to home and dismiss any overlays/sheets
    // v2 では IndexedStack の _index リセットのためボトムナビ「ホーム」も明示タップ
    GoRouter.of(tester.element(find.byType(Scaffold).first)).go('/home');
    await tester.pumpAndSettle(const Duration(seconds: 2));
    final homeTabLabelB = find.text('ホーム');
    if (homeTabLabelB.evaluate().isNotEmpty) {
      await tester.tap(homeTabLabelB.last, warnIfMissed: false);
      await tester.pumpAndSettle(const Duration(seconds: 1));
    }
    await dismissOverlays(tester);

    // --- Screenshot 1: Home (clean, no bottom sheet) ---
    // V2 では Card ではなく V2TaskCard (Material+InkWell) なので InkWell 出現を待つ。
    for (var i = 0; i < 20; i++) {
      if (find.byType(InkWell).evaluate().isNotEmpty) break;
      await tester.pump(const Duration(milliseconds: 500));
    }
    await tester.pumpAndSettle();

    await takeScreenshot('raw_01_home');
    debugPrint('[SS] raw_01_home');

    // --- Screenshot 4: Task detail (V2TaskCard tap -> detail screen) ---
    // V2TaskCard を直接 type 一致で取得。 SliverList 内でも widget tree から
    // 見つかるので確実。
    final v2Cards = find.byType(V2TaskCard);
    final cardCount = v2Cards.evaluate().length;
    debugPrint('[SS] V2TaskCard count=$cardCount');
    if (cardCount > 0) {
      await tester.tap(v2Cards.first, warnIfMissed: false);
      // task detail 画面の遷移アニメーション + AI コメント表示
      await tester.pumpAndSettle(const Duration(seconds: 2));
      debugPrint('[SS] V2TaskCard tapped');
    }
    await takeScreenshot('raw_04_ai_comment');
    debugPrint('[SS] raw_04_ai_comment');

    // 詳細画面から戻る (以降の Calendar 撮影のため)
    final backBtn = find.byTooltip('戻る');
    if (backBtn.evaluate().isNotEmpty) {
      await tester.tap(backBtn.first, warnIfMissed: false);
      await tester.pumpAndSettle(const Duration(seconds: 1));
    } else {
      GoRouter.of(tester.element(find.byType(Scaffold).first)).go('/home');
      await tester.pumpAndSettle(const Duration(seconds: 1));
    }

    // --- Screenshot 3: Calendar ---
    // v1: フィルターchip「カレンダー」 / v2: ボトムナビ「カレンダー」
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
    // ホームタブに戻る (v1=「やること」 / v2=「ホーム」)
    var homeLabel = find.text('やること');
    if (homeLabel.evaluate().isEmpty) homeLabel = find.text('ホーム');
    if (homeLabel.evaluate().isNotEmpty) {
      await tester.tap(homeLabel.first, warnIfMissed: false);
      await tester.pumpAndSettle(const Duration(seconds: 1));
    }

    // タスク追加ボタン: v1 = FloatingActionButton / v2 = GlassBottomNav 中央+
    var taskAddTapped = false;
    final fab = find.byType(FloatingActionButton);
    if (fab.evaluate().isNotEmpty) {
      await tester.tap(fab);
      taskAddTapped = true;
    } else {
      // v2: + アイコンを探す (HeroAiCard 内「+タスクを追加」も candid)
      final addIcons = find.byIcon(Icons.add_rounded);
      if (addIcons.evaluate().isNotEmpty) {
        // 最後のアイコン = ボトムナビ中央+FAB (画面下端)
        await tester.tap(addIcons.last, warnIfMissed: false);
        taskAddTapped = true;
      }
    }

    if (taskAddTapped) {
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
