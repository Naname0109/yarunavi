import 'dart:math' as math;

import 'package:flutter/material.dart';

/// 円形進捗リング（CustomPainter）。
///
/// XP進捗 / 今日のミッション進捗 / その他汎用に利用。
/// グラデ着色対応 (色の場合は単色、Gradientの場合はSweepGradient塗り)。
class ProgressRing extends StatelessWidget {
  const ProgressRing({
    super.key,
    required this.value,
    this.size = 72,
    this.strokeWidth = 7,
    this.trackColor,
    this.color,
    this.gradient,
    this.center,
    this.startAngle = -math.pi / 2,
  })  : assert(value >= 0 && value <= 1),
        assert(color != null || gradient != null);

  /// 0.0〜1.0
  final double value;
  final double size;
  final double strokeWidth;
  final Color? trackColor;
  final Color? color;
  final Gradient? gradient;
  final Widget? center;

  /// 描画開始角度。デフォルトは真上 (−π/2)。
  final double startAngle;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size.square(size),
            painter: _RingPainter(
              value: value,
              strokeWidth: strokeWidth,
              trackColor: trackColor ?? Colors.white.withValues(alpha: 0.15),
              color: color,
              gradient: gradient,
              startAngle: startAngle,
            ),
          ),
          ?center,
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.value,
    required this.strokeWidth,
    required this.trackColor,
    required this.color,
    required this.gradient,
    required this.startAngle,
  });

  final double value;
  final double strokeWidth;
  final Color trackColor;
  final Color? color;
  final Gradient? gradient;
  final double startAngle;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = trackColor;
    canvas.drawCircle(center, radius, trackPaint);

    if (value <= 0) return;
    final sweep = 2 * math.pi * value;
    final progressPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    if (gradient != null) {
      progressPaint.shader = gradient!.createShader(rect);
    } else {
      progressPaint.color = color!;
    }
    canvas.drawArc(rect, startAngle, sweep, false, progressPaint);
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) {
    return old.value != value ||
        old.strokeWidth != strokeWidth ||
        old.trackColor != trackColor ||
        old.color != color ||
        old.gradient != gradient ||
        old.startAngle != startAngle;
  }
}
