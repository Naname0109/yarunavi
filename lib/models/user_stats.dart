import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_stats.freezed.dart';
part 'user_stats.g.dart';

/// ユーザーの統計情報（XP、レベル、ストリーク、累計）
@freezed
class UserStats with _$UserStats {
  const UserStats._();

  const factory UserStats({
    @Default(0) int totalXp,
    @Default(1) int currentLevel,
    @Default(0) int streakDays,
    DateTime? streakLastDate,
    @Default(0) int longestStreak,
    @Default(0) int totalTasksCompleted,
    @Default(0) int totalAiSorts,
    required DateTime createdAt,
  }) = _UserStats;

  factory UserStats.fromJson(Map<String, dynamic> json) =>
      _$UserStatsFromJson(json);

  /// sqflite用: Map → UserStats
  static UserStats fromMap(Map<String, dynamic> map) => UserStats(
        totalXp: map['total_xp'] as int? ?? 0,
        currentLevel: map['current_level'] as int? ?? 1,
        streakDays: map['streak_days'] as int? ?? 0,
        streakLastDate: map['streak_last_date'] != null
            ? DateTime.parse(map['streak_last_date'] as String)
            : null,
        longestStreak: map['longest_streak'] as int? ?? 0,
        totalTasksCompleted: map['total_tasks_completed'] as int? ?? 0,
        totalAiSorts: map['total_ai_sorts'] as int? ?? 0,
        createdAt: DateTime.parse(map['created_at'] as String),
      );
}
