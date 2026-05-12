import 'package:flutter/material.dart';

import '../theme/yaru_theme.dart';

/// AI スパークル円バッジ（青紫グラデ + 中央スパークル）。
///
/// サイズ可変 (26〜96 推奨)、ライト/ダーク自動切替。
/// ライト = sparkleGradient (#2453FF→#7C5CFF) + 紫グロー
/// ダーク = neonGradient (シアン→インディゴ→マゼンタ) + マゼンタグロー
class SparkleBadge extends StatelessWidget {
  const SparkleBadge({
    super.key,
    this.size = 36,
    this.glow = true,
  });

  final double size;
  final bool glow;

  @override
  Widget build(BuildContext context) {
    final yaru = context.yaru;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: yaru.sparkleGradient,
        boxShadow: glow
            ? (yaru.useGlassBlur
                ? yaru.magentaGlow
                : [
                    BoxShadow(
                      color: yaru.sparkle.withValues(alpha: 0.45),
                      blurRadius: size * 0.5,
                      offset: Offset(0, size * 0.16),
                    ),
                  ])
            : null,
      ),
      child: Center(
        child: Icon(
          Icons.auto_awesome,
          size: size * 0.55,
          color: Colors.white,
        ),
      ),
    );
  }
}
