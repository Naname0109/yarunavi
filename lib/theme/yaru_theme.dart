import 'package:flutter/material.dart';

import 'yaru_colors.dart';
import 'yaru_gradients.dart';
import 'yaru_shadows.dart';

/// テーマ依存のデザイントークン束。
///
/// Widget からは `Theme.of(context).extension<YaruTheme>()!` で参照する。
/// ライト = v1 Electric Blue、ダーク = v2 Midnight Neon に値が切り替わる。
@immutable
class YaruTheme extends ThemeExtension<YaruTheme> {
  const YaruTheme({
    required this.scaffoldBg,
    required this.paper,
    required this.paperEmph,
    required this.line,
    required this.lineStrong,
    required this.inkPrimary,
    required this.inkSecondary,
    required this.inkTertiary,
    required this.inkQuaternary,
    required this.accent,
    required this.accentDeep,
    required this.sparkle,
    required this.heroGradient,
    required this.primaryGradient,
    required this.sparkleGradient,
    required this.streakGradient,
    required this.mascotGradient,
    required this.bgGradient,
    required this.progressGradient,
    required this.flameMiniGradient,
    required this.neonGradient,
    required this.aiOrbGradient,
    required this.cardShadow,
    required this.heroShadow,
    required this.ctaShadow,
    required this.streakShadow,
    required this.fabShadow,
    required this.cyanGlow,
    required this.magentaGlow,
    required this.amberGlow,
    required this.useGlassBlur,
    required this.glassOpacity,
    required this.urgent,
    required this.soon,
    required this.later,
    required this.calm,
    required this.flame,
    required this.gold,
    required this.goldDeep,
  });

  // ============ Surfaces ============
  final Color scaffoldBg;
  final Color paper;
  final Color paperEmph;
  final Color line;
  final Color lineStrong;

  // ============ Ink (text) ============
  final Color inkPrimary;
  final Color inkSecondary;
  final Color inkTertiary;
  final Color inkQuaternary;

  // ============ Accents ============
  final Color accent;
  final Color accentDeep;
  final Color sparkle;

  // ============ Priority tones ============
  final Color urgent;
  final Color soon;
  final Color later;
  final Color calm;
  final Color flame;
  final Color gold;
  final Color goldDeep;

  // ============ Gradients ============
  final Gradient heroGradient;
  final Gradient primaryGradient;
  final Gradient sparkleGradient;
  final Gradient streakGradient;
  final Gradient mascotGradient;
  final Gradient bgGradient;
  final Gradient progressGradient;
  final Gradient flameMiniGradient;
  final Gradient neonGradient;
  final SweepGradient aiOrbGradient;

  // ============ Shadows ============
  final List<BoxShadow> cardShadow;
  final List<BoxShadow> heroShadow;
  final List<BoxShadow> ctaShadow;
  final List<BoxShadow> streakShadow;
  final List<BoxShadow> fabShadow;
  final List<BoxShadow> cyanGlow;
  final List<BoxShadow> magentaGlow;
  final List<BoxShadow> amberGlow;

  // ============ Flags ============
  final bool useGlassBlur;
  final double glassOpacity;

  // ============ Factories ============

  static const YaruTheme light = YaruTheme(
    scaffoldBg: YaruColors.bgLight,
    paper: YaruColors.paperLight,
    paperEmph: YaruColors.paperLight,
    line: YaruColors.lineLight,
    lineStrong: YaruColors.inkLight200,
    inkPrimary: YaruColors.inkLight900,
    inkSecondary: YaruColors.inkLight700,
    inkTertiary: YaruColors.inkLight500,
    inkQuaternary: YaruColors.inkLight400,
    accent: YaruColors.primary,
    accentDeep: YaruColors.primaryDeep,
    sparkle: YaruColors.sparkle,
    urgent: YaruColors.urgent,
    soon: YaruColors.soonDeep,
    later: YaruColors.primary,
    calm: YaruColors.inkLight400,
    flame: YaruColors.flame,
    gold: YaruColors.goldLight,
    goldDeep: YaruColors.goldDeep,
    heroGradient: YaruGradients.heroLight,
    primaryGradient: YaruGradients.primaryLight,
    sparkleGradient: YaruGradients.sparkleLight,
    streakGradient: YaruGradients.streakLight,
    mascotGradient: YaruGradients.mascotLight,
    bgGradient: YaruGradients.bgSparkleLight,
    progressGradient: YaruGradients.primaryLight,
    flameMiniGradient: YaruGradients.streakLight,
    // ライトでも neon を提供するが、控えめなsparkleグラデで代用
    neonGradient: YaruGradients.sparkleLight,
    aiOrbGradient: YaruGradients.aiOrbDark, // SweepGradient はライトでも見栄え良
    cardShadow: YaruShadows.card,
    heroShadow: YaruShadows.heroLight,
    ctaShadow: YaruShadows.ctaLight,
    streakShadow: YaruShadows.streakLight,
    fabShadow: YaruShadows.fab,
    cyanGlow: <BoxShadow>[], // ライトはグロー無し
    magentaGlow: <BoxShadow>[],
    amberGlow: <BoxShadow>[],
    useGlassBlur: false,
    glassOpacity: 1.0,
  );

