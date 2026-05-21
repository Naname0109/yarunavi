import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../providers/gamification_provider.dart';
import '../../providers/secure_storage_provider.dart';
import '../../services/gamification_service.dart';
import '../../theme/yaru_colors.dart';
import '../../theme/yaru_theme.dart';
import '../ai_sort_button.dart';
import '../progress_ring.dart';

/// ホーム画面のヒーローカード。
///
/// - ライト: electric blue グラデ + 白CTA
/// - ダーク: 暗いガラス + ネオンメッシュ + ネオンリング + ネオンCTA
/// 表示要素: TODAY / ストリーク / レベル / 今日の進捗 (N/M) / リング / AI整理CTA
///
/// タスク0件のときは「タスクを追加」促し文に切り替え、`onAddTask` を CTA から呼ぶ。
class HeroAiCard extends ConsumerWidget {
  const HeroAiCard({
    super.key,
    required this.todayDone,
    required this.todayTotal,
    this.onAddTask,
  });

  final int todayDone;
  final int todayTotal;

  /// タスク0件時のCTA「タスクを追加」を押したときに呼ばれる。
  /// 通常は TaskFormSheet.show を渡す。
  final VoidCallback? onAddTask;

  bool get _isEmpty => todayTotal == 0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final yaru = context.yaru;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    final statsAsync = ref.watch(userStatsProvider);
    final quotaAsync = ref.watch(aiSortQuotaProvider);

