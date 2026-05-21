import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'app.dart';
import 'models/task.dart';
import 'providers/dev_mode_provider.dart';
import 'providers/purchase_provider.dart';
import 'providers/secure_storage_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/task_provider.dart';
import 'services/calendar_service.dart';
import 'services/database_service.dart';
import 'services/gamification_service.dart' as services;
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

// スクショ撮影時に強制テーマを指定するための env override (--dart-define=THEME_MODE=dark)
const _forcedThemeMode = String.fromEnvironment('THEME_MODE');

ThemeMode _resolveThemeMode(ThemeMode fallback) {
  switch (_forcedThemeMode) {
    case 'dark':
      return ThemeMode.dark;
    case 'light':
      return ThemeMode.light;
    default:
      return fallback;
  }
}

bool get _shouldDebugTheme => _forcedThemeMode.isNotEmpty;

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
  // #8: AI 整理チケット購入時に Keychain を更新
  purchaseService.onAiTicketPurchased = () async {
    await secureStorage.recordAiTicketPurchase();
    debugPrint('[INIT] AI ticket purchased -> SecureStorage updated');
  };
  try {
    await secureStorage.getInstallDate();
    debugPrint('[INIT] secureStorage OK');
  } catch (e) {
    debugPrint('[INIT] secureStorage skipped: $e');
  }

  // レビューサービス
  final reviewService = ReviewService(secureStorage);
  debugPrint('[INIT] reviewService OK');

  // 開発者用: --dart-define=SEED_TASKS=true でアプリ起動時にテストタスクを 3件投入。
  // 真っ白バグの再現/原因切り分け用。本番では絶対に有効化しない。
  const seedTasks = bool.fromEnvironment('SEED_TASKS');
  if (seedTasks && kDebugMode) {
    final existing = await dbService.getAllTasks();
    if (existing.isEmpty) {
      // SharedPreferencesでオンボもスキップ
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_onboarding_completed', true);

      final today = DateTime.now();
      final dayOnly = DateTime(today.year, today.month, today.day);
      final tomorrow = dayOnly.add(const Duration(days: 1));
      final next = dayOnly.add(const Duration(days: 7));
      final now = DateTime.now();

      await dbService.insertTask(Task(
        title: 'Sample today',
        dueDate: dayOnly,
        priority: 0,
        importance: 1,
        sortOrder: 0,
        createdAt: now,
        updatedAt: now,
      ));
      await dbService.insertTask(Task(
        title: 'Sample tomorrow',
        dueDate: tomorrow,
        priority: 0,
        importance: 1,
        sortOrder: 1,
        createdAt: now,
        updatedAt: now,
      ));
      await dbService.insertTask(Task(
        title: 'Sample next week',
        dueDate: next,
        priority: 0,
        importance: 1,
        sortOrder: 2,
        createdAt: now,
        updatedAt: now,
      ));
      debugPrint('[INIT] seeded 3 sample tasks');
    }
  }

  // #2-D: 累計 XP の Keychain バックアップ vs DB 値の reconciliation
  // #5-C: アプリ起動 1 回ごとにストリーク (連続起動日数) を更新
  try {
    final gam =
        services.GamificationService(dbService, secureStorage: secureStorage);
    await gam.reconcileTotalXpBackup();
    await gam.touchActivity();
    debugPrint('[INIT] XP backup reconciled + streak touched');
  } catch (e) {
    debugPrint('[INIT] gamification init skipped: $e');
  }

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
        initialThemeModeProvider.overrideWithValue(
          () {
            final resolved = _resolveThemeMode(settings.themeMode);
            if (_shouldDebugTheme) {
              debugPrint('[INIT] _forcedThemeMode="$_forcedThemeMode" '
                  'fallback=${settings.themeMode} -> $resolved');
            }
            return resolved;
          }(),
        ),
        initialExecutionTimingProvider
            .overrideWithValue(settings.executionTiming),
        initialSoundEnabledProvider.overrideWithValue(settings.soundEnabled),
        initialDevAiUnlimitedProvider.overrideWithValue(devMode.aiUnlimited),
        initialDevPremiumProvider.overrideWithValue(devMode.premium),
        initialUseNewUiProvider.overrideWithValue(devMode.useNewUi),
      ],
      child: const YaruNaviApp(),
    ),
  );

  // トリガーC: アプリ起動後10秒のフォールバック（最低優先度）
  Future.delayed(const Duration(seconds: 10), () {
    reviewService.requestReviewIfEligible();
  });
}
