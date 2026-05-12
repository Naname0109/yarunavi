// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_stats.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$UserStatsImpl _$$UserStatsImplFromJson(Map<String, dynamic> json) =>
    _$UserStatsImpl(
      totalXp: (json['totalXp'] as num?)?.toInt() ?? 0,
      currentLevel: (json['currentLevel'] as num?)?.toInt() ?? 1,
      streakDays: (json['streakDays'] as num?)?.toInt() ?? 0,
      streakLastDate: json['streakLastDate'] == null
          ? null
          : DateTime.parse(json['streakLastDate'] as String),
      longestStreak: (json['longestStreak'] as num?)?.toInt() ?? 0,
      totalTasksCompleted: (json['totalTasksCompleted'] as num?)?.toInt() ?? 0,
      totalAiSorts: (json['totalAiSorts'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$$UserStatsImplToJson(_$UserStatsImpl instance) =>
    <String, dynamic>{
      'totalXp': instance.totalXp,
      'currentLevel': instance.currentLevel,
      'streakDays': instance.streakDays,
      'streakLastDate': instance.streakLastDate?.toIso8601String(),
      'longestStreak': instance.longestStreak,
      'totalTasksCompleted': instance.totalTasksCompleted,
      'totalAiSorts': instance.totalAiSorts,
      'createdAt': instance.createdAt.toIso8601String(),
    };
