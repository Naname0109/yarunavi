import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../models/user_badge.dart';
import '../../models/user_stats.dart';
import '../../providers/gamification_provider.dart';
import '../../providers/task_provider.dart' show completedTaskCountProvider;
import '../../services/gamification_service.dart';
import '../../theme/yaru_colors.dart';
import '../../theme/yaru_theme.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/progress_ring.dart';
import '../../widgets/responsive_wrapper.dart';
import '../../widgets/v2/heatmap_14days.dart';
import '../../widgets/v2/streak_card.dart';

/// v2 実績/ストリーク画面。
///
/// ストリーク炎カード + 統計タイル (Done/Week/Best) + 14日ヒートマップ + Lv/XP + バッジ
class V2StatsScreen extends ConsumerWidget {
  const V2StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final yaru = context.yaru;
    final l10n = AppLocalizations.of(context)!;
    final statsAsync = ref.watch(userStatsProvider);
    final badgesAsync = ref.watch(badgesProvider);
    final heatmapAsync = ref.watch(activityHeatmapProvider);
    final completedAsync = ref.watch(completedTaskCountProvider);

    return Scaffold(
      backgroundColor: yaru.scaffoldBg,
      body: SafeArea(
        bottom: false,
        child: ResponsiveWrapper(
          child: statsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('$e')),
            data: (stats) {
              // 完了済みタスク総数 (tasks テーブルから直接取得した値を優先、
              // 失敗時のフォールバックとして gamification の累計値を使用)
              final realCompleted = completedAsync.maybeWhen(
                data: (c) => c,
                orElse: () => stats.totalTasksCompleted,
              );
              // 今週の活動数 (xp_history のヒートマップから過去7日合計)
              final thisWeek = heatmapAsync.maybeWhen(
                data: (m) {
                  final now = DateTime.now();
                  int sum = 0;
                  for (int i = 0; i < 7; i++) {
                    final d = DateTime(now.year, now.month, now.day - i);
                    final key = '${d.year.toString().padLeft(4, '0')}-'
                        '${d.month.toString().padLeft(2, '0')}-'
                        '${d.day.toString().padLeft(2, '0')}';
                    sum += m[key] ?? 0;
                  }
                  return sum;
                },
                orElse: () => 0,
              );
              return ListView(
                padding: const EdgeInsets.only(top: 8, bottom: 120),
                children: [
                  _header(context, yaru, l10n, stats),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: StreakCard(stats: stats),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _statRow(l10n, realCompleted, thisWeek, stats),
                  ),
                  const SizedBox(height: 18),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: GlassCard(
                      borderRadius: 18,
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                l10n.statsPast14Days,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: yaru.inkSecondary,
                                ),
                              ),
                              const Spacer(),
                              heatmapAsync.maybeWhen(
                                data: (map) {
                                  final activeDays =
                                      map.values.where((c) => c > 0).length;
                                  final pct = (activeDays / 14 * 100).round();
                                  return Text(
                                    '$pct%',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w800,
                                      color: yaru.accent,
                                      fontFeatures: const [
                                        FontFeature.tabularFigures()
                                      ],
                                    ),
                                  );
                                },
                                orElse: () => const SizedBox.shrink(),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          heatmapAsync.when(
                            loading: () => const SizedBox(
                              height: 24,
                              child: Center(
                                child: SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
                            ),
                            error: (_, _) => const SizedBox.shrink(),
                            data: (map) => Heatmap14Days(activityByDay: map),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _levelCard(context, yaru, l10n, stats),
                  ),
                  const SizedBox(height: 18),
                  badgesAsync.maybeWhen(
                    data: (badges) => _badgesGrid(context, yaru, l10n, badges),
                    orElse: () => const SizedBox.shrink(),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _header(
    BuildContext context,
    YaruTheme yaru,
    AppLocalizations l10n,
    UserStats stats,
  ) {
    final levelName =
        _localizedLevelName(l10n, stats.currentLevel);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PROFILE · LV.${stats.currentLevel}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: yaru.inkTertiary,
                    letterSpacing: 1.4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  levelName,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: yaru.inkPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: yaru.paper,
              shape: BoxShape.circle,
              border: Border.all(color: yaru.line),
            ),
            child: Icon(
              Icons.emoji_events_rounded,
              size: 20,
              color: YaruColors.amber,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statRow(
    AppLocalizations l10n,
    int completed,
    int thisWeek,
    UserStats stats,
  ) {
    return Row(
      children: [
        Expanded(
          child: _statTile(
            label: l10n.statsDone,
            value: '$completed',
            color: YaruColors.cyan,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _statTile(
            label: l10n.statsWeek,
            value: '$thisWeek',
            color: YaruColors.lime,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _statTile(
            label: l10n.statsLongest,
            value: '${stats.longestStreak}',
            color: YaruColors.amber,
          ),
        ),
      ],
    );
  }

  Widget _statTile({
    required String label,
    required String value,
    required Color color,
  }) {
    return Builder(builder: (context) {
      final yaru = context.yaru;
      return GlassCard(
        borderRadius: 14,
        padding: const EdgeInsets.all(12),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: color,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: yaru.inkPrimary,
                    height: 1,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  boxShadow: yaru.useGlassBlur
                      ? [BoxShadow(color: color.withValues(alpha: 0.6), blurRadius: 6)]
                      : null,
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _levelCard(
    BuildContext context,
    YaruTheme yaru,
    AppLocalizations l10n,
    UserStats stats,
  ) {
    final progress = GamificationService.levelProgress(stats.totalXp);
    final startXp = GamificationService.currentLevelStartXp(stats.totalXp);
    final nextXp = GamificationService.xpForLevel(stats.currentLevel + 1);
    final levelName = _localizedLevelName(l10n, stats.currentLevel);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GlassCard(
      borderRadius: 18,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          ProgressRing(
            value: progress,
            size: 56,
            strokeWidth: 5,
            gradient: yaru.neonGradient,
            trackColor: yaru.line,
            center: Text(
              '${stats.currentLevel}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: yaru.inkPrimary,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'LEVEL ${stats.currentLevel} · $levelName',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: yaru.inkSecondary,
                    letterSpacing: 1.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: SizedBox(
                    height: 6,
                    child: Stack(
                      children: [
                        Container(color: yaru.line),
                        FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: progress.clamp(0.0, 1.0),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: yaru.neonGradient,
                              boxShadow: isDark
                                  ? [
                                      BoxShadow(
                                        color: YaruColors.magenta
                                            .withValues(alpha: 0.5),
                                        blurRadius: 8,
                                      ),
                                    ]
                                  : null,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.statsLevelXp(stats.totalXp - startXp, nextXp - startXp),
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: yaru.inkTertiary,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _badgesGrid(
    BuildContext context,
    YaruTheme yaru,
    AppLocalizations l10n,
    List<UserBadge> badges,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              l10n.statsBadges,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: yaru.inkSecondary,
                letterSpacing: 0.4,
              ),
            ),
          ),
          const SizedBox(height: 10),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.0,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            children: badges
                .map((b) => _BadgeTile(badge: b))
                .toList(growable: false),
          ),
        ],
      ),
    );
  }
}

class _BadgeTile extends StatelessWidget {
  const _BadgeTile({required this.badge});
  final UserBadge badge;

  @override
  Widget build(BuildContext context) {
    final yaru = context.yaru;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    final earned = badge.isEarned;

    return GlassCard(
      borderRadius: 14,
      padding: const EdgeInsets.all(10),
      child: Stack(
        children: [
          Center(
            child: Opacity(
              opacity: earned ? 1 : 0.35,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    badge.emoji,
                    style: TextStyle(
                      fontSize: 32,
                      shadows: earned && isDark
                          ? [
                              Shadow(
                                color: yaru.accent.withValues(alpha: 0.6),
                                blurRadius: 8,
                              ),
                            ]
                          : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _localizedBadgeName(l10n, badge.id),
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      color: earned ? yaru.inkSecondary : yaru.inkQuaternary,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
          if (!earned)
            Positioned(
              top: 4,
              right: 4,
              child: Icon(
                Icons.lock_rounded,
                size: 12,
                color: yaru.inkQuaternary,
              ),
            ),
        ],
      ),
    );
  }
}

String _localizedLevelName(AppLocalizations l10n, int level) {
  return switch (level) {
    1 => l10n.levelName1,
    2 => l10n.levelName2,
    3 => l10n.levelName3,
    4 => l10n.levelName4,
    5 => l10n.levelName5,
    6 => l10n.levelName6,
    7 => l10n.levelName7,
    8 => l10n.levelName8,
    _ => l10n.levelNameHigh(level),
  };
}

String _localizedBadgeName(AppLocalizations l10n, String id) {
  return switch (id) {
    'first_step' => l10n.badgeName_first_step,
    'streak_3' => l10n.badgeName_streak_3,
    'streak_7' => l10n.badgeName_streak_7,
    'streak_14' => l10n.badgeName_streak_14,
    'streak_30' => l10n.badgeName_streak_30,
    'ai_first' => l10n.badgeName_ai_first,
    'task_10' => l10n.badgeName_task_10,
    'task_50' => l10n.badgeName_task_50,
    'task_100' => l10n.badgeName_task_100,
    'level_5' => l10n.badgeName_level_5,
    'level_10' => l10n.badgeName_level_10,
    _ => id,
  };
}
