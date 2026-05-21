// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_badge.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$UserBadgeImpl _$$UserBadgeImplFromJson(Map<String, dynamic> json) =>
    _$UserBadgeImpl(
      id: json['id'] as String,
      isEarned: json['isEarned'] as bool? ?? false,
      isHidden: json['isHidden'] as bool? ?? false,
      earnedAt: json['earnedAt'] == null
          ? null
          : DateTime.parse(json['earnedAt'] as String),
    );

Map<String, dynamic> _$$UserBadgeImplToJson(_$UserBadgeImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'isEarned': instance.isEarned,
      'isHidden': instance.isHidden,
      'earnedAt': instance.earnedAt?.toIso8601String(),
    };
