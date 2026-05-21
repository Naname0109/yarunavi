import 'package:flutter/material.dart';

import '../../theme/yaru_theme.dart';
import '../../widgets/responsive_wrapper.dart';
import '../calendar_screen.dart';

/// v2 カレンダー画面ラッパー。
///
/// 中身は既存 CalendarScreen を使う。新テーマ (YaruTheme) で
/// 色・カードが自動的に切り替わる。神セルやネオンドットなど
/// pixel-perfect な作り込みは Bundle 3 で対応予定。
class V2CalendarScreen extends StatelessWidget {
  const V2CalendarScreen({super.key, this.isActive = true});

  /// 親 (V2HomeShell の IndexedStack) からタブが見えているかを受け取る。
  /// CalendarScreen がコーチマーク SnackBar の発火判定に利用する。
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final yaru = context.yaru;
    return Scaffold(
      backgroundColor: yaru.scaffoldBg,
      body: SafeArea(
        bottom: false,
        child: ResponsiveWrapper(child: CalendarScreen(isActive: isActive)),
      ),
    );
  }
}