  static const YaruTheme dark = YaruTheme(
    scaffoldBg: YaruColors.bgDark0,
    paper: YaruColors.bgDark1,
    paperEmph: YaruColors.bgDark2,
    line: YaruColors.lineDark,
    lineStrong: YaruColors.lineDarkStrong,
    inkPrimary: YaruColors.inkDark1,
    inkSecondary: YaruColors.inkDark2,
    inkTertiary: YaruColors.inkDark3,
    inkQuaternary: YaruColors.inkDark4,
    accent: YaruColors.cyan,
    accentDeep: YaruColors.indigo,
    sparkle: YaruColors.magenta,
    urgent: YaruColors.urgentNeon,
    soon: YaruColors.soonNeon,
    later: YaruColors.cyan,
    calm: YaruColors.inkDark3,
    flame: YaruColors.amber,
    gold: YaruColors.goldLight,
    goldDeep: YaruColors.goldDeep,
    heroGradient: YaruGradients.neonDark,
    primaryGradient: YaruGradients.primaryDark,
    sparkleGradient: YaruGradients.neonDark,
    streakGradient: YaruGradients.streakDark,
    mascotGradient: YaruGradients.neonDark,
    bgGradient: YaruGradients.bgMeshDark,
    progressGradient: YaruGradients.progressDark,
    flameMiniGradient: YaruGradients.flameMiniDark,
    neonGradient: YaruGradients.neonDark,
    aiOrbGradient: YaruGradients.aiOrbDark,
    cardShadow: YaruShadows.glass,
    heroShadow: YaruShadows.heroDark,
    ctaShadow: YaruShadows.ctaDark,
    streakShadow: YaruShadows.streakDark,
    fabShadow: YaruShadows.ctaDark,
    cyanGlow: YaruShadows.cyanGlow,
    magentaGlow: YaruShadows.magentaGlow,
    amberGlow: YaruShadows.amberGlow,
    useGlassBlur: true,
    glassOpacity: 0.04,
  );

  // ============ ThemeExtension hooks ============

