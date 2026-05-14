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

    // active時は icon上 + label下の縦構成にし、 ラベルを 9pt まで縮めて
    // 「カレンダー」5文字も省略されないようにする。
    // 同時に active タブの背景ピル (グラデ) も縦長から丸長方形に。
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

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            onTap(index);
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            height: 46,
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
            decoration: BoxDecoration(
              gradient: active ? activeBg : null,
              borderRadius: BorderRadius.circular(16),
              border: active
                  ? Border.all(
                      color: yaru.accent.withValues(alpha: isDark ? 0.4 : 0.25),
                    )
                  : null,
            ),
            child: Semantics(
              button: true,
              label: item.label,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(item.icon,
                      size: 18,
                      color: active ? yaru.accent : yaru.inkTertiary),
                  const SizedBox(height: 2),
                  Text(
                    item.label,
                    overflow: TextOverflow.visible,
                    maxLines: 1,
                    softWrap: false,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                      color: active ? yaru.inkPrimary : yaru.inkTertiary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// FAB は ボトムナビbar から 8pt 上方に浮上させて、 主導線として
  /// 視覚的に分離する (タブと同列に見えないように)。
  Widget _fab(BuildContext context, bool isDark, YaruTheme yaru) {
    final fg = isDark ? YaruColors.bgDark0 : Colors.white;
    return Transform.translate(
      offset: const Offset(0, -8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: SizedBox(
          width: 54,
          height: 54,
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: isDark ? yaru.neonGradient : yaru.primaryGradient,
              // 縁取りでバーから "突き出る" 感を強調 (ライト時は白縁、 ダーク時は背景色縁)
              border: Border.all(
                color: isDark
                    ? const Color(0xCC131734)
                    : Colors.white,
                width: 3,
              ),
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
      ),
    );
  }
}

class GlassNavItem {
  const GlassNavItem({required this.icon, required this.label});
  final IconData icon;
  final String label;
}
