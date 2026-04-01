import 'package:intl/intl.dart';

import '../l10n/generated/app_localizations.dart';

/// 日付を yyyy-MM-dd 形式の文字列に変換する
String formatDateForDb(DateTime date) {
  return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
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
