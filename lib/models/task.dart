import 'package:freezed_annotation/freezed_annotation.dart';

import '../utils/date_utils.dart' as app_date;

part 'task.freezed.dart';
part 'task.g.dart';

@freezed
class Task with _$Task {
  const Task._();

  const factory Task({
    int? id,
    required String title,
    required DateTime dueDate,
    String? memo,
    int? categoryId,
    @Default(false) bool isCompleted,
    DateTime? completedAt,
    @Default(0) int priority,
    String? aiComment,
    String? recurrenceType,
    int? recurrenceValue,
    int? recurrenceParentId,
    String? notifySettings,
    String? calendarEventId,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _Task;

  factory Task.fromJson(Map<String, dynamic> json) => _$TaskFromJson(json);

  /// sqflite用: Map → Task
  static Task fromMap(Map<String, dynamic> map) => Task(
        id: map['id'] as int?,
        title: map['title'] as String,
        dueDate: DateTime.parse(map['due_date'] as String),
        memo: map['memo'] as String?,
        categoryId: map['category_id'] as int?,
        isCompleted: (map['is_completed'] as int) == 1,
        completedAt: map['completed_at'] != null
            ? DateTime.parse(map['completed_at'] as String)
            : null,
        priority: map['priority'] as int? ?? 0,
        aiComment: map['ai_comment'] as String?,
        recurrenceType: map['recurrence_type'] as String?,
        recurrenceValue: map['recurrence_value'] as int?,
        recurrenceParentId: map['recurrence_parent_id'] as int?,
        notifySettings: map['notify_settings'] as String?,
        calendarEventId: map['calendar_event_id'] as String?,
        createdAt: DateTime.parse(map['created_at'] as String),
        updatedAt: DateTime.parse(map['updated_at'] as String),
      );

  /// sqflite用: Task → Map（insert用、idを含む）
  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        ..._toMapWithoutId(),
      };

  /// sqflite用: Task → Map（update用、idを含まない）
  Map<String, dynamic> toMapForUpdate() => _toMapWithoutId();

  Map<String, dynamic> _toMapWithoutId() => {
        'title': title,
        'due_date': app_date.formatDateForDb(dueDate),
        'memo': memo,
        'category_id': categoryId,
        'is_completed': isCompleted ? 1 : 0,
        'completed_at': completedAt?.toIso8601String(),
        'priority': priority,
        'ai_comment': aiComment,
        'recurrence_type': recurrenceType,
        'recurrence_value': recurrenceValue,
        'recurrence_parent_id': recurrenceParentId,
        'notify_settings': notifySettings,
        'calendar_event_id': calendarEventId,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };
}
