import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'app.dart';
import 'providers/task_provider.dart';
import 'services/ad_service.dart';
import 'services/calendar_service.dart';
import 'services/database_service.dart';
import 'services/notification_service.dart';
import 'widgets/ai_sort_button.dart';

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

  // 通知初期化
  final notificationService = NotificationService();
  await notificationService.initialize();

  // 起動時に全通知を再構築
  final allTasks = await dbService.getAllTasks();
  await notificationService.rescheduleAllNotifications(
    allTasks,
    isPremium: false, // TODO: ステップ10でSharedPreferencesから読み取り
  );

  // カレンダーサービス
  final calendarService = CalendarService();

  // 広告サービス
  final adService = AdService();
  await adService.initialize();

  runApp(
    ProviderScope(
      overrides: [
        databaseServiceProvider.overrideWithValue(dbService),
        notificationServiceProvider.overrideWithValue(notificationService),
        calendarServiceProvider.overrideWithValue(calendarService),
        adServiceProvider.overrideWithValue(adService),
      ],
      child: const YaruNaviApp(),
    ),
  );
}
