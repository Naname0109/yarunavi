import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/user_badge.dart';
import '../../models/user_stats.dart';
import '../../providers/gamification_provider.dart';
import '../../providers/settings_provider.dart' show daysSinceFirstLaunchProvider;
import '../../providers/task_provider.dart' show completedTaskCountProvider;
import '../../services/database_service.dart';
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
class V2StatsScreen extends ConsumerStatefulWidget {
  const V2StatsScreen({super.key, this.isActive = true});

  /// 親が `IndexedStack` で全タブを mount するため、 タブが実際に
  /// 見えているかを受け取り、 初回チュートリアルダイアログをここで制御する。
  /// 見えていない (= 他タブ表示中) ときに表示してしまうと、 オンボーディング
  /// 完了直後の TaskFormSheet 等と重なる不具合になる。
  final bool isActive;

  @override
  ConsumerState<V2StatsScreen> createState() => _V2StatsScreenState();
}

class _V2StatsScreenState extends ConsumerState<V2StatsScreen> {
  static const _kTutorialShownKey = 'stats_tutorial_shown';
  bool _tutorialChecked = false;

  @override
  void initState() {
    super.initState();
    if (widget.isActive) _maybeShowTutorial();
  }

  @override
  void didUpdateWidget(V2StatsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 他タブ → 統計タブへ切替時にチュートリアルを表示
    if (!oldWidget.isActive && widget.isActive) _maybeShowTutorial();
  }

