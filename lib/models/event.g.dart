// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'event.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$EventImpl _$$EventImplFromJson(Map<String, dynamic> json) => _$EventImpl(
  id: (json['id'] as num?)?.toInt(),
  title: json['title'] as String,
  date: DateTime.parse(json['date'] as String),
  startTime: json['startTime'] as String?,
  endTime: json['endTime'] as String?,
  isAllDay: json['isAllDay'] as bool? ?? true,
  memo: json['memo'] as String?,
  source: json['source'] as String? ?? 'manual',
  externalId: json['externalId'] as String?,
  createdAt: DateTime.parse(json['createdAt'] as String),
);

Map<String, dynamic> _$$EventImplToJson(_$EventImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'date': instance.date.toIso8601String(),
      'startTime': instance.startTime,
      'endTime': instance.endTime,
      'isAllDay': instance.isAllDay,
      'memo': instance.memo,
      'source': instance.source,
      'externalId': instance.externalId,
      'createdAt': instance.createdAt.toIso8601String(),
    };
