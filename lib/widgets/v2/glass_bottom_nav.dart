import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/yaru_colors.dart';
import '../../theme/yaru_theme.dart';

/// v2ホーム画面のフローティング・ボトムナビ。
///
/// 左右に 2 タブずつ、中央に大きな + FAB。ダーク時は ガラスストロング + ネオン枠、
/// ライト時は ペーパー + 控えめな影。
class GlassBottomNav extends StatelessWidget {
  const GlassBottomNav({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
    required this.onAddPressed,
  }) : assert(items.length == 4);

  final List<GlassNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;
  final VoidCallback onAddPressed;

  @override
  Widget build(BuildContext context) {
    final yaru = context.yaru;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark
        ? const Color(0xCC131734).withValues(alpha: 0.85)
        : Colors.white.withValues(alpha: 0.95);

    Widget bar = Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: yaru.line),
        boxShadow: isDark
            ? const [
                BoxShadow(
                  color: Color(0x99000000),
                  blurRadius: 30,
                  offset: Offset(0, 12),
                  spreadRadius: -8,
                ),
              ]
            : yaru.cardShadow,
      ),
      child: Row(
        children: [
          _tab(context, 0),
          _tab(context, 1),
          _fab(context, isDark, yaru),
          _tab(context, 2),
          _tab(context, 3),
        ],
      ),
    );

    if (isDark) {
      bar = ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: bar,
        ),
      );
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: bar,
      ),
    );
  }

  Widget _tab(BuildContext context, int index) {
    final yaru = context.yaru;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final active = currentIndex == index;
    final item = items[index];

    final activeBg = isDark
        ? const LinearGradient(
            colors: [Color(0x404DF5FF), Color(0x405B7BFF)],
          )
        : LinearGradient(
            colors: [
              yaru.accent.withValues(alpha: 0.15),
              yaru.accent.withValues(alpha: 0.05),
            ],
          );

    // アクティブ時は icon + label、非アクティブは icon のみで省スペース化
    // (アクティブもラベル省略可だが、現在地視認性のため表示)
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            onTap(index);
          },
          borderRadius: BorderRadius.circular(999),
          child: Container(
            height: 42,
            decoration: BoxDecoration(
              gradient: active ? activeBg : null,
              borderRadius: BorderRadius.circular(999),
              border: active
                  ? Border.all(
                      color: yaru.accent.withValues(alpha: isDark ? 0.4 : 0.25),
                    )
                  : null,
            ),
            child: active
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(item.icon, size: 19, color: yaru.accent),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          item.label,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            color: yaru.inkPrimary,
                          ),
                        ),
                      ),
                    ],
                  )
                : Semantics(
                    button: true,
                    label: item.label,
                    child: Tooltip(
                      message: item.label,
                      child: Icon(item.icon, size: 20, color: yaru.inkTertiary),
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _fab(BuildContext context, bool isDark, YaruTheme yaru) {
    final fg = isDark ? YaruColors.bgDark0 : Colors.white;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: SizedBox(
        width: 50,
        height: 50,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: isDark ? yaru.neonGradient : yaru.primaryGradient,
            boxShadow: yaru.fabShadow,
          ),
          child: Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () {
                HapticFeedback.mediumImpact();
                onAddPressed();
              },
              child: Icon(Icons.add_rounded, size: 26, color: fg),
            ),
          ),
        ),
      ),
    );
  }
}

class GlassNavItem {
  const GlassNavItem({required this.icon, required this.label});
  final IconData icon;
  final String label;
}
