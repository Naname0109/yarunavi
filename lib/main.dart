import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'app.dart';
import 'providers/dev_mode_provider.dart';
import 'providers/purchase_provider.dart';
import 'providers/secure_storage_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/task_provider.dart';
import 'services/calendar_service.dart';
import 'services/database_service.dart';
import 'services/notification_service.dart';
import 'services/purchase_service.dart';
import 'services/review_service.dart';
import 'services/secure_storage_service.dart';

bool get _isDesktop =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.macOS);

bool get _isMobile =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Web: サービスが動作しないためUI確認のみ
  if (kIsWeb) {
    runApp(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text(
              'Web版はサポートされていません。\n'
              'Windowsデスクトップまたはモバイルデバイスで実行してください。',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18),
            ),
          ),
        ),
      ),
    );
    return;
  }

  debugPrint('[INIT] start');

  // タイムゾーン初期化
  tz_data.initializeTimeZones();
  try {
    final timezoneName = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timezoneName));
    debugPrint('[INIT] timezone OK');
  } catch (e) {
    debugPrint('[INIT] timezone skipped: $e');
  }

  // Desktop: sqflite FFI初期化
  if (_isDesktop) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    debugPrint('[INIT] sqflite FFI OK');
  }

  // 広告SDK初期化（モバイルのみ）
  if (_isMobile) {
    await MobileAds.instance.initialize();
  }
  debugPrint('[INIT] ads done');

  // DB初期化
  final dbService = DatabaseService();
  try {
    await dbService.initialize();
    debugPrint('[INIT] DB OK');
  } catch (e) {
    debugPrint('[INIT] DB failed: $e');
  }

  // 課金サービス
  final purchaseService = PurchaseService.instance;
  try {
    await purchaseService.initialize();
    debugPrint('[INIT] purchase OK');
  } catch (e) {
    debugPrint('[INIT] purchase skipped: $e');
  }

  // 通知初期化
  final notificationService = NotificationService();
  try {
    await notificationService.initialize();

    // 起動時に全通知を再構築
    final allTasks = await dbService.getAllTasks();
    await notificationService.rescheduleAllNotifications(
      allTasks,
      isPremium: purchaseService.isPremium,
    );
    debugPrint('[INIT] notification OK');
  } catch (e) {
    debugPrint('[INIT] notification skipped: $e');
  }

  // カレンダーサービス
  final calendarService = CalendarService();
  debugPrint('[INIT] calendar OK');

  // 設定読み込み（フリッカー防止のため先に読む）
  final settings = await loadSettingsFromPrefs();
  final devMode = await loadDevModePrefs();
  debugPrint('[INIT] settings OK');

  // セキュアストレージ (AI使用回数の永続化用)
  final secureStorage = SecureStorageService();
  try {
    await secureStorage.getInstallDate();
    debugPrint('[INIT] secureStorage OK');
  } catch (e) {
    debugPrint('[INIT] secureStorage skipped: $e');
  }

  // レビューサービス
  final reviewService = ReviewService(secureStorage);
  debugPrint('[INIT] reviewService OK');

  debugPrint('[INIT] all done, launching app');

  runApp(
    ProviderScope(
      overrides: [
        databaseServiceProvider.overrideWithValue(dbService),
        notificationServiceProvider.overrideWithValue(notificationService),
        calendarServiceProvider.overrideWithValue(calendarService),
        purchaseServiceProvider.overrideWithValue(purchaseService),
        secureStorageServiceProvider.overrideWithValue(secureStorage),
        reviewServiceProvider.overrideWithValue(reviewService),
        initialLocaleProvider.overrideWithValue(settings.locale),
        initialThemeModeProvider.overrideWithValue(settings.themeMode),
        initialDevAiUnlimitedProvider.overrideWithValue(devMode.aiUnlimited),
        initialDevPremiumProvider.overrideWithValue(devMode.premium),
      ],
      child: const YaruNaviApp(),
    ),
  );

  // トリガーC: アプリ起動後10秒のフォールバック（最低優先度）
  Future.delayed(const Duration(seconds: 10), () {
    reviewService.requestReviewIfEligible();
  });
}
