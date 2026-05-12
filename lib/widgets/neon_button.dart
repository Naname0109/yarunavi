import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/yaru_colors.dart';
import '../theme/yaru_theme.dart';

/// CTA ボタン (グラデーション + ネオングロー)。
///
/// ライト = electric blue グラデ + 青影
/// ダーク = シアン→インディゴ グラデ + ネオングロー (シアン+インディゴ二重)
/// プライマリ用途は [NeonButton]、サブ用途は [NeonButtonSecondary]。
class NeonButton extends StatelessWidget {
  const NeonButton({
    super.key,
    required this.onPressed,
    this.child,
    this.label,
    this.icon,
    this.trailingIcon,
    this.height = 54,
    this.padding,
    this.fullWidth = true,
    this.haptic = true,
  }) : assert(child != null || label != null);

  final VoidCallback? onPressed;
  final Widget? child;
  final String? label;
  final IconData? icon;
  final IconData? trailingIcon;
  final double height;
  final EdgeInsetsGeometry? padding;
  final bool fullWidth;
  final bool haptic;

  @override
  Widget build(BuildContext context) {
    final yaru = context.yaru;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = isDark ? YaruColors.bgDark0 : Colors.white;

    final content = child ??
        DefaultTextStyle.merge(
          style: TextStyle(
            color: fg,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: fg),
                const SizedBox(width: 8),
              ],
              Text(label!),
              if (trailingIcon != null) ...[
                const SizedBox(width: 8),
                Icon(trailingIcon, size: 16, color: fg),
              ],
            ],
          ),
        );

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: yaru.ctaShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            gradient: yaru.primaryGradient,
            borderRadius: BorderRadius.circular(14),
          ),
          child: InkWell(
            onTap: onPressed == null
                ? null
                : () {
                    if (haptic) HapticFeedback.lightImpact();
                    onPressed!();
                  },
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: fullWidth ? double.infinity : null,
              height: height,
              padding: padding ??
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
              alignment: Alignment.center,
              child: content,
            ),
          ),
        ),
      ),
    );
  }
}

/// サブCTAボタン (透明 + 枠線 + ネオン or 青)。
class NeonButtonSecondary extends StatelessWidget {
  const NeonButtonSecondary({
    super.key,
    required this.onPressed,
    this.child,
    this.label,
    this.icon,
    this.height = 50,
    this.fullWidth = true,
  }) : assert(child != null || label != null);

  final VoidCallback? onPressed;
  final Widget? child;
  final String? label;
  final IconData? icon;
  final double height;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    final yaru = context.yaru;
    final fg = yaru.inkPrimary;
    final content = child ??
        DefaultTextStyle.merge(
          style: TextStyle(
            color: fg,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: fg),
                const SizedBox(width: 6),
              ],
              Text(label!),
            ],
          ),
        );

    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          color: yaru.paper,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: yaru.line),
        ),
        child: InkWell(
          onTap: onPressed == null
              ? null
              : () {
                  HapticFeedback.selectionClick();
                  onPressed!();
                },
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: fullWidth ? double.infinity : null,
            height: height,
            alignment: Alignment.center,
            child: content,
          ),
        ),
      ),
    );
  }
}
