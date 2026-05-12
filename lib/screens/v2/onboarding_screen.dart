import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../theme/yaru_colors.dart';
import '../../theme/yaru_theme.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/neon_button.dart';
import '../../widgets/responsive_wrapper.dart';

/// v2 オンボーディング画面。
///
/// 4ページ構成:
///  1. ようこそ (Conicオーブ + コピー)
///  2. Before/After デモ
///  3. ストリーク/レベルの説明
///  4. 開始CTA
class V2OnboardingScreen extends StatefulWidget {
  const V2OnboardingScreen({super.key});

  @override
  State<V2OnboardingScreen> createState() => _V2OnboardingScreenState();
}

class _V2OnboardingScreenState extends State<V2OnboardingScreen> {
  final _pc = PageController();
  int _page = 0;

  Future<void> _complete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_onboarding_completed', true);
    if (prefs.getBool('coachmarks_shown') == null) {
      await prefs.setBool('coachmarks_shown', false);
    }
    if (mounted) context.go('/home');
  }

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final yaru = context.yaru;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: yaru.scaffoldBg,
      body: SafeArea(
        child: ResponsiveWrapper(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 6),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _complete,
                    child: Text(
                      l10n.onboardingSkip,
                      style: TextStyle(
                        color: yaru.inkTertiary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: PageView(
                  controller: _pc,
                  onPageChanged: (i) => setState(() => _page = i),
                  children: [
                    _WelcomePage(yaru: yaru, l10n: l10n),
                    _BeforeAfterPage(yaru: yaru, l10n: l10n),
                    _GamificationPage(yaru: yaru, l10n: l10n),
                    _CtaPage(yaru: yaru, l10n: l10n, onStart: _complete),
                  ],
                ),
              ),
              _bottomBar(yaru, l10n),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bottomBar(YaruTheme yaru, AppLocalizations l10n) {
    final isLast = _page == 3;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(4, (i) {
              final active = i == _page;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: active ? 20 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: active ? yaru.accent : yaru.lineStrong,
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: active && yaru.useGlassBlur
                      ? [
                          BoxShadow(
                            color: yaru.accent.withValues(alpha: 0.6),
                            blurRadius: 8,
                          ),
                        ]
                      : null,
                ),
              );
            }),
          ),
          const SizedBox(height: 14),
          if (!isLast)
            NeonButton(
              label: l10n.onboardingNext,
              trailingIcon: Icons.chevron_right_rounded,
              height: 52,
              onPressed: () {
                _pc.nextPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                );
              },
            ),
        ],
      ),
    );
  }
}

class _WelcomePage extends StatelessWidget {
  const _WelcomePage({required this.yaru, required this.l10n});
  final YaruTheme yaru;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        children: [
          const Spacer(),
          _orb(yaru, 130),
          const SizedBox(height: 32),
          Text(
            'NAVI · AI ASSISTANT',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: yaru.accent,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 12),
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w800,
                color: yaru.inkPrimary,
                height: 1.25,
                letterSpacing: -0.5,
              ),
              children: [
                const TextSpan(text: 'AIが、\n'),
                TextSpan(
                  text: '次の一手',
                  style: TextStyle(
                    foreground: Paint()
                      ..shader = yaru.neonGradient
                          .createShader(const Rect.fromLTWH(0, 0, 300, 50)),
                  ),
                ),
                const TextSpan(text: '\nを教えてくれる'),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            '優先順位もアドバイスも通知も\nぜんぶナビにおまかせ。',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13.5,
              color: yaru.inkSecondary,
              height: 1.7,
            ),
          ),
          const Spacer(flex: 2),
        ],
      ),
    );
  }
}

