/// 定期タスクの次回due_dateを計算する
///
/// recurrenceValue のエンコーディング:
/// - weekly: 曜日番号 (1=月曜 ~ 7=日曜, Dart標準)
/// - monthly: 日にち (1-31)
/// - yearly: 月×100+日 (例: 315 = 3月15日, 229 = 2月29日)
/// - custom: 間隔日数
DateTime calculateNextDueDate({
  required DateTime currentDueDate,
  required String recurrenceType,
  required int recurrenceValue,
}) {
  switch (recurrenceType) {
    case 'weekly':
      return _nextWeekday(currentDueDate, recurrenceValue.clamp(1, 7));
    case 'monthly':
      return _nextMonthDay(currentDueDate, recurrenceValue.clamp(1, 31));
    case 'yearly':
      final month = (recurrenceValue ~/ 100).clamp(1, 12);
      final day = (recurrenceValue % 100).clamp(1, 31);
      return _nextYearMonthDay(currentDueDate, month, day);
    case 'custom':
      final interval = recurrenceValue < 1 ? 1 : recurrenceValue;
      return currentDueDate.add(Duration(days: interval));
    default:
      throw ArgumentError('Unknown recurrenceType: $recurrenceType');
  }
}

/// 次の該当曜日を計算（currentDueDateが該当曜日なら+7日）
DateTime _nextWeekday(DateTime from, int targetWeekday) {
  var daysUntil = targetWeekday - from.weekday;
  if (daysUntil <= 0) {
    daysUntil += 7;
  }
  return DateTime(from.year, from.month, from.day + daysUntil);
}

/// 翌月の指定日（月末繰り上げ対応）
DateTime _nextMonthDay(DateTime from, int targetDay) {
  var nextMonth = from.month + 1;
  var nextYear = from.year;
  if (nextMonth > 12) {
    nextMonth = 1;
    nextYear++;
  }
  final lastDay = _daysInMonth(nextYear, nextMonth);
  final day = targetDay > lastDay ? lastDay : targetDay;
  return DateTime(nextYear, nextMonth, day);
}

/// 翌年の同月同日（2/29→2/28繰り上げ対応）
DateTime _nextYearMonthDay(DateTime from, int targetMonth, int targetDay) {
  final nextYear = from.year + 1;
  final lastDay = _daysInMonth(nextYear, targetMonth);
  final day = targetDay > lastDay ? lastDay : targetDay;
  return DateTime(nextYear, targetMonth, day);
}

/// 指定年月の日数を返す
int _daysInMonth(int year, int month) {
  return DateTime(year, month + 1, 0).day;
}
