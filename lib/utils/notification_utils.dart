import 'dart:convert';

import 'constants.dart';

/// notify_settings JSON から実際の通知日時 (朝9:00) を計算して返す。
///
/// - `null` または空 → 空リスト
/// - `['ai_auto']` → 空リスト (AI整理時に決定されるため、ここでは扱わない)
/// - 過去の日時は除外
/// - 結果は時系列順
List<DateTime> getScheduledNotificationDates(
  DateTime dueDate,
  String? notifySettings, {
  DateTime? now,
}) {
  if (notifySettings == null || notifySettings.isEmpty) return const [];

  List<String> keys;
  try {
    keys = List<String>.from(jsonDecode(notifySettings) as List);
  } catch (_) {
    return const [];
  }
  if (keys.isEmpty) return const [];
  if (keys.length == 1 && keys.first == 'ai_auto') return const [];

  final reference = now ?? DateTime.now();
  final dates = <DateTime>[];
  for (final key in keys) {
    final daysBefore = AppConstants.notifyDaysBefore[key];
    if (daysBefore == null) continue;
    final dt = DateTime(
      dueDate.year,
      dueDate.month,
      dueDate.day - daysBefore,
      AppConstants.notificationHour,
    );
    if (dt.isAfter(reference)) {
      dates.add(dt);
    }
  }
  dates.sort((a, b) => a.compareTo(b));
  return dates;
}

/// 通知設定が `ai_auto` かどうか
bool isAiAutoNotify(String? notifySettings) {
  if (notifySettings == null || notifySettings.isEmpty) return false;
  try {
    final keys = List<String>.from(jsonDecode(notifySettings) as List);
    return keys.length == 1 && keys.first == 'ai_auto';
  } catch (_) {
    return false;
  }
}
