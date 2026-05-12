import 'package:flutter/material.dart';

/// YaruNavi デザイントークン: グラデーション
///
/// 命名: `<role><Theme>` (例: heroLight, heroDark)
class YaruGradients {
  YaruGradients._();

  // ============ Light (v1: Electric Blue) ============

  /// Home Hero AI card
  static const heroLight = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0F1F5E), Color(0xFF1738C4), Color(0xFF2453FF)],
    stops: [0.0, 0.45, 1.0],
  );

  /// Primary CTA
  static const primaryLight = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2453FF), Color(0xFF4F7BFF)],
  );

  /// Sparkle badge / AI emphasis
  static const sparkleLight = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2453FF), Color(0xFF7C5CFF)],
  );

  /// Streak card (ライト用 炎)
  static const streakLight = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF6B35), Color(0xFFFF8A00), Color(0xFFFFB050)],
  );

  /// Premium gold
  static const goldLight = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFE56A), Color(0xFFFFB050)],
  );

  /// Onboarding mascot (青紫)
  static const mascotLight = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2453FF), Color(0xFF7C5CFF)],
  );

  /// Body sparkle BG (ホーム背景 radial)
  static const bgSparkleLight = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFF5F7FC), Color(0xFFF4F6FB)],
  );

  // ============ Dark (v2: Midnight Neon) ============

  /// Primary CTA (シアン → インディゴ)
  static const primaryDark = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF4DF5FF), Color(0xFF5B7BFF)],
  );

  /// Full neon (シアン → インディゴ → マゼンタ)
  static const neonDark = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF4DF5FF), Color(0xFF5B7BFF), Color(0xFFFF4DDB)],
  );

  /// Streak (ダーク用 炎)
  static const streakDark = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFFB84D), Color(0xFFFF5577)],
  );

  /// AI Orb (Conic / SweepGradient)
  static const aiOrbDark = SweepGradient(
    colors: [
      Color(0xFF4DF5FF),
      Color(0xFF5B7BFF),
      Color(0xFFFF4DDB),
      Color(0xFF4DF5FF),
    ],
  );

  /// Background mesh (radial 風)
  static const bgMeshDark = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF0B0E1F), Color(0xFF050610)],
  );

  /// Progress bar
  static const progressDark = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFF4DF5FF), Color(0xFF5B7BFF), Color(0xFFFF4DDB)],
  );

  /// Mini bar in streak (7-day chart)
  static const flameMiniDark = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFFB84D), Color(0xFFFF5577)],
  );
}