  Future<void> _maybeShowTutorial() async {
    if (_tutorialChecked) return;
    _tutorialChecked = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(_kTutorialShownKey) ?? false) return;
      if (!mounted) return;
      await prefs.setBool(_kTutorialShownKey, true);
      if (!mounted) return;
      await _showTutorialDialog();
    });
  }

  Future<void> _showTutorialDialog() async {
    final l10n = AppLocalizations.of(context)!;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(Icons.emoji_events_rounded,
            size: 36, color: Theme.of(ctx).colorScheme.primary),
        title: Text(l10n.statsTutorialTitle),
        content: Text(l10n.statsTutorialBody),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.statsTutorialCta),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                  l10n.statsTitleHeader,
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
                const SizedBox(height: 4),
                // #1-A: 「やるナビを使い始めて N 日目」
                Consumer(builder: (_, ref, __) {
                  final daysAsync = ref.watch(daysSinceFirstLaunchProvider);
                  final days = daysAsync.valueOrNull;
                  if (days == null) return const SizedBox.shrink();
                  return Text(
                    l10n.statsUsageDays(days),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: yaru.inkSecondary,
                    ),
                  );
                }),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _showGamificationHelp(context, yaru, l10n),
            tooltip: l10n.statsHelpTooltip,
            icon: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: yaru.paper,
                shape: BoxShape.circle,
                border: Border.all(color: yaru.line),
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.help_outline_rounded,
                size: 18,
                color: yaru.inkSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// ゲーミフィケーション仕様の説明シート (XP/Lv/ストリーク/バッジ)。
  void _showGamificationHelp(
    BuildContext context,
    YaruTheme yaru,
    AppLocalizations l10n,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: yaru.paper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: yaru.lineStrong,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.gamificationHelpTitle,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: yaru.inkPrimary,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.gamificationHelpSubtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: yaru.inkTertiary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // #9: Material Icons + 改訂テキスト (絵文字は使わない)
                  _helpRow(
                    yaru,
                    Icons.bolt_rounded,
                    Theme.of(ctx).colorScheme.primary,
                    l10n.gamificationHelpXpTitle,
                    l10n.gamificationHelpXpBody,
                  ),
                  const SizedBox(height: 14),
                  _helpRow(
                    yaru,
                    Icons.local_fire_department_rounded,
                    Colors.amber.shade700,
                    l10n.gamificationHelpStreakTitle,
                    l10n.gamificationHelpStreakBody,
                  ),
                  const SizedBox(height: 14),
                  _helpRow(
                    yaru,
                    Icons.star_rounded,
                    Theme.of(ctx).colorScheme.primary,
                    l10n.gamificationHelpLevelTitle,
                    l10n.gamificationHelpLevelBody,
                  ),
                  const SizedBox(height: 14),
                  _helpRow(
                    yaru,
                    Icons.emoji_events_rounded,
                    Colors.amber.shade700,
                    l10n.gamificationHelpBadgeTitle,
                    l10n.gamificationHelpBadgeBody,
                  ),
                  const SizedBox(height: 20),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton.tonal(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: Text(l10n.cancel),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _helpRow(YaruTheme yaru, IconData icon, Color iconColor,
      String title, String body) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: yaru.accent.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: yaru.accent.withValues(alpha: 0.25)),
          ),
          child: Icon(icon, size: 24, color: iconColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: yaru.inkPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                body,
                style: TextStyle(
                  fontSize: 13,
                  color: yaru.inkSecondary,
                  height: 1.55,
                ),
              ),
            ],
          ),
        ),
      ],
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
            value: l10n.statsValueTasks(completed),
            sub: l10n.statsSubTasks,
            color: YaruColors.cyan,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _statTile(
            label: l10n.statsWeek,
            value: l10n.statsValueTasks(thisWeek),
            sub: l10n.statsSubTasks,
            color: YaruColors.lime,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _statTile(
            label: l10n.statsLongest,
            value: l10n.statsValueDays(stats.longestStreak),
            sub: l10n.statsSubStreak,
            color: YaruColors.amber,
          ),
        ),
      ],
    );
  }

  Widget _statTile({
    required String label,
    required String value,
    required String sub,
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
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: color,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: yaru.inkPrimary,
                    height: 1.1,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  sub,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: yaru.inkTertiary,
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
                const SizedBox(height: 6),
                // #5: 次レベル名 + 残 XP
                Text(
                  l10n.statsNextLevelLabel(
                    stats.currentLevel + 1,
                    _localizedLevelName(l10n, stats.currentLevel + 1),
                  ),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: yaru.inkSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.statsNextLevelXp(nextXp - stats.totalXp),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: yaru.accent,
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
    final earned = badges.where((b) => b.isEarned).toList()
      ..sort((a, b) => a.id.compareTo(b.id));
    final unearnedVisible = badges
        .where((b) => !b.isEarned && !b.isHidden)
        .toList()
      ..sort((a, b) => a.id.compareTo(b.id));
    final unearnedHidden = badges
        .where((b) => !b.isEarned && b.isHidden)
        .toList()
      ..sort((a, b) => a.id.compareTo(b.id));
    final earnedCount = earned.length;
    final total = badges.length;
    final pct = total == 0 ? 0 : ((earnedCount / total) * 100).round();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                Icon(Icons.emoji_events_outlined,
                    size: 16, color: yaru.inkSecondary),
                const SizedBox(width: 6),
                Text(
                  l10n.statsBadgesEarnedCount(earnedCount, total),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: yaru.inkSecondary,
                    letterSpacing: 0.4,
                  ),
                ),
                const Spacer(),
                Text(
                  '$pct%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: yaru.inkTertiary,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: total == 0 ? 0 : earnedCount / total,
                minHeight: 6,
                backgroundColor: yaru.line,
                valueColor: AlwaysStoppedAnimation(yaru.accent),
              ),
            ),
          ),
          if (earned.isNotEmpty) ...[
            const SizedBox(height: 16),
            _BadgeSectionHeader(label: l10n.statsBadgesEarnedSection),
            const SizedBox(height: 8),
            _badgeGridChunk(earned),
          ],
          if (unearnedVisible.isNotEmpty) ...[
            const SizedBox(height: 16),
            _BadgeSectionHeader(label: l10n.statsBadgesLockedSection),
            const SizedBox(height: 8),
            _badgeGridChunk(unearnedVisible),
          ],
          if (unearnedHidden.isNotEmpty) ...[
            const SizedBox(height: 16),
            _BadgeSectionHeader(
              label: l10n.statsBadgesHiddenSection(unearnedHidden.length),
            ),
            const SizedBox(height: 8),
            _badgeGridChunk(unearnedHidden),
          ],
        ],
      ),
    );
  }

  Widget _badgeGridChunk(List<UserBadge> items) {
    // #1-C: 未獲得バッジには条件テキスト 2 行が入るため少し縦長に
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 0.88,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      children:
          items.map((b) => _BadgeTile(badge: b)).toList(growable: false),
    );
  }
}

