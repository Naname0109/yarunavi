import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../providers/task_provider.dart';
import '../../services/ai_service.dart';
import '../../theme/yaru_colors.dart';
import '../../theme/yaru_theme.dart';
import '../../widgets/ai_sort_button.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/neon_button.dart';
import '../../widgets/responsive_wrapper.dart';
import '../../widgets/sparkle_badge.dart';

/// v2 AI整理結果画面: Conicオーブ + 番号付きバケット + AIアドバイス。
///
/// プレミアム自動セットアップ等の高度な機能は既存 [AiResultScreen] に残し、
/// 今回は redesigned UI でのプレビュー表示にフォーカス。
class V2AiResultScreen extends ConsumerWidget {
  const V2AiResultScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final yaru = context.yaru;
    final l10n = AppLocalizations.of(context)!;
    final response = ref.watch(aiSortResponseProvider);

    if (response == null) {
      return Scaffold(
        backgroundColor: yaru.scaffoldBg,
        body: Center(
          child: Text(l10n.aiSortNoTasks),
        ),
      );
    }

    return Scaffold(
      backgroundColor: yaru.scaffoldBg,
      body: SafeArea(
        child: ResponsiveWrapper(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _topBar(context, yaru),
              ),
              SliverToBoxAdapter(
                child: _hero(context, yaru, l10n, response),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                  child: _statStrip(context, yaru, l10n, response),
                ),
              ),
              if (response.summaryJa != null || response.summaryEn != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: _aiNote(context, yaru, l10n, response),
                  ),
                ),
              SliverToBoxAdapter(
                child: _buckets(context, yaru, l10n, response),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
                  child: _ctaRow(context, ref, l10n),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _topBar(BuildContext context, YaruTheme yaru) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              context.pop();
            },
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: yaru.paper,
                border: Border.all(color: yaru.line),
              ),
              child: Icon(Icons.chevron_left_rounded,
                  size: 18, color: yaru.inkSecondary),
            ),
          ),
          const Spacer(),
          Text(
            _now(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: yaru.inkTertiary,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _hero(
    BuildContext context,
    YaruTheme yaru,
    AppLocalizations l10n,
    AiSortResponse response,
  ) {
    final taskCount = response.tasks.length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        children: [
          _OrbBadge(),
          const SizedBox(height: 16),
          Text(
            'NAVI · OPTIMIZED',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: yaru.sparkle,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: yaru.inkPrimary,
                height: 1.2,
                letterSpacing: -0.5,
              ),
              children: [
                TextSpan(text: '$taskCount件を\n'),
                _gradSpan(
                    text: l10n.aiResultOptimized,
                    gradient: yaru.neonGradient),
              ],
            ),
          ),
        ],
      ),
    );
  }

  TextSpan _gradSpan({required String text, required Gradient gradient}) {
    return TextSpan(
      text: text,
      style: TextStyle(
        foreground: Paint()
          ..shader = gradient.createShader(const Rect.fromLTWH(0, 0, 300, 50)),
      ),
    );
  }

  Widget _statStrip(
    BuildContext context,
    YaruTheme yaru,
    AppLocalizations l10n,
    AiSortResponse response,
  ) {
    int now = 0, week = 0, later = 0;
    for (final t in response.tasks) {
      if (t.priority == 1) {
        now++;
      } else if (t.priority == 2) {
        week++;
      } else {
        later++;
      }
    }
    return Row(
      children: [
        Expanded(child: _statTile(yaru, l10n.aiResultNowLabel, now, yaru.urgent)),
        const SizedBox(width: 8),
        Expanded(child: _statTile(yaru, l10n.aiResultWeekLabel, week, yaru.soon)),
        const SizedBox(width: 8),
        Expanded(child: _statTile(yaru, l10n.aiResultLaterLabel, later, yaru.later)),
      ],
    );
  }

  Widget _statTile(YaruTheme yaru, String label, int value, Color color) {
    return GlassCard(
      padding: const EdgeInsets.all(12),
      borderRadius: 14,
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$value',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: color,
                  height: 1,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: color.withValues(alpha: 0.85),
                  letterSpacing: 0.5,
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
  }

  Widget _aiNote(
    BuildContext context,
    YaruTheme yaru,
    AppLocalizations l10n,
    AiSortResponse response,
  ) {
    final locale = Localizations.localeOf(context).languageCode;
    final summary = locale == 'ja'
        ? response.summaryJa ?? response.summaryEn
        : response.summaryEn ?? response.summaryJa;
    if (summary == null || summary.isEmpty) return const SizedBox.shrink();
    return GlassCard(
      padding: const EdgeInsets.all(14),
      borderRadius: 16,
      borderColor: yaru.sparkle.withValues(alpha: 0.25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SparkleBadge(size: 22, glow: false),
              const SizedBox(width: 8),
              Text(
                'NAVI のひとこと',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: yaru.sparkle,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            summary,
            style: TextStyle(
              fontSize: 13.5,
              color: yaru.inkPrimary,
              height: 1.7,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buckets(
    BuildContext context,
    YaruTheme yaru,
    AppLocalizations l10n,
    AiSortResponse response,
  ) {
    return Consumer(builder: (ctx, ref, _) {
      final tasksAsync = ref.watch(tasksProvider);
      final titleMap = tasksAsync.maybeWhen(
        data: (list) => {for (final t in list) if (t.id != null) t.id!: t.title},
        orElse: () => const <int, String>{},
      );
      final groups = <(String, Color, List<AiSortResult>)>[
        (l10n.aiResultNowLabel, yaru.urgent,
            response.tasks.where((t) => t.priority == 1).toList()),
        (l10n.aiResultWeekLabel, yaru.soon,
            response.tasks.where((t) => t.priority == 2).toList()),
        (l10n.aiResultLaterLabel, yaru.later,
            response.tasks.where((t) => t.priority >= 3).toList()),
      ];
      return Column(
        children: [
          for (final g in groups)
            if (g.$3.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                child: _bucket(context, yaru, g.$1, g.$2, g.$3, titleMap),
              ),
        ],
      );
    });
  }

  Widget _bucket(
    BuildContext context,
    YaruTheme yaru,
    String label,
    Color color,
    List<AiSortResult> items,
    Map<int, String> titleMap,
  ) {
    final locale = Localizations.localeOf(context).languageCode;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: yaru.useGlassBlur
                    ? [BoxShadow(color: color.withValues(alpha: 0.6), blurRadius: 6)]
                    : null,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: color,
                letterSpacing: 0.6,
              ),
            ),
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 12),
                height: 1,
                color: yaru.line,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        for (var i = 0; i < items.length; i++) ...[
          GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            borderRadius: 14,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: color.withValues(alpha: 0.35)),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${i + 1}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: color,
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
                        titleMap[items[i].taskId] ??
                            'Task #${items[i].taskId}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: yaru.inkPrimary,
                        ),
                      ),
                      Builder(builder: (_) {
                        final c = locale == 'ja'
                            ? items[i].commentJa ?? items[i].commentEn
                            : items[i].commentEn ?? items[i].commentJa;
                        if (c == null || c.isEmpty) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            c,
                            style: TextStyle(
                              fontSize: 11.5,
                              color: yaru.inkTertiary,
                              height: 1.5,
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (i < items.length - 1) const SizedBox(height: 8),
        ],
      ],
    );
  }

  Widget _ctaRow(BuildContext context, WidgetRef ref, AppLocalizations l10n) {
    return Row(
      children: [
        Expanded(
          flex: 1,
          child: NeonButtonSecondary(
            label: l10n.aiResultRetryCta,
            height: 50,
            onPressed: () => context.pop(),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 2,
          child: NeonButton(
            label: l10n.aiResultStartCta,
            icon: Icons.bolt_rounded,
            height: 50,
            onPressed: () {
              context.go('/home');
            },
          ),
        ),
      ],
    );
  }

  String _now() {
    final n = DateTime.now();
    return '${n.year}.${n.month.toString().padLeft(2, '0')}.${n.day.toString().padLeft(2, '0')} · '
        '${n.hour.toString().padLeft(2, '0')}:${n.minute.toString().padLeft(2, '0')}';
  }
}

class _OrbBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final yaru = context.yaru;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      width: 110,
      height: 110,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (isDark)
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: yaru.magentaGlow,
                ),
              ),
            ),
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: yaru.aiOrbGradient,
              boxShadow: isDark
                  ? const [
                      BoxShadow(
                        color: Color(0xB35B7BFF),
                        blurRadius: 50,
                        offset: Offset(0, 20),
                        spreadRadius: -10,
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark ? YaruColors.bgDark1 : Colors.white,
                ),
                child: Icon(
                  Icons.auto_awesome,
                  size: 36,
                  color: isDark ? Colors.white : yaru.sparkle,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
