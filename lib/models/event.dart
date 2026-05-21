import 'package:freezed_annotation/freezed_annotation.dart';

import '../utils/date_utils.dart' as app_date;

part 'event.freezed.dart';
part 'event.g.dart';

/// カレンダー予定 (タスクとは独立。 AI 整理の対象外)。
///
/// source: 'manual' = 手動作成 / 'calendar_sync' = iOS カレンダー同期
@freezed
class Event with _$Event {
  const Event._();

  const factory Event({
    int? id,
    required String title,
    required DateTime date,
    String? startTime, // "HH:mm" 形式
    String? endTime, // "HH:mm" 形式
    @Default(true) bool isAllDay,
    String? memo,
    @Default('manual') String source,
    String? externalId,
    required DateTime createdAt,
  }) = _Event;

  factory Event.fromJson(Map<String, dynamic> json) => _$EventFromJson(json);

  static Event fromMap(Map<String, dynamic> map) => Event(
        id: map['id'] as int?,
        title: map['title'] as String,
        date: DateTime.parse(map['date'] as String),
        startTime: map['start_time'] as String?,
        endTime: map['end_time'] as String?,
        isAllDay: (map['is_all_day'] as int? ?? 1) == 1,
        memo: map['memo'] as String?,
        source: map['source'] as String? ?? 'manual',
        externalId: map['external_id'] as String?,
        createdAt: DateTime.parse(map['created_at'] as String),
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'title': title,
        'date': app_date.formatDateForDb(date),
        'start_time': startTime,
        'end_time': endTime,
        'is_all_day': isAllDay ? 1 : 0,
        'memo': memo,
        'source': source,
        'external_id': externalId,
        'created_at': createdAt.toIso8601String(),
      };

  /// 「14:00〜16:00」 「終日」 等の表示用文字列。
  String timeRangeLabel({String allDayLabel = '終日'}) {
    if (isAllDay) return allDayLabel;
    if (startTime == null) return '';
    if (endTime == null || endTime!.isEmpty) return '$startTime〜';
    return '$startTime〜$endTime';
  }
}
