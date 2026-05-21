import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../models/user_stats.dart';
import '../../providers/gamification_provider.dart';
import '../../theme/yaru_colors.dart';
import '../../theme/yaru_theme.dart';

/// 実績画面の炎カード（連続日数）。カウントアップ演出 + 7日ミニバー付き。
class StreakCard extends ConsumerWidget {
  const StreakCard({super.key, required this.stats});
  final UserStats stats;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final yaru = context.yaru;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    final heatmap = ref.watch(activityHeatmapProvider).maybeWhen(
          data: (m) => m,
          orElse: () => const <String, int>{},
        );

    if (isDark) {
      return _darkVariant(yaru: yaru, l10n: l10n, heatmap: heatmap);
    }
    return _lightVariant(yaru: yaru, l10n: l10n, heatmap: heatmap);
  }

  Widget _lightVariant({
    required YaruTheme yaru,
    required AppLocalizations l10n,
    required Map<String, int> heatmap,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: yaru.streakGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: yaru.streakShadow,
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: -20,
            top: -10,
            child: Icon(
              Icons.local_fire_department_rounded,
              size: 180,
              color: Colors.white.withValues(alpha: 0.25),
            ),
          ),
          _content(
            textColor: Colors.white,
            l10n: l10n,
            accent: Colors.white,
            heatmap: heatmap,
            isDark: false,
          ),
        ],
      ),
    );
  }

  Widget _darkVariant({
    required YaruTheme yaru,
    required AppLocalizations l10n,
    required Map<String, int> heatmap,
  }) {
    return Container(
      padding: const EdgeInsets.all(1),
      decoration: BoxDecoration(
        gradient: yaru.streakGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: yaru.streakShadow,
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: YaruColors.bgDark1,
          borderRadius: BorderRadius.circular(23),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              right: -20,
              top: -10,
              child: Icon(
                Icons.local_fire_department_rounded,
                size: 180,
                color: YaruColors.amber.withValues(alpha: 0.15),
              ),
            ),
            _content(
              textColor: yaru.inkPrimary,
              l10n: l10n,
              accent: YaruColors.amber,
              heatmap: heatmap,
              isDark: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _content({
    required Color textColor,
    required Color accent,
    required AppLocalizations l10n,
    required Map<String, int> heatmap,
    required bool isDark,
  }) {
    final days = _last7Counts(heatmap);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.local_fire_department_rounded, size: 20, color: accent),
            const SizedBox(width: 8),
            Text(
              l10n.statsStreakActive,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: accent,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Builder(builder: (context) {
          final locale = Localizations.localeOf(context).languageCode;
          final suffix = locale == 'ja' ? '日' : ' days';
          return TweenAnimationBuilder<int>(
            tween: IntTween(begin: 0, end: stats.streakDays),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutCubic,
            builder: (_, value, _) {
              return RichText(
                text: TextSpan(
                  style: TextStyle(
                    fontSize: 64,
                    fontWeight: FontWeight.w800,
                    height: 1.0,
                    color: textColor,
                    fontFeatures: const [FontFeature.tabularFigures()],
                    letterSpacing: -2.5,
                  ),
                  children: [
                    TextSpan(text: '$value'),
                    TextSpan(
                      text: suffix,
                      style: TextStyle(fontSize: 22, color: accent),
                    ),
                  ],
                ),
              );
            },
          );
        }),
        const SizedBox(height: 6),
        Text(
          stats.streakDays == 0
              ? l10n.streakKickoffPrompt
              : '${l10n.statsLongest}: ${stats.longestStreak}',
          style: TextStyle(
            fontSize: 12,
            color: textColor.withValues(alpha: 0.85),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          l10n.streakLast7DaysLabel,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: textColor.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 6),
        _miniBars(days: days, isDark: isDark, textColor: textColor),
        const SizedBox(height: 12),
        // #5: 次の目標 (次のストリークバッジまで)
        Builder(builder: (context) {
          final next = _nextStreakMilestone(stats.streakDays);
          if (next == null) return const SizedBox.shrink();
          return Row(
            children: [
              Icon(Icons.flag_rounded,
                  size: 14, color: textColor.withValues(alpha: 0.8)),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  l10n.streakNextGoal(next, next - stats.streakDays),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: textColor.withValues(alpha: 0.9),
                  ),
                ),
              ),
            ],
          );
        }),
      ],
    );
  }

  int? _nextStreakMilestone(int current) {
    const milestones = [3, 7, 14, 30, 60, 100];
    for (final m in milestones) {
      if (current < m) return m;
    }
    return null;
  }

  Widget _miniBars({
    required List<int> days,
    required bool isDark,
    required Color textColor,
  }) {
    final maxV = days.fold<int>(0, (a, b) => a > b ? a : b);
    final now = DateTime.now();
    final locale = const ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    final weekLabels = List<String>.generate(7, (i) {
      final d = DateTime(now.year, now.month, now.day - 6 + i);
      return locale[d.weekday % 7];
    });
    return Column(
      children: [
        SizedBox(
          height: 28,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (final v in days) ...[
                Expanded(
                  child: _bar(v: v, max: maxV, isDark: isDark),
                ),
                const SizedBox(width: 4),
              ],
            ]..removeLast(),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            for (final w in weekLabels) ...[
              Expanded(
                child: Center(
                  child: Text(
                    w,
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      color: textColor.withValues(alpha: 0.6),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
            ],
          ]..removeLast(),
        ),
      ],
    );
  }

  Widget _bar({required int v, required int max, required bool isDark}) {
    final h = max == 0 ? 0.1 : (v / max).clamp(0.1, 1.0);
    return FractionallySizedBox(
      heightFactor: h,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [YaruColors.amber, YaruColors.urgentNeon],
          ),
          borderRadius: BorderRadius.circular(4),
          boxShadow: isDark && v > 0
              ? [
                  BoxShadow(
                    color: YaruColors.amber.withValues(alpha: 0.45),
                    blurRadius: 6,
                  ),
                ]
              : null,
        ),
      ),
    );
  }

  List<int> _last7Counts(Map<String, int> heatmap) {
    final now = DateTime.now();
    return List<int>.generate(7, (i) {
      final d = DateTime(now.year, now.month, now.day - 6 + i);
      final key = '${d.year.toString().padLeft(4, '0')}-'
          '${d.month.toString().padLeft(2, '0')}-'
          '${d.day.toString().padLeft(2, '0')}';
      return heatmap[key] ?? 0;
    });
  }
}
