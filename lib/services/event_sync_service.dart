import 'package:device_calendar/device_calendar.dart' as dc;
import 'package:flutter/foundation.dart';

import '../models/event.dart';
import 'database_service.dart';

/// #2-2: iOS デバイスカレンダーから今日〜60日先の予定を同期する。
///
/// - 既存の `events` テーブル中 source='calendar_sync' を削除して上書き
/// - 戻り値: 取り込んだ件数 (権限拒否や致命的失敗時は -1)
///
/// EventSyncService は Riverpod Provider 化しない。
/// カレンダー同期は FAB からの明示的な操作時のみ実行される 1 回限りの処理
/// であり、 状態の継続管理は不要なため。
class EventSyncService {
  EventSyncService(this._db);
  final DatabaseService _db;
  final dc.DeviceCalendarPlugin _plugin = dc.DeviceCalendarPlugin();

  /// パーミッション確認 + 取得 → events テーブルへ全件再投入。
  /// 戻り値: 取り込み件数。 権限拒否やセットアップ失敗時のみ -1。
  /// 個別カレンダーで失敗した場合はそのカレンダーのみスキップし、 続行する。
  Future<int> syncNext60Days() async {
    // 権限取得は致命層 (ここで失敗したら -1)
    try {
      final permResult = await _plugin.hasPermissions();
      if (permResult.data != true) {
        final request = await _plugin.requestPermissions();
        if (request.data != true) return -1;
      }
    } catch (err) {
      debugPrint('[EVENT-SYNC] permission setup failed: $err');
      return -1;
    }

    final List<dc.Calendar> calendars;
    try {
      final calendarsResult = await _plugin.retrieveCalendars();
      if (calendarsResult.errors.isNotEmpty) {
        debugPrint(
            '[EVENT-SYNC] retrieveCalendars errors: ${calendarsResult.errors}');
      }
      calendars = calendarsResult.data ?? <dc.Calendar>[];
    } catch (err) {
      debugPrint('[EVENT-SYNC] retrieveCalendars failed: $err');
      return -1;
    }
    if (calendars.isEmpty) {
      await _db.deleteSyncedEvents();
      return 0;
    }

    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 60));
    final params = dc.RetrieveEventsParams(startDate: start, endDate: end);

    final fetched = <Event>[];
    for (final cal in calendars) {
      if (cal.id == null) continue;
      try {
        final res = await _plugin.retrieveEvents(cal.id, params);
        if (res.errors.isNotEmpty) {
          debugPrint(
              '[EVENT-SYNC] "${cal.name}" errors: ${res.errors}');
        }
        for (final e in res.data ?? <dc.Event>[]) {
          if (e.start == null) continue;
          final s = e.start!.toLocal();
          final allDay = e.allDay ?? false;
          fetched.add(Event(
            title: e.title ?? '(no title)',
            date: DateTime(s.year, s.month, s.day),
            startTime: allDay ? null : _fmt(s),
            endTime: allDay || e.end == null ? null : _fmt(e.end!.toLocal()),
            isAllDay: allDay,
            memo: e.description,
            source: 'calendar_sync',
            externalId: e.eventId,
            createdAt: DateTime.now(),
          ));
        }
      } catch (err) {
        // 1 つのカレンダー失敗で全停止しないようにスキップ
        debugPrint('[EVENT-SYNC] Calendar "${cal.name}" skipped: $err');
        continue;
      }
    }

    try {
      await _db.deleteSyncedEvents();
      for (final e in fetched) {
        await _db.insertEvent(e);
      }
    } catch (err) {
      debugPrint('[EVENT-SYNC] DB write failed: $err');
      return -1;
    }
    return fetched.length;
  }

  String _fmt(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}
