import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../models/user_badge.dart';
import '../../theme/yaru_colors.dart';
import '../../theme/yaru_theme.dart';

/// 新規バッジ獲得トースト (画面下中央)。
class BadgeUnlockPopup {
  BadgeUnlockPopup._();

  static OverlayEntry? _current;

  static void show(BuildContext context, UserBadge badge) {
    HapticFeedback.mediumImpact();
    _current?.remove();
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(builder: (_) {
      return _Popup(
        badge: badge,
        onDone: () {
          if (_current == entry) {
            entry.remove();
            _current = null;
          }
        },
      );
    });
    _current = entry;
    overlay.insert(entry);
  }
}

class _Popup extends StatefulWidget {
  const _Popup({required this.badge, required this.onDone});
  final UserBadge badge;
  final VoidCallback onDone;

  @override
  State<_Popup> createState() => _PopupState();
}

class _PopupState extends State<_Popup>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..forward();
    _ctrl.addStatusListener((status) {
      if (status == AnimationStatus.completed) widget.onDone();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final yaru = context.yaru;
    final l10n = AppLocalizations.of(context)!;
    final fadeIn = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0, 0.15, curve: Curves.easeOut),
    );
    final fadeOut = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.85, 1.0, curve: Curves.easeIn),
    );
    final slideUp = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0, 0.15, curve: Curves.easeOutBack),
    );

    return Positioned(
      left: 24,
      right: 24,
      bottom: MediaQuery.of(context).padding.bottom + 110,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, _) {
          final alpha = (fadeIn.value - fadeOut.value).clamp(0.0, 1.0);
          return Opacity(
            opacity: alpha,
            child: Transform.translate(
              offset: Offset(0, (1 - slideUp.value) * 40),
              child: GestureDetector(
                onTap: widget.onDone,
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      gradient: yaru.neonGradient,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: yaru.accent.withValues(alpha: 0.5),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                          spreadRadius: -4,
                        ),
                      ],
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: YaruColors.bgDark1,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            widget.badge.icon,
                            size: 30,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.badgeUnlocked,
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w800,
                                    color: YaruColors.cyan,
                                    letterSpacing: 1.4,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _badgeName(l10n, widget.badge.id),
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  _badgeDesc(l10n, widget.badge.id),
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: YaruColors.inkDark2,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.auto_awesome,
                            color: YaruColors.magenta,
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

String _badgeName(AppLocalizations l10n, String id) => switch (id) {
      // 表バッジ
      'first_step' => l10n.badgeName_first_step,
      'task_10' => l10n.badgeName_task_10,
      'task_25' => l10n.badgeName_task_25,
      'task_50' => l10n.badgeName_task_50,
      'task_100' => l10n.badgeName_task_100,
      'task_250' => l10n.badgeName_task_250,
      'task_500' => l10n.badgeName_task_500,
      'task_1000' => l10n.badgeName_task_1000,
      'streak_3' => l10n.badgeName_streak_3,
      'streak_7' => l10n.badgeName_streak_7,
      'streak_14' => l10n.badgeName_streak_14,
      'streak_30' => l10n.badgeName_streak_30,
      'streak_60' => l10n.badgeName_streak_60,
      'streak_100' => l10n.badgeName_streak_100,
      'ai_first' => l10n.badgeName_ai_first,
      'ai_10' => l10n.badgeName_ai_10,
      'ai_50' => l10n.badgeName_ai_50,
      'level_5' => l10n.badgeName_level_5,
      'level_10' => l10n.badgeName_level_10,
      'level_20' => l10n.badgeName_level_20,
      'level_30' => l10n.badgeName_level_30,
      // 隠しバッジ
      'early_bird' => l10n.badgeName_early_bird,
      'night_owl' => l10n.badgeName_night_owl,
      'busy_day_5' => l10n.badgeName_busy_day_5,
      'busy_day_10' => l10n.badgeName_busy_day_10,
      'busy_month_30' => l10n.badgeName_busy_month_30,
      'back_from_hibernation' => l10n.badgeName_back_from_hibernation,
      'long_time_no_see' => l10n.badgeName_long_time_no_see,
      'category_master' => l10n.badgeName_category_master,
      'habit_demon' => l10n.badgeName_habit_demon,
      'schedule_master' => l10n.badgeName_schedule_master,
      'zero_overdue' => l10n.badgeName_zero_overdue,
      'multi_tasker' => l10n.badgeName_multi_tasker,
      'ticket_buyer' => l10n.badgeName_ticket_buyer,
      'weekend_warrior' => l10n.badgeName_weekend_warrior,
      'perfect_week' => l10n.badgeName_perfect_week,
      'level_50' => l10n.badgeName_level_50,
      'level_70' => l10n.badgeName_level_70,
      'level_100' => l10n.badgeName_level_100,
      _ => id,
    };

String _badgeDesc(AppLocalizations l10n, String id) => switch (id) {
      'first_step' => l10n.badgeDesc_first_step,
      'task_10' => l10n.badgeDesc_task_10,
      'task_25' => l10n.badgeDesc_task_25,
      'task_50' => l10n.badgeDesc_task_50,
      'task_100' => l10n.badgeDesc_task_100,
      'task_250' => l10n.badgeDesc_task_250,
      'task_500' => l10n.badgeDesc_task_500,
      'task_1000' => l10n.badgeDesc_task_1000,
      'streak_3' => l10n.badgeDesc_streak_3,
      'streak_7' => l10n.badgeDesc_streak_7,
      'streak_14' => l10n.badgeDesc_streak_14,
      'streak_30' => l10n.badgeDesc_streak_30,
      'streak_60' => l10n.badgeDesc_streak_60,
      'streak_100' => l10n.badgeDesc_streak_100,
      'ai_first' => l10n.badgeDesc_ai_first,
      'ai_10' => l10n.badgeDesc_ai_10,
      'ai_50' => l10n.badgeDesc_ai_50,
      'level_5' => l10n.badgeDesc_level_5,
      'level_10' => l10n.badgeDesc_level_10,
      'level_20' => l10n.badgeDesc_level_20,
      'level_30' => l10n.badgeDesc_level_30,
      'early_bird' => l10n.badgeDesc_early_bird,
      'night_owl' => l10n.badgeDesc_night_owl,
      'busy_day_5' => l10n.badgeDesc_busy_day_5,
      'busy_day_10' => l10n.badgeDesc_busy_day_10,
      'busy_month_30' => l10n.badgeDesc_busy_month_30,
      'back_from_hibernation' => l10n.badgeDesc_back_from_hibernation,
      'long_time_no_see' => l10n.badgeDesc_long_time_no_see,
      'category_master' => l10n.badgeDesc_category_master,
      'habit_demon' => l10n.badgeDesc_habit_demon,
      'schedule_master' => l10n.badgeDesc_schedule_master,
      'zero_overdue' => l10n.badgeDesc_zero_overdue,
      'multi_tasker' => l10n.badgeDesc_multi_tasker,
      'ticket_buyer' => l10n.badgeDesc_ticket_buyer,
      'weekend_warrior' => l10n.badgeDesc_weekend_warrior,
      'perfect_week' => l10n.badgeDesc_perfect_week,
      'level_50' => l10n.badgeDesc_level_50,
      'level_70' => l10n.badgeDesc_level_70,
      'level_100' => l10n.badgeDesc_level_100,
      _ => '',
    };
