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
    DateTime? earnedAt,
  }) = _UserBadge;

  factory UserBadge.fromJson(Map<String, dynamic> json) =>
      _$UserBadgeFromJson(json);

  /// sqflite用: Map → UserBadge
  static UserBadge fromMap(Map<String, dynamic> map) => UserBadge(
        id: map['id'] as String,
        isEarned: (map['is_earned'] as int? ?? 0) == 1,
        earnedAt: map['earned_at'] != null
            ? DateTime.parse(map['earned_at'] as String)
            : null,
      );

  /// 名称i18nキー
  String get nameKey => 'badgeName_$id';

  /// 説明i18nキー
  String get descriptionKey => 'badgeDesc_$id';

  /// 絵文字アイコン（暫定。後でカスタムSVG/Painterへ差し替え可能）
  String get emoji => switch (id) {
        'first_step' => '🏁',
        'streak_3' || 'streak_7' || 'streak_14' || 'streak_30' => '🔥',
        'ai_first' => '✨',
        'task_10' || 'task_50' || 'task_100' => '📋',
        'level_5' || 'level_10' => '🏆',
        _ => '🎖️',
      };
}
