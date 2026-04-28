import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;

import '../models/task.dart';
import '../utils/constants.dart';

class NotificationService {
  static const _isE2ETest = bool.fromEnvironment('E2E_TEST');

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  bool get isInitialized => _initialized;

  /// 通知がサポートされるプラットフォームか
  static bool get isSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  Future<void> initialize() async {
    if (!isSupported) return;
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    // 初期化時はパーミッションを要求しない（シミュレータのシステムダイアログでブロックを防ぐ）
    // パーミッションは requestPermission() で明示的にリクエストする
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // Android通知チャンネル作成
    const channel = AndroidNotificationChannel(
      AppConstants.notificationChannelId,
      AppConstants.notificationChannelName,
      importance: Importance.high,
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    _initialized = true;
  }

  void _onNotificationTap(NotificationResponse response) {
    // 通知タップ時: アプリが開く（go_routerで /  に遷移済み）
    debugPrint('Notification tapped: ${response.payload}');
  }

  /// iOS通知権限をリクエスト
  Future<bool> requestPermission() async {
    if (!isSupported) return false;
    if (_isE2ETest) return true;
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      final result = await ios.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return result ?? false;
    }
    return true;
  }

  /// タスクの通知をスケジュール
  /// [locale] は通知テキストの言語選択に使用（'ja' or 'en'）
  Future<void> scheduleTaskNotifications(
    Task task, {
    required bool isPremium,
    String locale = 'ja',
  }) async {
    if (!isSupported) return;
    if (!isPremium && !kDebugMode) return;
    if (task.id == null) return;
    if (task.notifySettings == null || task.isCompleted) return;

    // 通知をスケジュールする前にパーミッションを確認・要求
    await requestPermission();

    List<String> settings;
    try {
      settings = List<String>.from(jsonDecode(task.notifySettings!) as List);
    } catch (_) {
      return;
    }

    for (final setting in settings) {
      final offset = AppConstants.notifyOffsets[setting];
      final daysBefore = AppConstants.notifyDaysBefore[setting];
      if (offset == null || daysBefore == null) continue;

      final notifyDate = task.dueDate.subtract(Duration(days: daysBefore));
      final scheduledDateTime = tz.TZDateTime(
        tz.local,
        notifyDate.year,
        notifyDate.month,
        notifyDate.day,
        AppConstants.notificationHour,
      );

      // 過去の日時はスキップ
      if (scheduledDateTime.isBefore(tz.TZDateTime.now(tz.local))) continue;

      final notificationId = task.id! * 10 + offset;

      // 通知テキスト（ロケール対応）
      String body;
      if (task.recurrenceType != null && setting == 'on_due') {
        body = locale == 'ja'
            ? '${task.title} の時期です'
            : "It's time for ${task.title}";
      } else if (daysBefore == 0) {
        body = locale == 'ja'
            ? '${task.title} の期限は今日です'
            : '${task.title} is due today';
      } else {
        body = locale == 'ja'
            ? '${task.title} の期限まであと$daysBefore日です'
            : '${task.title} is due in $daysBefore days';
      }

      await _plugin.zonedSchedule(
        notificationId,
        AppConstants.appName,
        body,
        scheduledDateTime,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            AppConstants.notificationChannelId,
            AppConstants.notificationChannelName,
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: task.id.toString(),
      );
    }
  }

  /// AI推奨日付でタスクの通知をスケジュール
  Future<void> scheduleNotificationsForDates(
    Task task, {
    required List<String> dates,
    required bool isPremium,
    String locale = 'ja',
  }) async {
    if (!isSupported) return;
    if (!isPremium && !kDebugMode) return;
    if (task.id == null || task.isCompleted) return;

    // 既存通知をクリア
    await cancelTaskNotifications(task.id!);

    for (var i = 0; i < dates.length && i < 4; i++) {
      final date = DateTime.tryParse(dates[i]);
      if (date == null) continue;

      final scheduledDateTime = tz.TZDateTime(
        tz.local,
        date.year,
        date.month,
        date.day,
        AppConstants.notificationHour,
      );

      if (scheduledDateTime.isBefore(tz.TZDateTime.now(tz.local))) continue;

      final notificationId = task.id! * 10 + i;

      final body = locale == 'ja'
          ? '${task.title} の期限が近づいています'
          : '${task.title} deadline is approaching';

      await _plugin.zonedSchedule(
        notificationId,
        AppConstants.appName,
        body,
        scheduledDateTime,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            AppConstants.notificationChannelId,
            AppConstants.notificationChannelName,
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: task.id.toString(),
      );
    }
  }

  /// タスクの通知を全キャンセル
  Future<void> cancelTaskNotifications(int taskId) async {
    if (!isSupported) return;
    for (final offset in AppConstants.notifyOffsets.values) {
      await _plugin.cancel(taskId * 10 + offset);
    }
  }

  /// 全通知を再構築
  Future<void> rescheduleAllNotifications(
    List<Task> tasks, {
    required bool isPremium,
    String locale = 'ja',
  }) async {
    if (!isSupported) return;
    await _plugin.cancelAll();

    if (!isPremium && !kDebugMode) return;

    for (final task in tasks) {
      if (!task.isCompleted && task.notifySettings != null) {
        await scheduleTaskNotifications(task,
            isPremium: isPremium, locale: locale);
      }
    }

    // 全タスク期限切れチェック → 通知スケジュール
    await _checkAndScheduleAllExpiredNotification(
      tasks,
      isPremium: isPremium,
      locale: locale,
    );
  }

  /// 全タスクが期限切れの場合、翌朝9:00に通知をスケジュール
  Future<void> _checkAndScheduleAllExpiredNotification(
    List<Task> tasks, {
    required bool isPremium,
    String locale = 'ja',
  }) async {
    if (!isPremium && !kDebugMode) return;

    final incompleteTasks = tasks.where((t) => !t.isCompleted).toList();
    if (incompleteTasks.isEmpty) return;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final allOverdue = incompleteTasks.every(
      (t) => t.dueDate.isBefore(today),
    );
    if (!allOverdue) return;

    // フラグチェック
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(AppConstants.allExpiredNotifiedKey) == true) return;

    // 翌朝9:00にスケジュール
    final tomorrow9am = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day + 1,
      AppConstants.notificationHour,
    );

    final body = locale == 'ja'
        ? 'すべてのタスクの期限が過ぎました。新しいやることを追加しませんか？'
        : 'All task deadlines have passed. Add new tasks to stay organized!';

    await _plugin.zonedSchedule(
      AppConstants.allExpiredNotificationId,
      AppConstants.appName,
      body,
      tomorrow9am,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          AppConstants.notificationChannelId,
          AppConstants.notificationChannelName,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );

    // フラグを保存（重複送信防止）
    await prefs.setBool(AppConstants.allExpiredNotifiedKey, true);
  }

  /// 全期限切れ通知フラグをリセットし、スケジュール済み通知もキャンセル
  Future<void> resetAllExpiredFlag() async {
    if (!isSupported) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.allExpiredNotifiedKey, false);
    await _plugin.cancel(AppConstants.allExpiredNotificationId);
  }
}
