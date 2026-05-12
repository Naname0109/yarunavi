import 'package:flutter/material.dart';

import '../../theme/yaru_colors.dart';
import '../../theme/yaru_theme.dart';

/// 過去14日のアクティビティヒートマップ。
class Heatmap14Days extends StatelessWidget {
  const Heatmap14Days({super.key, required this.activityByDay});

  /// 'YYYY-MM-DD' → 件数
  final Map<String, int> activityByDay;

  @override
  Widget build(BuildContext context) {
    final yaru = context.yaru;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();
    final days = List.generate(14, (i) {
      final d = DateTime(now.year, now.month, now.day - 13 + i);
      final key = _key(d);
      final count = activityByDay[key] ?? 0;
      return _DayCell(date: d, count: count);
    });

    return Row(
      children: [
        for (final d in days) ...[
          Expanded(child: _cell(d.count, isDark, yaru)),
          const SizedBox(width: 3),
        ],
      ]..removeLast(),
    );
  }

  Widget _cell(int count, bool isDark, YaruTheme yaru) {
    final intensity = count >= 5 ? 1.0 : count / 5.0;
    final base = isDark ? YaruColors.cyan : yaru.accent;
    final bg = count == 0
        ? (isDark ? Colors.white.withValues(alpha: 0.04) : yaru.lineStrong)
        : base.withValues(alpha: 0.15 + intensity * 0.75);
    return AspectRatio(
      aspectRatio: 1,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(4),
          boxShadow: isDark && intensity >= 1.0
              ? [
                  BoxShadow(
                    color: base.withValues(alpha: 0.6),
                    blurRadius: 6,
                  ),
                ]
              : null,
        ),
      ),
    );
  }

  static String _key(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}

class _DayCell {
  _DayCell({required this.date, required this.count});
  final DateTime date;
  final int count;
}
