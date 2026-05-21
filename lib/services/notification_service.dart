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

  /// ストリーク達成時の祝福通知 (即時表示)。
  /// 3/7/14/30 日達成タイミングでアプリ側から呼び出す。
  /// 通知 ID は streakDays ベースで一意化し、同じマイルストーンの重複を防ぐ。
  Future<void> showStreakMilestoneNotification({
    required int streakDays,
    required String title,
    required String body,
  }) async {
    if (!isSupported || !_initialized) return;
    if (_isE2ETest) return;
    const androidDetails = AndroidNotificationDetails(
      AppConstants.notificationChannelId,
      AppConstants.notificationChannelName,
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    await _plugin.show(
      900000 + streakDays,
      title,
      body,
      const NotificationDetails(android: androidDetails, iOS: iosDetails),
      payload: 'streak:$streakDays',
    );
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

  /// #6-1 / #4: タスク通知の 3 段スケジュール。
  /// SharedPreferences の 3 トグル + カスタム時刻 (hour/minute) を読んで:
  /// - 実行日朝   (recommended_date のあるタスクのみ)
  /// - 期限日朝   (実行日と異なる場合のみ)
  /// - 期限超過翌日朝
  /// 既存呼び出しシグネチャを維持。
  Future<void> scheduleExecutionDayNotification(
    Task task, {
    required bool isPremium,
    String locale = 'ja',
  }) async {
    if (!isSupported) return;
    if (!isPremium && !kDebugMode) return;
    if (task.id == null || task.isCompleted) return;

    final prefs = await SharedPreferences.getInstance();
    final onRec = prefs.getBool('notify_on_recommended_date') ?? true;
    final onDue = prefs.getBool('notify_on_due_date') ?? true;
    final onOverdue = prefs.getBool('notify_on_overdue') ?? true;
    final hour = prefs.getInt('notify_time_hour') ?? 9;
    final minute = prefs.getInt('notify_time_minute') ?? 0;

    await requestPermission();
    final now = tz.TZDateTime.now(tz.local);
    final taskId = task.id!;
    final rec = task.recommendedDate;
    final due = task.dueDate;
    final recDay = rec == null
        ? null
        : DateTime(rec.year, rec.month, rec.day);
    final dueDay = DateTime(due.year, due.month, due.day);

    // 既存の 3 段通知を一度キャンセル (置き換え)。
    // ID オフセット 0-3 は AppConstants.notifyOffsets (on_due / 1_day_before /
    // 3_days_before / 1_week_before) で予約済みのため、 重複を避けて 7-9 を使う。
    await _plugin.cancel(taskId * 10 + 7);
    await _plugin.cancel(taskId * 10 + 8);
    await _plugin.cancel(taskId * 10 + 9);

    Future<void> schedule({
      required int id,
      required tz.TZDateTime when,
      required String body,
    }) async {
      if (when.isBefore(now)) return;
      await _plugin.zonedSchedule(
        id,
        AppConstants.appName,
        body,
        when,
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
        payload: taskId.toString(),
      );
    }

    // #4-1 (a) 実行日朝
    if (onRec && recDay != null) {
      await schedule(
        id: taskId * 10 + 7,
        when: tz.TZDateTime(
            tz.local, recDay.year, recDay.month, recDay.day, hour, minute),
        body: locale == 'ja'
            ? '今日のタスク: ${task.title}'
            : "Today's task: ${task.title}",
      );
    }

    // #4-1 (b) 期限日朝 (rec と異なる場合のみ)
    if (onDue && (recDay == null || recDay != dueDay)) {
      await schedule(
        id: taskId * 10 + 8,
        when: tz.TZDateTime(
            tz.local, dueDay.year, dueDay.month, dueDay.day, hour, minute),
        body: locale == 'ja'
            ? '本日が期限です: ${task.title}'
            : '${task.title} is due today',
      );
    }

    // #4-1 (c) 期限超過翌日朝
    if (onOverdue) {
      final over = dueDay.add(const Duration(days: 1));
      await schedule(
        id: taskId * 10 + 9,
        when: tz.TZDateTime(
            tz.local, over.year, over.month, over.day, hour, minute),
        body: locale == 'ja'
            ? '期限を過ぎています: ${task.title} 早めに対応しましょう'
            : 'Overdue: ${task.title} — please address soon',
      );
    }
  }

  /// #6-2: タスク整理リマインド。 同日中に 1 度しか発火しない (id 固定)。
  /// アプリ起動時の check_and_schedule で呼ぶ想定。
  Future<void> scheduleAiSortReminder({
    required bool enabled,
    String locale = 'ja',
  }) async {
    const reminderId = 9999;
    if (!isSupported) return;
    if (!enabled) {
      await _plugin.cancel(reminderId);
      return;
    }
    // 既存予定があれば一旦キャンセル (置き換え)
    await _plugin.cancel(reminderId);

    final now = tz.TZDateTime.now(tz.local);
    // 18 時に通知 (夕方に「整理しませんか?」)
    var target = tz.TZDateTime(
        tz.local, now.year, now.month, now.day, 18);
    if (target.isBefore(now)) {
      target = target.add(const Duration(days: 1));
    }
    final title = locale == 'ja'
        ? 'やることが溜まっていませんか?'
        : 'Tasks piling up?';
    final body = locale == 'ja'
        ? 'AIで整理しましょう'
        : 'Let AI sort them for you';

    await _plugin.zonedSchedule(
      reminderId,
      title,
      body,
      target,
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