  @override
  YaruTheme copyWith({
    Color? scaffoldBg,
    Color? paper,
    Color? paperEmph,
    Color? line,
    Color? lineStrong,
    Color? inkPrimary,
    Color? inkSecondary,
    Color? inkTertiary,
    Color? inkQuaternary,
    Color? accent,
    Color? accentDeep,
    Color? sparkle,
    Color? urgent,
    Color? soon,
    Color? later,
    Color? calm,
    Color? flame,
    Color? gold,
    Color? goldDeep,
    Gradient? heroGradient,
    Gradient? primaryGradient,
    Gradient? sparkleGradient,
    Gradient? streakGradient,
    Gradient? mascotGradient,
    Gradient? bgGradient,
    Gradient? progressGradient,
    Gradient? flameMiniGradient,
    Gradient? neonGradient,
    SweepGradient? aiOrbGradient,
    List<BoxShadow>? cardShadow,
    List<BoxShadow>? heroShadow,
    List<BoxShadow>? ctaShadow,
    List<BoxShadow>? streakShadow,
    List<BoxShadow>? fabShadow,
    List<BoxShadow>? cyanGlow,
    List<BoxShadow>? magentaGlow,
    List<BoxShadow>? amberGlow,
    bool? useGlassBlur,
    double? glassOpacity,
  }) {
    return YaruTheme(
      scaffoldBg: scaffoldBg ?? this.scaffoldBg,
      paper: paper ?? this.paper,
      paperEmph: paperEmph ?? this.paperEmph,
      line: line ?? this.line,
      lineStrong: lineStrong ?? this.lineStrong,
      inkPrimary: inkPrimary ?? this.inkPrimary,
      inkSecondary: inkSecondary ?? this.inkSecondary,
      inkTertiary: inkTertiary ?? this.inkTertiary,
      inkQuaternary: inkQuaternary ?? this.inkQuaternary,
      accent: accent ?? this.accent,
      accentDeep: accentDeep ?? this.accentDeep,
      sparkle: sparkle ?? this.sparkle,
      urgent: urgent ?? this.urgent,
      soon: soon ?? this.soon,
      later: later ?? this.later,
      calm: calm ?? this.calm,
      flame: flame ?? this.flame,
      gold: gold ?? this.gold,
      goldDeep: goldDeep ?? this.goldDeep,
      heroGradient: heroGradient ?? this.heroGradient,
      primaryGradient: primaryGradient ?? this.primaryGradient,
      sparkleGradient: sparkleGradient ?? this.sparkleGradient,
      streakGradient: streakGradient ?? this.streakGradient,
      mascotGradient: mascotGradient ?? this.mascotGradient,
      bgGradient: bgGradient ?? this.bgGradient,
      progressGradient: progressGradient ?? this.progressGradient,
      flameMiniGradient: flameMiniGradient ?? this.flameMiniGradient,
      neonGradient: neonGradient ?? this.neonGradient,
      aiOrbGradient: aiOrbGradient ?? this.aiOrbGradient,
      cardShadow: cardShadow ?? this.cardShadow,
      heroShadow: heroShadow ?? this.heroShadow,
      ctaShadow: ctaShadow ?? this.ctaShadow,
      streakShadow: streakShadow ?? this.streakShadow,
      fabShadow: fabShadow ?? this.fabShadow,
      cyanGlow: cyanGlow ?? this.cyanGlow,
      magentaGlow: magentaGlow ?? this.magentaGlow,
      amberGlow: amberGlow ?? this.amberGlow,
      useGlassBlur: useGlassBlur ?? this.useGlassBlur,
      glassOpacity: glassOpacity ?? this.glassOpacity,
    );
  }

  @override
  YaruTheme lerp(ThemeExtension<YaruTheme>? other, double t) {
    if (other is! YaruTheme) return this;
    // 色は補間、グラデーション/シャドウ/フラグは t<0.5 で this, それ以上で other
    Color c(Color a, Color b) => Color.lerp(a, b, t) ?? b;
    final useOther = t >= 0.5;
    YaruTheme src = useOther ? other : this;
    return YaruTheme(
      scaffoldBg: c(scaffoldBg, other.scaffoldBg),
      paper: c(paper, other.paper),
      paperEmph: c(paperEmph, other.paperEmph),
      line: c(line, other.line),
      lineStrong: c(lineStrong, other.lineStrong),
      inkPrimary: c(inkPrimary, other.inkPrimary),
      inkSecondary: c(inkSecondary, other.inkSecondary),
      inkTertiary: c(inkTertiary, other.inkTertiary),
      inkQuaternary: c(inkQuaternary, other.inkQuaternary),
      accent: c(accent, other.accent),
      accentDeep: c(accentDeep, other.accentDeep),
      sparkle: c(sparkle, other.sparkle),
      urgent: c(urgent, other.urgent),
      soon: c(soon, other.soon),
      later: c(later, other.later),
      calm: c(calm, other.calm),
      flame: c(flame, other.flame),
      gold: c(gold, other.gold),
      goldDeep: c(goldDeep, other.goldDeep),
      heroGradient: src.heroGradient,
      primaryGradient: src.primaryGradient,
      sparkleGradient: src.sparkleGradient,
      streakGradient: src.streakGradient,
      mascotGradient: src.mascotGradient,
      bgGradient: src.bgGradient,
      progressGradient: src.progressGradient,
      flameMiniGradient: src.flameMiniGradient,
      neonGradient: src.neonGradient,
      aiOrbGradient: src.aiOrbGradient,
      cardShadow: src.cardShadow,
      heroShadow: src.heroShadow,
      ctaShadow: src.ctaShadow,
      streakShadow: src.streakShadow,
      fabShadow: src.fabShadow,
      cyanGlow: src.cyanGlow,
      magentaGlow: src.magentaGlow,
      amberGlow: src.amberGlow,
      useGlassBlur: src.useGlassBlur,
      glassOpacity: src.glassOpacity,
    );
  }
}

/// 取得ヘルパー: `context.yaru` で参照可能。
extension YaruThemeContext on BuildContext {
  YaruTheme get yaru => Theme.of(this).extension<YaruTheme>() ?? YaruTheme.light;
}
