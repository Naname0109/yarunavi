import 'package:flutter/material.dart';

/// YaruNavi デザイントークン: BoxShadow セット
class YaruShadows {
  YaruShadows._();

  // ============ Light (subtle) ============

  /// 通常カード（白カード用）
  static const card = <BoxShadow>[
    BoxShadow(color: Color(0x0A0B1736), blurRadius: 0, offset: Offset(0, 1)),
    BoxShadow(
      color: Color(0x140B1736),
      blurRadius: 24,
      offset: Offset(0, 8),
      spreadRadius: -12,
    ),
  ];

  /// 浮遊する小型FAB / アイコンボタン
  static const button = <BoxShadow>[
    BoxShadow(
      color: Color(0x0F0B1736),
      blurRadius: 2,
      offset: Offset(0, 1),
    ),
    BoxShadow(
      color: Color(0x140B1736),
      blurRadius: 14,
      offset: Offset(0, 4),
      spreadRadius: -4,
    ),
  ];

  /// FAB (electric blue glow)
  static const fab = <BoxShadow>[
    BoxShadow(
      color: Color(0x8C2453FF),
      blurRadius: 28,
      offset: Offset(0, 12),
      spreadRadius: -8,
    ),
  ];

  /// Primary CTA
  static const ctaLight = <BoxShadow>[
    BoxShadow(
      color: Color(0x8C2453FF),
      blurRadius: 30,
      offset: Offset(0, 14),
      spreadRadius: -10,
    ),
  ];

  /// Home Hero AI card (大型カードのリフト)
  static const heroLight = <BoxShadow>[
    BoxShadow(
      color: Color(0x8C1738C4),
      blurRadius: 40,
      offset: Offset(0, 16),
      spreadRadius: -16,
    ),
  ];

  /// Streak card (orange)
  static const streakLight = <BoxShadow>[
    BoxShadow(
      color: Color(0x8CFF6B35),
      blurRadius: 40,
      offset: Offset(0, 16),
      spreadRadius: -16,
    ),
  ];

  // ============ Dark (neon glow) ============

  /// 控えめなネオングロー (シアン)
  static const cyanGlow = <BoxShadow>[
    BoxShadow(color: Color(0x804DF5FF), blurRadius: 12),
    BoxShadow(color: Color(0x404DF5FF), blurRadius: 24),
  ];

  /// マゼンタ
  static const magentaGlow = <BoxShadow>[
    BoxShadow(color: Color(0x80FF4DDB), blurRadius: 16),
  ];

  /// アンバー (炎用)
  static const amberGlow = <BoxShadow>[
    BoxShadow(color: Color(0x80FFB84D), blurRadius: 16),
  ];

  /// CTA (シアン + インディゴ二重重ね)
  static const ctaDark = <BoxShadow>[
    BoxShadow(color: Color(0x804DF5FF), blurRadius: 24, offset: Offset(0, 8)),
    BoxShadow(color: Color(0x995B7BFF), blurRadius: 40, offset: Offset(0, 16)),
  ];

  /// Hero AI card (ダーク)
  static const heroDark = <BoxShadow>[
    BoxShadow(
      color: Color(0x805B7BFF),
      blurRadius: 60,
      offset: Offset(0, 24),
      spreadRadius: -20,
    ),
    BoxShadow(
      color: Color(0x40FF4DDB),
      blurRadius: 80,
      offset: Offset(0, 32),
      spreadRadius: -30,
    ),
  ];

  /// Streak card (ダーク)
  static const streakDark = <BoxShadow>[
    BoxShadow(
      color: Color(0x80FF5577),
      blurRadius: 60,
      offset: Offset(0, 24),
      spreadRadius: -16,
    ),
  ];

  /// グラスカードの軽い影
  static const glass = <BoxShadow>[
    BoxShadow(
      color: Color(0x66000000),
      blurRadius: 30,
      offset: Offset(0, 12),
      spreadRadius: -10,
    ),
  ];
}
