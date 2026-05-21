import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../l10n/generated/app_localizations.dart';

/// 日付を yyyy-MM-dd 形式の文字列に変換する
String formatDateForDb(DateTime date) {
  return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

/// #3: 日付を「M/d（曜）」 / 「M/d (Mon)」 形式で返す。
/// 月/日 表示を統一する共通フォーマッタ。
String formatDateWithWeekday(DateTime date, String locale) {
  if (locale.startsWith('ja')) {
    const weekdays = ['月', '火', '水', '木', '金', '土', '日'];
    final wd = weekdays[date.weekday - 1];
    return '${date.month}/${date.day}（$wd）';
  }
  const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  final wd = weekdays[date.weekday - 1];
  return '${date.month}/${date.day} ($wd)';
}

/// #3: 土日の色分け (土=青、 日=赤、 平日=null)。
/// null を返す日は呼び出し側のデフォルト色 (例: priorityColor) を使う。
Color? weekendAccentColor(DateTime date, {required bool isDark}) {
  switch (date.weekday) {
    case DateTime.saturday:
      return isDark ? const Color(0xFF7BD0FF) : const Color(0xFF1F6FEB);
    case DateTime.sunday:
      return isDark ? const Color(0xFFFF8585) : const Color(0xFFD13438);
    default:
      return null;
  }
}

/// 期限日を相対表示に変換する
String formatRelativeDate(DateTime dueDate, AppLocalizations l10n, String locale) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final due = DateTime(dueDate.year, dueDate.month, dueDate.day);
  final diff = due.difference(today).inDays;

  if (diff == 0) return l10n.today;
  if (diff == 1) return l10n.tomorrow;
  if (diff == -1) return l10n.yesterday;
  if (diff > 1 && diff <= 6) return l10n.daysLater(diff);
  if (diff < -1) return l10n.daysAgo(-diff);

  // 7日以上先: 日付表示
  final format = DateFormat.MMMd(locale).add_E();
  return format.format(dueDate);
}
