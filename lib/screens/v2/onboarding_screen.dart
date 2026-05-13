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
/// 4ページ:
///  1. ようこそ: 「今日何からやる？」の問いに、AIが答える価値訴求
///  2. AI整理 Before/After: ただ並び替えるだけでなく "今やる1件" を選び抜くこと
///  3. ゲーミフィケーション: 続けるほど好きになる仕組み (XP/ストリーク/レベル) と
///     "完璧じゃなくていい" の寄り添い
///  4. CTA: 最初のタスクを追加へ
class V2OnboardingScreen extends StatefulWidget {
  const V2OnboardingScreen({super.key});

  @override
  State<V2OnboardingScreen> createState() => _V2OnboardingScreenState();
}

class _V2OnboardingScreenState extends State<V2OnboardingScreen> {
  final _pc = PageController();
  int _page = 0;

  Future<void> _complete({bool openTaskForm = false}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_onboarding_completed', true);
    if (prefs.getBool('coachmarks_shown') == null) {
      await prefs.setBool('coachmarks_shown', false);
    }
    if (!mounted) return;
    // 初回タスク追加シートを自動で開きたい場合は extra でフラグを渡す
    context.go('/home', extra: openTaskForm ? {'openTaskForm': true} : null);
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
                    _CtaPage(
                      yaru: yaru,
                      l10n: l10n,
                      onStart: () => _complete(openTaskForm: true),
                    ),
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
            l10n.onbV2WelcomeBadge.toUpperCase(),
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
                TextSpan(text: l10n.onbV2WelcomeTitlePart1),
                TextSpan(
                  text: l10n.onbV2WelcomeTitleAccent,
                  style: TextStyle(
                    foreground: Paint()
                      ..shader = yaru.neonGradient
                          .createShader(const Rect.fromLTWH(0, 0, 300, 50)),
                  ),
                ),
                TextSpan(text: l10n.onbV2WelcomeTitlePart2),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            l10n.onbV2WelcomeBody,
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
    final beforeTasks = <(String, String)>[
      (l10n.onbV2BeforeTask1, l10n.onbV2BeforeDate1),
      (l10n.onbV2BeforeTask2, l10n.onbV2BeforeDate2),
      (l10n.onbV2BeforeTask3, l10n.onbV2BeforeDate3),
    ];
    final afterTasks = <(String, String, String, Color)>[
      (l10n.onbV2AfterBadgeUrgent, l10n.onbV2AfterTask1, l10n.onbV2AfterComment1, yaru.urgent),
      (l10n.onbV2AfterBadgeWeek, l10n.onbV2AfterTask2, l10n.onbV2AfterComment2, yaru.soon),
      (l10n.onbV2AfterBadgeLater, l10n.onbV2AfterTask3, l10n.onbV2AfterComment3, yaru.later),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 8),
          Text(
            l10n.onbV2BeforeAfterTitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: yaru.inkPrimary,
              letterSpacing: -0.4,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            l10n.onbV2BeforeAfterSub,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.5,
              color: yaru.inkTertiary,
              height: 1.55,
            ),
          ),
          const SizedBox(height: 18),
          GlassCard(
            borderRadius: 16,
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      l10n.onbV2BeforeLabel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: yaru.inkTertiary,
                        letterSpacing: 1.4,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n.onbV2BeforeCaption,
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 11,
                          color: yaru.inkQuaternary,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                for (final t in beforeTasks)
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
                        Expanded(
                          child: Text(t.$1,
                              style: TextStyle(
                                  fontSize: 13, color: yaru.inkSecondary)),
                        ),
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
                l10n.onbV2NaviArrow.toUpperCase(),
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
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              decoration: BoxDecoration(
                color: yaru.paper,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        l10n.onbV2AfterLabel,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: yaru.sparkle,
                          letterSpacing: 1.4,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l10n.onbV2AfterCaption,
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontSize: 11,
                            color: yaru.sparkle,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  for (final t in afterTasks)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: t.$4.withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                      color:
                                          t.$4.withValues(alpha: 0.5),
                                      width: 0.6),
                                ),
                                child: Text(
                                  t.$1,
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w800,
                                    color: t.$4,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  t.$2,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: yaru.inkPrimary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.only(
                                left: 4, top: 3, right: 0),
                            child: Row(
                              children: [
                                Icon(Icons.auto_awesome,
                                    size: 11, color: yaru.sparkle),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    t.$3,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: yaru.inkTertiary,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
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
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Text(
            l10n.onbV2GameTitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: yaru.inkPrimary,
              letterSpacing: -0.4,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            l10n.onbV2GameSub,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12.5, color: yaru.inkTertiary, height: 1.5),
          ),
          const SizedBox(height: 22),
          GlassCard(
            borderRadius: 18,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _featureRow(
                  yaru: yaru,
                  emoji: '⚡',
                  title: l10n.onbV2GameXpTitle,
                  sub: l10n.onbV2GameXpSub,
                ),
                const SizedBox(height: 14),
                _featureRow(
                  yaru: yaru,
                  emoji: '🔥',
                  title: l10n.onbV2GameStreakTitle,
                  sub: l10n.onbV2GameStreakSub,
                ),
                const SizedBox(height: 14),
                _featureRow(
                  yaru: yaru,
                  emoji: '🏆',
                  title: l10n.onbV2GameLevelTitle,
                  sub: l10n.onbV2GameLevelSub,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(
              color: yaru.accent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: yaru.accent.withValues(alpha: 0.18)),
            ),
            child: Text(
              l10n.onbV2GameFooter,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: yaru.inkSecondary,
                height: 1.55,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
          const SizedBox(height: 16),
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
            l10n.onbV2CtaTitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: yaru.inkPrimary,
              letterSpacing: -0.4,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            l10n.onbV2CtaBody,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13.5,
              color: yaru.inkSecondary,
              height: 1.7,
            ),
          ),
          const SizedBox(height: 30),
          NeonButton(
            label: l10n.onbV2CtaButton,
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
