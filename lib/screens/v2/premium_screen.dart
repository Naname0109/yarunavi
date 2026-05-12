import 'package:flutter/material.dart';

import '../../theme/yaru_theme.dart';
import '../../widgets/responsive_wrapper.dart';
import '../store_screen.dart';

/// v2 プレミアム/ストア画面ラッパー。
///
/// 中身は既存 [StoreScreen] を使う (IAP/サブスクの審査要件があるため安全に運用)。
/// 新テーマ (YaruTheme) で色/影/枠線が自動切替される。
/// pixel-perfect な v2 デザイン (ガラス機能リスト等) は Bundle 3 で対応予定。
class V2PremiumScreen extends StatelessWidget {
  const V2PremiumScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final yaru = context.yaru;
    return Scaffold(
      backgroundColor: yaru.scaffoldBg,
      body: const SafeArea(
        bottom: false,
        child: ResponsiveWrapper(child: StoreScreen()),
      ),
    );
  }
}
