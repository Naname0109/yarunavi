import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:yarunavi/app.dart';
import 'package:yarunavi/providers/dev_mode_provider.dart';
import 'package:yarunavi/providers/settings_provider.dart';
import 'package:yarunavi/providers/task_provider.dart';
import 'package:yarunavi/services/database_service.dart';
import 'package:yarunavi/services/notification_service.dart';
import 'package:yarunavi/services/purchase_service.dart';
import 'package:yarunavi/services/calendar_service.dart';
import 'package:yarunavi/services/secure_storage_service.dart';
import 'package:yarunavi/providers/purchase_provider.dart';
import 'package:yarunavi/providers/secure_storage_provider.dart';
import 'package:yarunavi/utils/test_data.dart';

/// 全画面のオーバーフロー・レイアウト検証テスト
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late DatabaseService db;
  late NotificationService notif;
  late SecureStorageService secure;

  // オーバーフローエラーを収集
  final overflowErrors = <String>[];

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    db = DatabaseService();
    await db.initialize();
    notif = NotificationService();
    secure = SecureStorageService();
  });

  tearDown(() async {
    await db.close();
  });

  Widget buildApp({ThemeMode themeMode = ThemeMode.light}) {
    return ProviderScope(
      overrides: [
        databaseServiceProvider.overrideWithValue(db),
        notificationServiceProvider.overrideWithValue(notif),
        calendarServiceProvider.overrideWithValue(CalendarService()),
        purchaseServiceProvider.overrideWithValue(PurchaseService.instance),
        secureStorageServiceProvider.overrideWithValue(secure),
        initialLocaleProvider.overrideWithValue(const Locale('ja')),
        initialThemeModeProvider.overrideWithValue(themeMode),
        initialDevAiUnlimitedProvider.overrideWithValue(false),
        initialDevPremiumProvider.overrideWithValue(false),
      ],
      child: const YaruNaviApp(),
    );
  }

  /// オーバーフローを検出するヘルパー
  void captureOverflowErrors() {
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      final msg = details.exceptionAsString();
      if (msg.contains('overflowed') || msg.contains('OVERFLOWED')) {
        overflowErrors.add(msg);
        debugPrint('[OVERFLOW DETECTED] $msg');
      }
      originalOnError?.call(details);
    };
  }

  group('オンボーディング画面（ライトモード）', () {
    testWidgets('全6画面をスワイプして通過 — オーバーフローなし', (tester) async {
      overflowErrors.clear();
      captureOverflowErrors();

      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // スプラッシュ→オンボーディングの遷移を待つ
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // 各画面をスワイプして進む（6画面）
      for (var i = 0; i < 5; i++) {
        // 現在の画面でオーバーフローがないか確認
        await tester.pumpAndSettle();
        debugPrint('[TEST] オンボーディング画面${i + 1} 表示確認');

        // 次へボタンをタップ
        final nextButton = find.text('次へ');
        if (nextButton.evaluate().isNotEmpty) {
          await tester.tap(nextButton);
          await tester.pumpAndSettle();
        } else {
          // ボタンが見つからない場合はスワイプ
          await tester.fling(
              find.byType(PageView), const Offset(-300, 0), 1000);
          await tester.pumpAndSettle();
        }
      }

      // 最終画面（はじめる）
      await tester.pumpAndSettle();
      debugPrint('[TEST] オンボーディング画面6 表示確認');

      expect(overflowErrors, isEmpty,
          reason: 'オンボーディング画面でオーバーフローが検出されました: $overflowErrors');
    });
  });

  group('オンボーディング画面（ダークモード）', () {
    testWidgets('全6画面をスワイプして通過 — オーバーフローなし', (tester) async {
      overflowErrors.clear();
      captureOverflowErrors();

      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(buildApp(themeMode: ThemeMode.dark));
      await tester.pumpAndSettle(const Duration(seconds: 3));

      for (var i = 0; i < 5; i++) {
        await tester.pumpAndSettle();
        debugPrint('[TEST-DARK] オンボーディング画面${i + 1} 表示確認');

        final nextButton = find.text('次へ');
        if (nextButton.evaluate().isNotEmpty) {
          await tester.tap(nextButton);
          await tester.pumpAndSettle();
        } else {
          await tester.fling(
              find.byType(PageView), const Offset(-300, 0), 1000);
          await tester.pumpAndSettle();
        }
      }

      await tester.pumpAndSettle();
      expect(overflowErrors, isEmpty,
          reason: 'ダークモードオンボーディングでオーバーフロー: $overflowErrors');
    });
  });

  group('ホーム画面・タスクリスト', () {
    testWidgets('テストデータ15件でオーバーフローなし', (tester) async {
      overflowErrors.clear();
      captureOverflowErrors();

      // オンボーディングスキップ
      SharedPreferences.setMockInitialValues({
        'is_onboarding_completed': true,
        'coachmarks_shown': true,
      });

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // テストデータ投入
      await insertDetailedTestData(db);
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // ホーム画面が表示されているか
      expect(find.byType(Scaffold), findsWidgets);
      debugPrint('[TEST] ホーム画面 表示確認');

      // タスクリストをスクロール
      final listFinder = find.byType(Scrollable).first;
      await tester.fling(listFinder, const Offset(0, -300), 1000);
      await tester.pumpAndSettle();
      debugPrint('[TEST] タスクリスト スクロール確認');

      expect(overflowErrors, isEmpty,
          reason: 'ホーム画面でオーバーフロー: $overflowErrors');
    });

    testWidgets('ダークモードでオーバーフローなし', (tester) async {
      overflowErrors.clear();
      captureOverflowErrors();

      SharedPreferences.setMockInitialValues({
        'is_onboarding_completed': true,
        'coachmarks_shown': true,
      });

      await tester.pumpWidget(buildApp(themeMode: ThemeMode.dark));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      await insertDetailedTestData(db);
      await tester.pumpAndSettle(const Duration(seconds: 1));

      expect(overflowErrors, isEmpty,
          reason: 'ダークモードホーム画面でオーバーフロー: $overflowErrors');
    });
  });

  group('カレンダー画面', () {
    testWidgets('カレンダー表示でオーバーフローなし', (tester) async {
      overflowErrors.clear();
      captureOverflowErrors();

      SharedPreferences.setMockInitialValues({
        'is_onboarding_completed': true,
        'coachmarks_shown': true,
      });

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle(const Duration(seconds: 2));

      await insertDetailedTestData(db);
      await tester.pumpAndSettle();

      // カレンダータブに切り替え
      final calendarTab = find.byIcon(Icons.calendar_month);
      if (calendarTab.evaluate().isNotEmpty) {
        await tester.tap(calendarTab.last);
        await tester.pumpAndSettle();
        debugPrint('[TEST] カレンダー画面 表示確認');
      }

      expect(overflowErrors, isEmpty,
          reason: 'カレンダー画面でオーバーフロー: $overflowErrors');
    });
  });

  group('設定画面', () {
    testWidgets('設定画面表示でオーバーフローなし', (tester) async {
      overflowErrors.clear();
      captureOverflowErrors();

      SharedPreferences.setMockInitialValues({
        'is_onboarding_completed': true,
        'coachmarks_shown': true,
      });

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // 設定アイコンをタップ
      final settingsIcon = find.byIcon(Icons.settings);
      if (settingsIcon.evaluate().isNotEmpty) {
        await tester.tap(settingsIcon.first);
        await tester.pumpAndSettle();
        debugPrint('[TEST] 設定画面 表示確認');

        // スクロールして全体を表示
        final scrollable = find.byType(Scrollable);
        if (scrollable.evaluate().isNotEmpty) {
          await tester.fling(scrollable.first, const Offset(0, -500), 1000);
          await tester.pumpAndSettle();
        }
      }

      expect(overflowErrors, isEmpty,
          reason: '設定画面でオーバーフロー: $overflowErrors');
    });
  });

  group('iPad画面サイズ', () {
    testWidgets('iPad幅(1024x1366)でオンボーディング — オーバーフローなし',
        (tester) async {
      overflowErrors.clear();
      captureOverflowErrors();

      // iPad Pro 12.9インチ相当のサイズ
      tester.view.physicalSize = const Size(2048, 2732);
      tester.view.devicePixelRatio = 2.0;

      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle(const Duration(seconds: 3));

      for (var i = 0; i < 5; i++) {
        await tester.pumpAndSettle();
        debugPrint('[TEST-iPad] オンボーディング画面${i + 1}');

        final nextButton = find.text('次へ');
        if (nextButton.evaluate().isNotEmpty) {
          await tester.tap(nextButton);
          await tester.pumpAndSettle();
        } else {
          await tester.fling(
              find.byType(PageView), const Offset(-300, 0), 1000);
          await tester.pumpAndSettle();
        }
      }

      // リセット
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();

      expect(overflowErrors, isEmpty,
          reason: 'iPad画面でオーバーフロー: $overflowErrors');
    });

    testWidgets('iPad幅でホーム+カレンダー — オーバーフローなし',
        (tester) async {
      overflowErrors.clear();
      captureOverflowErrors();

      tester.view.physicalSize = const Size(2048, 2732);
      tester.view.devicePixelRatio = 2.0;

      SharedPreferences.setMockInitialValues({
        'is_onboarding_completed': true,
        'coachmarks_shown': true,
      });

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle(const Duration(seconds: 2));

      await insertDetailedTestData(db);
      await tester.pumpAndSettle();

      debugPrint('[TEST-iPad] ホーム画面 表示確認');

      // カレンダータブ
      final calendarTab = find.byIcon(Icons.calendar_month);
      if (calendarTab.evaluate().isNotEmpty) {
        await tester.tap(calendarTab.last);
        await tester.pumpAndSettle();
        debugPrint('[TEST-iPad] カレンダー画面 表示確認');
      }

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();

      expect(overflowErrors, isEmpty,
          reason: 'iPad画面でオーバーフロー: $overflowErrors');
    });
  });

  group('AI整理結果画面', () {
    testWidgets('フォールバック結果画面でオーバーフローなし', (tester) async {
      overflowErrors.clear();
      captureOverflowErrors();

      SharedPreferences.setMockInitialValues({
        'is_onboarding_completed': true,
        'coachmarks_shown': true,
      });

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // テストデータ投入
      await insertDetailedTestData(db);
      await tester.pumpAndSettle();

      // AI整理ボタンをタップ
      final aiButton = find.byIcon(Icons.auto_awesome);
      if (aiButton.evaluate().isNotEmpty) {
        await tester.tap(aiButton.first);
        // ローディング中
        await tester.pump(const Duration(seconds: 1));

        // ダイアログが出たらバックグラウンドで実行
        final bgButton = find.text('バックグラウンドで実行');
        if (bgButton.evaluate().isNotEmpty) {
          await tester.tap(bgButton);
        }

        // 結果を待つ
        await tester.pumpAndSettle(const Duration(seconds: 10));
        debugPrint('[TEST] AI整理結果画面 表示確認');

        // 結果画面をスクロール
        final scrollable = find.byType(Scrollable);
        if (scrollable.evaluate().isNotEmpty) {
          await tester.fling(scrollable.first, const Offset(0, -500), 1000);
          await tester.pumpAndSettle();
          debugPrint('[TEST] AI結果画面スクロール確認');
        }
      }

      expect(overflowErrors, isEmpty,
          reason: 'AI結果画面でオーバーフロー: $overflowErrors');
    });
  });
}