    final mission = _isEmpty ? 0.0 : todayDone / todayTotal;
    final streak = statsAsync.maybeWhen(data: (s) => s.streakDays, orElse: () => 0);
    final level = statsAsync.maybeWhen(data: (s) => s.currentLevel, orElse: () => 1);
    final totalXp = statsAsync.maybeWhen(data: (s) => s.totalXp, orElse: () => 0);
    final xpToNext = GamificationService.xpToNextLevel(totalXp);
    final levelProgress = GamificationService.levelProgress(totalXp);
    final quota = quotaAsync.maybeWhen(data: (q) => q, orElse: () => null);

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: isDark ? null : yaru.heroGradient,
          color: isDark ? yaru.paperEmph : null,
          borderRadius: BorderRadius.circular(24),
          border: isDark ? Border.all(color: yaru.line) : null,
          boxShadow: yaru.heroShadow,
        ),
        child: Stack(
          children: [
            if (isDark) ..._darkMesh(),
            // iPadなど横長表示では情報密度を上げるため2カラム化
            LayoutBuilder(builder: (ctx, constraints) {
              final isWide = constraints.maxWidth > 600;
              if (isWide) {
                return _buildWideLayout(
                  l10n: l10n,
                  yaru: yaru,
                  isDark: isDark,
                  streak: streak,
                  level: level,
                  xpToNext: xpToNext,
                  levelProgress: levelProgress,
                  mission: mission,
                  quota: quota,
                );
              }
              return _buildCompactLayout(
                l10n: l10n,
                yaru: yaru,
                isDark: isDark,
                streak: streak,
                level: level,
                xpToNext: xpToNext,
                levelProgress: levelProgress,
                mission: mission,
                quota: quota,
              );
            }),
          ],
        ),
      ),
    );
  }

  /// iPhone等の縦長表示: 上から topRow / mission(or empty) / bar / CTA を縦並び
  Widget _buildCompactLayout({
    required AppLocalizations l10n,
    required YaruTheme yaru,
    required bool isDark,
    required int streak,
    required int level,
    required int xpToNext,
    required double levelProgress,
    required double mission,
    required ({int remaining, int total, bool isPremium})? quota,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _topRow(
          l10n: l10n,
          streak: streak,
          level: level,
          xpToNext: xpToNext,
          levelProgress: levelProgress,
          isDark: isDark,
        ),
        const SizedBox(height: 18),
        if (_isEmpty)
          _emptyRow(l10n: l10n, isDark: isDark)
        else
          _missionRow(
            l10n: l10n,
            yaru: yaru,
            isDark: isDark,
            mission: mission,
          ),
        const SizedBox(height: 14),
        if (!_isEmpty) ...[
          _missionBar(yaru: yaru, value: mission, isDark: isDark),
          const SizedBox(height: 16),
        ],
        _buildCta(l10n: l10n, yaru: yaru, isDark: isDark, quota: quota),
      ],
    );
  }

  /// iPad等の横長表示: 左に進捗/リング、右にCTA+ピル群を配置
  Widget _buildWideLayout({
    required AppLocalizations l10n,
    required YaruTheme yaru,
    required bool isDark,
    required int streak,
    required int level,
    required int xpToNext,
    required double levelProgress,
    required double mission,
    required ({int remaining, int total, bool isPremium})? quota,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _topRow(
                l10n: l10n,
                streak: streak,
                level: level,
                xpToNext: xpToNext,
                levelProgress: levelProgress,
                isDark: isDark,
              ),
              const SizedBox(height: 16),
              if (_isEmpty)
                _emptyRow(l10n: l10n, isDark: isDark)
              else
                _missionRow(
                  l10n: l10n,
                  yaru: yaru,
                  isDark: isDark,
                  mission: mission,
                ),
              if (!_isEmpty) ...[
                const SizedBox(height: 12),
                _missionBar(yaru: yaru, value: mission, isDark: isDark),
              ],
            ],
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          flex: 2,
          child: _buildCta(l10n: l10n, yaru: yaru, isDark: isDark, quota: quota),
        ),
      ],
    );
  }

  Widget _buildCta({
    required AppLocalizations l10n,
    required YaruTheme yaru,
    required bool isDark,
    required ({int remaining, int total, bool isPremium})? quota,
  }) {
    if (_isEmpty) {
      return _addTaskCta(
        label: l10n.addTask,
        onTap: onAddTask,
        isDark: isDark,
        yaru: yaru,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        AiSortButton(
          builder: (ctx, isLoading, onTap) => _aiCta(
            label: isLoading ? l10n.aiSorting : l10n.aiSortHeroCta,
            loading: isLoading,
            onTap: onTap,
            isDark: isDark,
            yaru: yaru,
          ),
        ),
        if (quota != null) ...[
          const SizedBox(height: 6),
          _quotaRow(l10n: l10n, quota: quota, isDark: isDark),
        ],
      ],
    );
  }

  /// CTA直下の残回数表示。 #4 改定:
  /// - VIP (remaining=-1): 「VIP 無制限」 + ★
  /// - プレミアム: 「今月 残り N/30回」
  /// - 無料: 「残り N回」 (free + ticket 合算)
  /// - 0 回: 赤テキスト
  Widget _quotaRow({
    required AppLocalizations l10n,
    required ({int remaining, int total, bool isPremium}) quota,
    required bool isDark,
  }) {
    final isVip = quota.isPremium && quota.total == 0 && quota.remaining < 0;
    final exhausted = quota.remaining == 0;
    final label = isVip
        ? l10n.aiSortQuotaVip
        : quota.isPremium
            ? l10n.aiSortQuotaPremium(quota.remaining, quota.total)
            : l10n.aiSortQuotaFreeShort(quota.remaining);
    final color = exhausted
        ? Colors.red.shade300
        : Colors.white.withValues(alpha: 0.7);
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isVip) ...[
            const Icon(Icons.star_rounded,
                size: 12, color: Colors.amberAccent),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
              fontFeatures: const [FontFeature.tabularFigures()],
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  /// 空状態: 数字の代わりに「タスクを追加して始めよう」促し文を表示。
  Widget _emptyRow({required AppLocalizations l10n, required bool isDark}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.add_task_rounded,
            color: Colors.white,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.emptyTodayMessage,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.emptyTaskMessage,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: Colors.white.withValues(alpha: 0.78),
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 空状態用CTA: AI整理ではなくタスク追加へ。
  Widget _addTaskCta({
    required String label,
    required VoidCallback? onTap,
    required bool isDark,
    required YaruTheme yaru,
  }) {
    final fg = isDark ? YaruColors.bgDark0 : YaruColors.primaryDeep;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 46,
          decoration: BoxDecoration(
            color: isDark ? null : Colors.white.withValues(alpha: 0.96),
            gradient: isDark ? yaru.primaryGradient : null,
            borderRadius: BorderRadius.circular(14),
            boxShadow: isDark ? yaru.ctaShadow : null,
          ),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add_rounded, size: 18, color: fg),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: fg,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _topRow({
    required AppLocalizations l10n,
    required int streak,
    required int level,
    required int xpToNext,
    required double levelProgress,
    required bool isDark,
  }) {
    return Row(
      children: [
        _pill(
          label: l10n.today,
          color: isDark ? YaruColors.cyan : Colors.white,
          bg: isDark
              ? YaruColors.cyan.withValues(alpha: 0.12)
              : Colors.white.withValues(alpha: 0.18),
          border: isDark ? YaruColors.cyan : null,
        ),
        const SizedBox(width: 8),
        if (streak > 0)
          _pill(
            icon: Icons.local_fire_department_rounded,
            label: '${streak}d',
            color: isDark ? YaruColors.amber : Colors.white,
            bg: isDark
                ? YaruColors.amber.withValues(alpha: 0.12)
                : Colors.white.withValues(alpha: 0.16),
          ),
        const Spacer(),
        // Lv表示 + 次レベルまでのXP (B-8): モチベ持続のため進捗を可視化
        _levelChip(
          level: level,
          xpToNext: xpToNext,
          progress: levelProgress,
          isDark: isDark,
        ),
      ],
    );
  }

  Widget _levelChip({
    required int level,
    required int xpToNext,
    required double progress,
    required bool isDark,
  }) {
    final accent = isDark ? YaruColors.cyan : Colors.white;
    final bg = isDark
        ? YaruColors.cyan.withValues(alpha: 0.12)
        : Colors.white.withValues(alpha: 0.18);
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 4, 10, 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: isDark ? Border.all(color: accent.withValues(alpha: 0.35)) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Lv.$level',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  color: accent,
                  letterSpacing: 0.4,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '+$xpToNext',
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  color: accent.withValues(alpha: 0.85),
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          // レベル内進捗のミニバー (40px幅)
          SizedBox(
            width: 50,
            height: 3,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                backgroundColor: accent.withValues(alpha: 0.18),
                valueColor: AlwaysStoppedAnimation(accent),
                minHeight: 3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _missionRow({
    required AppLocalizations l10n,
    required YaruTheme yaru,
    required bool isDark,
    required double mission,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.heroTodayMission,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.8),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              RichText(
                text: TextSpan(
                  style: const TextStyle(
                    fontSize: 56,
                    fontWeight: FontWeight.w800,
                    height: 1.0,
                    fontFeatures: [FontFeature.tabularFigures()],
                    color: Colors.white,
                    letterSpacing: -2,
                  ),
                  children: [
                    TextSpan(text: '$todayDone'),
                    TextSpan(
                      text: ' / $todayTotal',
                      style: TextStyle(
                        fontSize: 24,
                        color: Colors.white.withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        ProgressRing(
          value: mission,
          size: 72,
          strokeWidth: 7,
          gradient: isDark ? yaru.progressGradient : null,
          color: isDark ? null : Colors.white,
          trackColor: Colors.white.withValues(alpha: 0.2),
          center: Text(
            '${(mission * 100).round()}%',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ],
    );
  }

  Widget _missionBar({
    required YaruTheme yaru,
    required double value,
    required bool isDark,
  }) {
    return Container(
      height: isDark ? 4 : 6,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: value.clamp(0.0, 1.0),
          child: Container(
            decoration: BoxDecoration(
              gradient: isDark
                  ? yaru.progressGradient
                  : const LinearGradient(
                      colors: [Color(0xFF7DFFD1), Color(0xFFA6C6FF)],
                    ),
              boxShadow: isDark
                  ? [
                      BoxShadow(
                        color: YaruColors.cyan.withValues(alpha: 0.6),
                        blurRadius: 8,
                      ),
                    ]
                  : null,
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _darkMesh() {
    return [
      Positioned.fill(
        child: IgnorePointer(
          child: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(-0.6, -1),
                radius: 1.0,
                colors: [Color(0x4D4DF5FF), Colors.transparent],
              ),
            ),
          ),
        ),
      ),
      Positioned.fill(
        child: IgnorePointer(
          child: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(1, 1),
                radius: 1.0,
                colors: [Color(0x40FF4DDB), Colors.transparent],
              ),
            ),
          ),
        ),
      ),
      Positioned(
        top: 0,
        left: 0,
        right: 0,
        child: Container(
          height: 1,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Colors.transparent, YaruColors.cyan, Colors.transparent],
            ),
            boxShadow: [
              BoxShadow(
                color: YaruColors.cyan.withValues(alpha: 0.7),
                blurRadius: 8,
              ),
            ],
          ),
        ),
      ),
    ];
  }

  Widget _pill({
    IconData? icon,
    required String label,
    required Color color,
    required Color bg,
    Color? border,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: border != null
            ? Border.all(color: border.withValues(alpha: 0.35))
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: 0.6,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _aiCta({
    required String label,
    required bool loading,
    required VoidCallback? onTap,
    required bool isDark,
    required YaruTheme yaru,
  }) {
    final fg = isDark ? YaruColors.bgDark0 : YaruColors.primaryDeep;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 46,
          decoration: BoxDecoration(
            color: isDark ? null : Colors.white.withValues(alpha: 0.96),
            gradient: isDark ? yaru.primaryGradient : null,
            borderRadius: BorderRadius.circular(14),
            boxShadow: isDark ? yaru.ctaShadow : null,
          ),
          child: Center(
            child: loading
                ? SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      valueColor: AlwaysStoppedAnimation(fg),
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.auto_awesome, size: 16, color: fg),
                      const SizedBox(width: 8),
                      Text(
                        label,
                        style: TextStyle(
                          color: fg,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.chevron_right_rounded, size: 16, color: fg),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
