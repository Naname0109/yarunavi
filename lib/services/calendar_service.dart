import 'package:device_calendar/device_calendar.dart';
import 'package:timezone/timezone.dart' as tz;

import '../models/task.dart';

/// カレンダー操作の結果種別
enum CalendarResult { success, permissionDenied, failed }

class CalendarService {
  final DeviceCalendarPlugin _plugin = DeviceCalendarPlugin();

  /// カレンダーアクセス権限をリクエスト
  Future<bool> requestPermission() async {
    var result = await _plugin.hasPermissions();
    if (result.data == true) return true;

    result = await _plugin.requestPermissions();
    return result.data == true;
  }

  /// デフォルトカレンダーを取得（isDefault優先、なければwritable最初）
  Future<Calendar?> _getDefaultCalendar() async {
    final result = await _plugin.retrieveCalendars();
    if (result.data == null || result.data!.isEmpty) return null;

    final calendars =
        result.data!.where((c) => !(c.isReadOnly ?? true)).toList();
    if (calendars.isEmpty) return null;

    return calendars.firstWhere(
      (c) => c.isDefault ?? false,
      orElse: () => calendars.first,
    );
  }

  Event _buildEvent(String? calendarId, Task task, {String? eventId}) {
    return Event(calendarId, eventId: eventId)
      ..title = task.title
      ..description = task.memo
      ..start = tz.TZDateTime(
        tz.local,
        task.dueDate.year,
        task.dueDate.month,
        task.dueDate.day,
      )
      ..end = tz.TZDateTime(
        tz.local,
        task.dueDate.year,
        task.dueDate.month,
        task.dueDate.day + 1,
      )
      ..allDay = true;
  }

  /// タスクをカレンダーに終日イベントとして追加
  /// 戻り値: (結果, イベントID)
  Future<(CalendarResult, String?)> addTaskToCalendar(Task task) async {
    if (!await requestPermission()) {
      return (CalendarResult.permissionDenied, null);
    }

    final calendar = await _getDefaultCalendar();
    if (calendar == null) return (CalendarResult.failed, null);

    final event = _buildEvent(calendar.id, task);
    final result = await _plugin.createOrUpdateEvent(event);

    if (result?.isSuccess == true) {
      return (CalendarResult.success, result!.data);
    }
    return (CalendarResult.failed, null);
  }

  /// カレンダーイベントを更新
  Future<CalendarResult> updateCalendarEvent(Task task, String eventId) async {
    if (!await requestPermission()) return CalendarResult.permissionDenied;

    final calendar = await _getDefaultCalendar();
    if (calendar == null) return CalendarResult.failed;

    final event = _buildEvent(calendar.id, task, eventId: eventId);
    final result = await _plugin.createOrUpdateEvent(event);

    return result?.isSuccess == true
        ? CalendarResult.success
        : CalendarResult.failed;
  }

  /// カレンダーイベントを削除
  Future<CalendarResult> deleteCalendarEvent(String eventId) async {
    if (!await requestPermission()) return CalendarResult.permissionDenied;

    final calendar = await _getDefaultCalendar();
    if (calendar == null) return CalendarResult.failed;

    final result = await _plugin.deleteEvent(calendar.id, eventId);
    return result.isSuccess ? CalendarResult.success : CalendarResult.failed;
  }
}