/// #5: バッジセクション区切り (獲得済み / 未獲得 / 隠し)
class _BadgeSectionHeader extends StatelessWidget {
  const _BadgeSectionHeader({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 14,
            decoration: BoxDecoration(
              color: cs.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: cs.onSurfaceVariant,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 1,
              color: cs.outlineVariant.withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _BadgeTile extends ConsumerWidget {
  const _BadgeTile({required this.badge});
  final UserBadge badge;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final yaru = context.yaru;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    final earned = badge.isEarned;

    // 隠しバッジ未獲得時は名前・条件を「???」 で伏せる (#5)
    final concealed = badge.isHidden && !earned;
    final displayIcon = concealed ? Icons.help_outline_rounded : badge.icon;
    // #1-C: 獲得済み=名前、 未獲得 (表)=達成条件、 隠し=???
    final displayName = concealed
        ? l10n.badgeHidden
        : (earned
            ? _localizedBadgeName(l10n, badge.id)
            : _localizedBadgeCondition(l10n, badge.id));

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _showBadgeDetail(context, ref, badge),
        child: GlassCard(
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
                      Icon(
                        displayIcon,
                        size: 32,
                        color: earned
                            ? Theme.of(context).colorScheme.primary
                            : yaru.inkTertiary,
                        shadows: earned && isDark
                            ? [
                                Shadow(
                                  color: yaru.accent.withValues(alpha: 0.6),
                                  blurRadius: 8,
                                ),
                              ]
                            : null,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        displayName,
                        style: TextStyle(
                          fontSize: 9.5,
                          // 獲得済みは太字、 未獲得は通常字
                          fontWeight: earned ? FontWeight.w800 : FontWeight.w600,
                          color: earned ? yaru.inkSecondary : yaru.inkQuaternary,
                          height: 1.2,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
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
                    concealed
                        ? Icons.visibility_off_rounded
                        : Icons.lock_rounded,
                    size: 12,
                    color: yaru.inkQuaternary,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// #4: バッジ詳細ダイアログ。 獲得済み/未獲得/隠しバッジで内容を切り替え。
Future<void> _showBadgeDetail(
    BuildContext context, WidgetRef ref, UserBadge badge) async {
  final l10n = AppLocalizations.of(context)!;
  final concealed = badge.isHidden && !badge.isEarned;
  final stats = ref.read(userStatsProvider).valueOrNull;
  final progress = concealed ? null : _badgeProgress(badge.id, stats);
  final xpReward = DatabaseService.kBadgeXpReward[badge.id] ?? 0;
  await showDialog<void>(
    context: context,
    builder: (ctx) {
      final theme = Theme.of(ctx);
      final cs = theme.colorScheme;
      final name = concealed
          ? l10n.badgeHidden
          : _localizedBadgeName(l10n, badge.id);
      final cond = concealed
          ? l10n.badgeHiddenCondition
          : _localizedBadgeCondition(l10n, badge.id);
      return AlertDialog(
        icon: Icon(
          concealed ? Icons.help_outline_rounded : badge.icon,
          size: 44,
          color: badge.isEarned ? cs.primary : cs.onSurfaceVariant,
        ),
        title: Text(
          name,
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _DetailRow(
              label: l10n.badgeDetailCondition,
              value: cond,
            ),
            if (badge.isEarned && badge.earnedAt != null) ...[
              const SizedBox(height: 8),
              _DetailRow(
                label: l10n.badgeDetailEarnedAt,
                value: DateFormat.yMd(
                        Localizations.localeOf(ctx).toLanguageTag())
                    .format(badge.earnedAt!),
              ),
            ],
            if (!badge.isEarned && progress != null) ...[
              const SizedBox(height: 8),
              _DetailRow(
                label: l10n.badgeDetailProgress,
                value: l10n.badgeDetailProgressValue(
                    progress.$1, progress.$2),
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (progress.$1 / progress.$2).clamp(0.0, 1.0),
                  minHeight: 6,
                  backgroundColor: cs.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation(cs.primary),
                ),
              ),
            ],
            if (xpReward > 0) ...[
              const SizedBox(height: 8),
              _DetailRow(
                label: l10n.badgeDetailXp,
                value: l10n.badgeDetailXpValue(xpReward),
              ),
            ],
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.cancel),
          ),
        ],
      );
    },
  );
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }
}

/// 未獲得 (表) バッジで current/target を返す。 計算不能なら null。
(int, int)? _badgeProgress(String id, dynamic stats) {
  if (stats == null) return null;
  return switch (id) {
    'first_step' => (stats.totalTasksCompleted.clamp(0, 1) as int, 1),
    'task_10' => (stats.totalTasksCompleted as int, 10),
    'task_25' => (stats.totalTasksCompleted as int, 25),
    'task_50' => (stats.totalTasksCompleted as int, 50),
    'task_100' => (stats.totalTasksCompleted as int, 100),
    'task_250' => (stats.totalTasksCompleted as int, 250),
    'task_500' => (stats.totalTasksCompleted as int, 500),
    'task_1000' => (stats.totalTasksCompleted as int, 1000),
    'streak_3' => (stats.streakDays as int, 3),
    'streak_7' => (stats.streakDays as int, 7),
    'streak_14' => (stats.streakDays as int, 14),
    'streak_30' => (stats.streakDays as int, 30),
    'streak_60' => (stats.streakDays as int, 60),
    'streak_100' => (stats.streakDays as int, 100),
    'ai_first' => (stats.totalAiSorts.clamp(0, 1) as int, 1),
    'ai_10' => (stats.totalAiSorts as int, 10),
    'ai_50' => (stats.totalAiSorts as int, 50),
    'level_5' => (stats.currentLevel as int, 5),
    'level_10' => (stats.currentLevel as int, 10),
    'level_20' => (stats.currentLevel as int, 20),
    'level_30' => (stats.currentLevel as int, 30),
    _ => null,
  };
}

String _localizedBadgeCondition(AppLocalizations l10n, String id) {
  return switch (id) {
    'first_step' => l10n.badgeCond_first_step,
    'task_10' => l10n.badgeCond_task_10,
    'task_25' => l10n.badgeCond_task_25,
    'task_50' => l10n.badgeCond_task_50,
    'task_100' => l10n.badgeCond_task_100,
    'task_250' => l10n.badgeCond_task_250,
    'task_500' => l10n.badgeCond_task_500,
    'task_1000' => l10n.badgeCond_task_1000,
    'streak_3' => l10n.badgeCond_streak_3,
    'streak_7' => l10n.badgeCond_streak_7,
    'streak_14' => l10n.badgeCond_streak_14,
    'streak_30' => l10n.badgeCond_streak_30,
    'streak_60' => l10n.badgeCond_streak_60,
    'streak_100' => l10n.badgeCond_streak_100,
    'ai_first' => l10n.badgeCond_ai_first,
    'ai_10' => l10n.badgeCond_ai_10,
    'ai_50' => l10n.badgeCond_ai_50,
    'level_5' => l10n.badgeCond_level_5,
    'level_10' => l10n.badgeCond_level_10,
    'level_20' => l10n.badgeCond_level_20,
    'level_30' => l10n.badgeCond_level_30,
    'early_bird' => l10n.badgeCond_early_bird,
    'night_owl' => l10n.badgeCond_night_owl,
    'busy_day_5' => l10n.badgeCond_busy_day_5,
    'busy_day_10' => l10n.badgeCond_busy_day_10,
    'busy_month_30' => l10n.badgeCond_busy_month_30,
    'back_from_hibernation' => l10n.badgeCond_back_from_hibernation,
    'long_time_no_see' => l10n.badgeCond_long_time_no_see,
    'category_master' => l10n.badgeCond_category_master,
    'habit_demon' => l10n.badgeCond_habit_demon,
    'schedule_master' => l10n.badgeCond_schedule_master,
    'zero_overdue' => l10n.badgeCond_zero_overdue,
    'multi_tasker' => l10n.badgeCond_multi_tasker,
    'ticket_buyer' => l10n.badgeCond_ticket_buyer,
    'weekend_warrior' => l10n.badgeCond_weekend_warrior,
    'perfect_week' => l10n.badgeCond_perfect_week,
    'level_50' => l10n.badgeCond_level_50,
    'level_70' => l10n.badgeCond_level_70,
    'level_100' => l10n.badgeCond_level_100,
    _ => id,
  };
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
}
