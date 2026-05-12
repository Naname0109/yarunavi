import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../models/user_stats.dart';
import '../../theme/yaru_colors.dart';
import '../../theme/yaru_theme.dart';

/// 実績画面の炎カード（連続日数）。
///
/// - ライト: オレンジグラデ (v1) + 大きな炎装飾
/// - ダーク: グラデ枠線で囲った黒内側 + 炎装飾 (v2 dark)
class StreakCard extends StatelessWidget {
  const StreakCard({super.key, required this.stats});
  final UserStats stats;

  @override
  Widget build(BuildContext context) {
    final yaru = context.yaru;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    if (isDark) {
      return _darkVariant(yaru: yaru, l10n: l10n);
    }
    return _lightVariant(yaru: yaru, l10n: l10n);
  }

  Widget _lightVariant({required YaruTheme yaru, required AppLocalizations l10n}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: yaru.streakGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: yaru.streakShadow,
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: -20,
            top: -10,
            child: Icon(
              Icons.local_fire_department_rounded,
              size: 180,
              color: Colors.white.withValues(alpha: 0.25),
            ),
          ),
          _content(textColor: Colors.white, l10n: l10n, accent: Colors.white),
        ],
      ),
    );
  }

  Widget _darkVariant({required YaruTheme yaru, required AppLocalizations l10n}) {
    return Container(
      padding: const EdgeInsets.all(1),
      decoration: BoxDecoration(
        gradient: yaru.streakGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: yaru.streakShadow,
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: YaruColors.bgDark1,
          borderRadius: BorderRadius.circular(23),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              right: -20,
              top: -10,
              child: Icon(
                Icons.local_fire_department_rounded,
                size: 180,
                color: YaruColors.amber.withValues(alpha: 0.15),
              ),
            ),
            _content(
              textColor: yaru.inkPrimary,
              l10n: l10n,
              accent: YaruColors.amber,
            ),
          ],
        ),
      ),
    );
  }

  Widget _content({
    required Color textColor,
    required Color accent,
    required AppLocalizations l10n,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.local_fire_department_rounded, size: 20, color: accent),
            const SizedBox(width: 8),
            Text(
              l10n.statsStreakActive,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: accent,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        RichText(
          text: TextSpan(
            style: TextStyle(
              fontSize: 64,
              fontWeight: FontWeight.w800,
              height: 1.0,
              color: textColor,
              fontFeatures: const [FontFeature.tabularFigures()],
              letterSpacing: -2.5,
            ),
            children: [
              TextSpan(text: '${stats.streakDays}'),
              TextSpan(
                text: stats.streakDays == 0 ? ' days' : '日',
                style: TextStyle(
                  fontSize: 22,
                  color: accent,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '${l10n.statsLongest}: ${stats.longestStreak}',
          style: TextStyle(
            fontSize: 12,
            color: textColor.withValues(alpha: 0.85),
          ),
        ),
      ],
    );
  }
}
