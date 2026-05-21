import 'package:device_calendar/device_calendar.dart' as dc;
import 'package:flutter/foundation.dart';

import '../models/event.dart';
import 'database_service.dart';

/// #2-2: iOS デバイスカレンダーから今日〜60日先の予定を同期する。
///
/// - 既存の `events` テーブル中 source='calendar_sync' を削除して上書き
/// - 戻り値: 取り込んだ件数 (失敗時は -1)
class EventSyncService {
  EventSyncService(this._db);
  final DatabaseService _db;
  final dc.DeviceCalendarPlugin _plugin = dc.DeviceCalendarPlugin();

  /// パーミッション確認 + 取得 → events テーブルへ全件再投入。
  /// 戻り値: 取り込み件数。 失敗時は -1。
  Future<int> syncNext60Days() async {
    try {
      // パーミッション
      final permResult = await _plugin.hasPermissions();
      if (permResult.data != true) {
        final request = await _plugin.requestPermissions();
        if (request.data != true) return -1;
      }

      final calendarsResult = await _plugin.retrieveCalendars();
      final calendars = calendarsResult.data ?? <dc.Calendar>[];
      if (calendars.isEmpty) {
        // 既存の sync 分はクリア
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
        final res = await _plugin.retrieveEvents(cal.id, params);
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
      }

      // 全削除 → 投入 (差分なしの全同期)
      await _db.deleteSyncedEvents();
      for (final e in fetched) {
        await _db.insertEvent(e);
      }
      return fetched.length;
    } catch (err, st) {
      debugPrint('[EVENT-SYNC] failed: $err\n$st');
      return -1;
    }
  }

  String _fmt(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}
