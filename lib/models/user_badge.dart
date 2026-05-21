import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_badge.freezed.dart';
part 'user_badge.g.dart';

/// ユーザーが獲得可能なバッジ。
/// （Material widget の `Badge` と衝突を避けるため `UserBadge` と命名）
@freezed
class UserBadge with _$UserBadge {
  const UserBadge._();

  const factory UserBadge({
    required String id,
    @Default(false) bool isEarned,
    @Default(false) bool isHidden,
    DateTime? earnedAt,
  }) = _UserBadge;

  factory UserBadge.fromJson(Map<String, dynamic> json) =>
      _$UserBadgeFromJson(json);

  /// sqflite用: Map → UserBadge
  static UserBadge fromMap(Map<String, dynamic> map) => UserBadge(
        id: map['id'] as String,
        isEarned: (map['is_earned'] as int? ?? 0) == 1,
        isHidden: (map['is_hidden'] as int? ?? 0) == 1,
        earnedAt: map['earned_at'] != null
            ? DateTime.parse(map['earned_at'] as String)
            : null,
      );

  /// 名称i18nキー
  String get nameKey => 'badgeName_$id';

  /// 説明i18nキー
  String get descriptionKey => 'badgeDesc_$id';

  /// Material Icon code point。 隠しバッジ未獲得時は呼び出し側で
  /// help_outline 等を使い「???」表示にする。
  IconData get icon {
    switch (id) {
      case 'first_step':
        return Icons.flag;
      case 'task_10':
      case 'task_25':
      case 'task_50':
      case 'task_100':
      case 'task_250':
      case 'task_500':
      case 'task_1000':
        return Icons.checklist_rtl;
      case 'streak_3':
      case 'streak_7':
      case 'streak_14':
      case 'streak_30':
      case 'streak_60':
      case 'streak_100':
        return Icons.local_fire_department;
      case 'ai_first':
      case 'ai_10':
      case 'ai_50':
        return Icons.auto_awesome;
      case 'level_5':
      case 'level_10':
      case 'level_20':
      case 'level_30':
        return Icons.workspace_premium;
      case 'early_bird':
        return Icons.wb_twilight;
      case 'night_owl':
        return Icons.nights_stay;
      case 'busy_day_5':
      case 'busy_day_10':
        return Icons.bolt;
      case 'busy_month_30':
        return Icons.calendar_month;
      case 'back_from_hibernation':
      case 'long_time_no_see':
        return Icons.replay;
      case 'category_master':
        return Icons.category;
      case 'habit_demon':
        return Icons.repeat;
      case 'schedule_master':
        return Icons.event_available;
      case 'zero_overdue':
        return Icons.check_circle;
      case 'multi_tasker':
        return Icons.dynamic_feed;
      case 'ticket_buyer':
        return Icons.confirmation_number;
      case 'weekend_warrior':
        return Icons.beach_access;
      case 'perfect_week':
        return Icons.star;
      case 'level_50':
      case 'level_70':
      case 'level_100':
        return Icons.diamond;
      default:
        return Icons.emoji_events;
    }
  }
}
