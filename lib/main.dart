import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
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
import 'services/secure_storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // タイムゾーン初期化
  tz_data.initializeTimeZones();
  final timezoneName = await FlutterTimezone.getLocalTimezone();
  tz.setLocalLocation(tz.getLocation(timezoneName));

  // 広告SDK初期化
  await MobileAds.instance.initialize();

  // DB初期化
  final dbService = DatabaseService();
  await dbService.initialize();

  // 課金サービス
  final purchaseService = PurchaseService.instance;
  await purchaseService.initialize();

  // 通知初期化
  final notificationService = NotificationService();
  await notificationService.initialize();

  // 起動時に全通知を再構築
  final allTasks = await dbService.getAllTasks();
  await notificationService.rescheduleAllNotifications(
    allTasks,
    isPremium: purchaseService.isPremium,
  );

  // カレンダーサービス
  final calendarService = CalendarService();

  // 設定読み込み（フリッカー防止のため先に読む）
  final settings = await loadSettingsFromPrefs();
  final devMode = await loadDevModePrefs();

  // セキュアストレージ (AI使用回数の永続化用)
  final secureStorage = SecureStorageService();
  await secureStorage.getInstallDate();

  runApp(
    ProviderScope(
      overrides: [
        databaseServiceProvider.overrideWithValue(dbService),
        notificationServiceProvider.overrideWithValue(notificationService),
        calendarServiceProvider.overrideWithValue(calendarService),
        purchaseServiceProvider.overrideWithValue(purchaseService),
        secureStorageServiceProvider.overrideWithValue(secureStorage),
        initialLocaleProvider.overrideWithValue(settings.locale),
        initialThemeModeProvider.overrideWithValue(settings.themeMode),
        initialDevAiUnlimitedProvider.overrideWithValue(devMode.aiUnlimited),
        initialDevPremiumProvider.overrideWithValue(devMode.premium),
      ],
      child: const YaruNaviApp(),
    ),
  );
}
