// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$TaskImpl _$$TaskImplFromJson(Map<String, dynamic> json) => _$TaskImpl(
  id: (json['id'] as num?)?.toInt(),
  title: json['title'] as String,
  dueDate: DateTime.parse(json['dueDate'] as String),
  memo: json['memo'] as String?,
  categoryId: (json['categoryId'] as num?)?.toInt(),
  isCompleted: json['isCompleted'] as bool? ?? false,
  completedAt: json['completedAt'] == null
      ? null
      : DateTime.parse(json['completedAt'] as String),
  priority: (json['priority'] as num?)?.toInt() ?? 0,
  aiComment: json['aiComment'] as String?,
  recurrenceType: json['recurrenceType'] as String?,
  recurrenceValue: (json['recurrenceValue'] as num?)?.toInt(),
  recurrenceParentId: (json['recurrenceParentId'] as num?)?.toInt(),
  notifySettings: json['notifySettings'] as String?,
  calendarEventId: json['calendarEventId'] as String?,
  estimatedTime: json['estimatedTime'] as String?,
  importance: (json['importance'] as num?)?.toInt() ?? 1,
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$$TaskImplToJson(_$TaskImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'dueDate': instance.dueDate.toIso8601String(),
      'memo': instance.memo,
      'categoryId': instance.categoryId,
      'isCompleted': instance.isCompleted,
      'completedAt': instance.completedAt?.toIso8601String(),
      'priority': instance.priority,
      'aiComment': instance.aiComment,
      'recurrenceType': instance.recurrenceType,
      'recurrenceValue': instance.recurrenceValue,
      'recurrenceParentId': instance.recurrenceParentId,
      'notifySettings': instance.notifySettings,
      'calendarEventId': instance.calendarEventId,
      'estimatedTime': instance.estimatedTime,
      'importance': instance.importance,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };
