import 'package:flutter/material.dart';

import '../../theme/yaru_theme.dart';
import '../../widgets/responsive_wrapper.dart';
import '../onboarding_screen.dart';

/// v2 オンボーディング画面ラッパー (現状は既存ロジックを再利用)。
class V2OnboardingScreen extends StatelessWidget {
  const V2OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final yaru = context.yaru;
    return Scaffold(
      backgroundColor: yaru.scaffoldBg,
      body: const SafeArea(
        bottom: false,
        child: ResponsiveWrapper(child: OnboardingScreen()),
      ),
    );
  }
}