class _BeforeAfterPage extends StatelessWidget {
  const _BeforeAfterPage({required this.yaru, required this.l10n});
  final YaruTheme yaru;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 8),
          Text(
            'AI整理の効果',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: yaru.inkPrimary,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '混乱したタスクを最適順に並べ替えます',
            style: TextStyle(fontSize: 13, color: yaru.inkTertiary),
          ),
          const SizedBox(height: 22),
          GlassCard(
            borderRadius: 16,
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'BEFORE · MESSY',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: yaru.inkTertiary,
                    letterSpacing: 1.4,
                  ),
                ),
                const SizedBox(height: 10),
                for (final t in const [
                  ('週報提出', '今日'),
                  ('家賃振込', '明日'),
                  ('買い物', '5/18'),
                ])
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Container(
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                            color: yaru.inkQuaternary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(t.$1,
                            style: TextStyle(
                                fontSize: 13, color: yaru.inkSecondary)),
                        const Spacer(),
                        Text(t.$2,
                            style: TextStyle(
                              fontSize: 11,
                              color: yaru.inkQuaternary,
                              fontFeatures: const [
                                FontFeature.tabularFigures()
                              ],
                            )),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.arrow_downward_rounded,
                  size: 14, color: yaru.accent),
              const SizedBox(width: 6),
              Text(
                'NAVI で整理',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: yaru.accent,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(1),
            decoration: BoxDecoration(
              gradient: yaru.neonGradient,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: yaru.paper,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AFTER · OPTIMIZED',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: yaru.sparkle,
                      letterSpacing: 1.4,
                    ),
                  ),
                  const SizedBox(height: 10),
                  for (final t in [
                    ('URGENT', '週報提出', yaru.urgent),
                    ('THIS WEEK', '家賃振込', yaru.soon),
                    ('LATER', '買い物', yaru.later),
                  ])
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: t.$3,
                              shape: BoxShape.circle,
                              boxShadow: yaru.useGlassBlur
                                  ? [
                                      BoxShadow(
                                          color: t.$3
                                              .withValues(alpha: 0.6),
                                          blurRadius: 6)
                                    ]
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            t.$1,
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              color: t.$3,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            t.$2,
                            style: TextStyle(
                              fontSize: 13,
                              color: yaru.inkPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}

class _GamificationPage extends StatelessWidget {
  const _GamificationPage({required this.yaru, required this.l10n});
  final YaruTheme yaru;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Text(
            '使うほど報われる',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: yaru.inkPrimary,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'タスク完了で XP/レベル + 連続ストリーク',
            style: TextStyle(fontSize: 13, color: yaru.inkTertiary),
          ),
          const SizedBox(height: 24),
          GlassCard(
            borderRadius: 18,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _featureRow(
                  yaru: yaru,
                  emoji: '⚡',
                  title: 'タスク完了 +10 XP',
                  sub: '今日全完了でさらに +25 XP',
                ),
                const SizedBox(height: 14),
                _featureRow(
                  yaru: yaru,
                  emoji: '🔥',
                  title: 'ストリーク連続日数',
                  sub: '3/7/14/30日でボーナス + バッジ獲得',
                ),
                const SizedBox(height: 14),
                _featureRow(
                  yaru: yaru,
                  emoji: '🏆',
                  title: 'レベル + バッジ',
                  sub: 'Lv.1 はじめてのナビ → Lv.8 伝説のプランナー',
                ),
              ],
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _featureRow({
    required YaruTheme yaru,
    required String emoji,
    required String title,
    required String sub,
  }) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: yaru.accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: yaru.accent.withValues(alpha: 0.3)),
          ),
          child: Text(emoji, style: const TextStyle(fontSize: 22)),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: yaru.inkPrimary)),
              const SizedBox(height: 2),
              Text(sub,
                  style:
                      TextStyle(fontSize: 11.5, color: yaru.inkTertiary)),
            ],
          ),
        ),
      ],
    );
  }
}

class _CtaPage extends StatelessWidget {
  const _CtaPage({
    required this.yaru,
    required this.l10n,
    required this.onStart,
  });
  final YaruTheme yaru;
  final AppLocalizations l10n;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        children: [
          const Spacer(),
          _orb(yaru, 110),
          const SizedBox(height: 28),
          Text(
            'さあ、はじめよう',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: yaru.inkPrimary,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '最初のタスクを追加するか\nサンプルから始められます。',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13.5,
              color: yaru.inkSecondary,
              height: 1.7,
            ),
          ),
          const SizedBox(height: 30),
          NeonButton(
            label: 'タスク追加から始める',
            icon: Icons.add_rounded,
            height: 54,
            onPressed: onStart,
          ),
          const Spacer(flex: 2),
        ],
      ),
    );
  }
}

Widget _orb(YaruTheme yaru, double size) {
  return SizedBox(
    width: size,
    height: size,
    child: Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: yaru.aiOrbGradient,
            boxShadow: yaru.useGlassBlur
                ? [
                    BoxShadow(
                      color: yaru.sparkle.withValues(alpha: 0.5),
                      blurRadius: 80,
                      spreadRadius: -8,
                    ),
                  ]
                : [
                    BoxShadow(
                      color: yaru.accent.withValues(alpha: 0.45),
                      blurRadius: 60,
                      spreadRadius: -12,
                      offset: const Offset(0, 16),
                    ),
                  ],
          ),
        ),
        Container(
          width: size - 14,
          height: size - 14,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: yaru.useGlassBlur ? YaruColors.bgDark1 : Colors.white,
          ),
          alignment: Alignment.center,
          child: Icon(
            Icons.auto_awesome,
            size: size * 0.45,
            color: yaru.useGlassBlur ? Colors.white : yaru.sparkle,
          ),
        ),
      ],
    ),
  );
}
