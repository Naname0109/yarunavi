import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/yaru_theme.dart';

/// テーマ自動切替対応のカード。
///
/// ダーク: BackdropFilter + 半透明白 + ライン枠（v2 ガラスモーフィズム）
/// ライト: ペーパー白 + 控えめなシャドウ + ライン枠
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = 16,
    this.strong = false,
    this.borderColor,
    this.gradientBorder,
    this.shadow,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;

  /// ダーク時に より不透明な背景を使う (glass-strong 相当)
  final bool strong;

  /// 枠線色を上書き（null = テーマの line）
  final Color? borderColor;

  /// 枠線を「グラデーション」にしたい場合（ネオン枠用）
  final Gradient? gradientBorder;

  /// 影を上書き（null = テーマの cardShadow）
  final List<BoxShadow>? shadow;

  /// タップハンドラ（指定時はInkWellで包む）
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final yaru = context.yaru;
    final radius = BorderRadius.circular(borderRadius);

    // グラデーション枠線の場合は外側 1pxパディング Container + 内側 ペーパー
    if (gradientBorder != null) {
      return DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          gradient: gradientBorder,
          boxShadow: shadow ?? yaru.cardShadow,
        ),
        child: Padding(
          padding: const EdgeInsets.all(1),
          child: _innerSurface(
            context,
            radius: BorderRadius.circular(borderRadius - 1),
          ),
        ),
      );
    }

    final surface = _innerSurface(context, radius: radius);
    return DecoratedBox(
      decoration: BoxDecoration(
        boxShadow: shadow ?? yaru.cardShadow,
        borderRadius: radius,
      ),
      child: surface,
    );
  }

  Widget _innerSurface(BuildContext context, {required BorderRadius radius}) {
    final yaru = context.yaru;
    final bg = yaru.useGlassBlur
        ? Colors.white.withValues(alpha: strong ? 0.07 : yaru.glassOpacity)
        : (strong ? yaru.paperEmph : yaru.paper);

    Widget content = DecoratedBox(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: radius,
        border: Border.all(
          color: borderColor ?? (strong ? yaru.lineStrong : yaru.line),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Padding(padding: padding, child: child),
      ),
    );

    if (yaru.useGlassBlur) {
      content = ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: content,
        ),
      );
    }

    if (onTap != null) {
      content = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: content,
        ),
      );
    }
    return content;
  }
}
