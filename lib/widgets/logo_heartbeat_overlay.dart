import 'package:flutter/material.dart';

/// 完了時にロゴが「サッと広がって消える」スタイリッシュな演出
///
/// タイムライン (合計 1.0秒):
///   0.00 - 0.20 (0.20s) 出現: scale 0.8 → 1.0、opacity 0 → 0.7 (easeOut)
///   0.20 - 0.70 (0.50s) リング拡大: Primary色の薄いリングが画面全体に放射状に広がる
///                       (リング opacity 0.30 → 0、ロゴ scale 1.0 → 1.1)
///   0.70 - 1.00 (0.30s) 消失: ロゴ opacity 0.7 → 0、scale 1.1 → 1.3 (easeIn)
class LogoHeartbeatOverlay extends StatefulWidget {
  const LogoHeartbeatOverlay({
    super.key,
    required this.onComplete,
    required this.primaryColor,
    this.logoSize = 96.0,
  });

  final VoidCallback onComplete;
  final Color primaryColor;
  final double logoSize;

  /// 演出が再生中かを示すフラグ (連打防御)
  static bool _isPlaying = false;

  /// ナビゲーター直下の rootOverlay に挿入して演出を再生し、
  /// 完了したら自動的に entry を除去する。
  /// 既に再生中なら何もしない (重複挿入による Overlay 残骸を防ぐ)。
  static void show(BuildContext context, {double logoSize = 96.0}) {
    if (_isPlaying) return;
    _isPlaying = true;

    final overlay = Overlay.of(context, rootOverlay: true);
    final primary = Theme.of(context).colorScheme.primary;
    late OverlayEntry entry;
    bool removed = false;
    void safeRemove() {
      if (removed) return;
      removed = true;
      entry.remove();
      _isPlaying = false;
    }

    entry = OverlayEntry(
      builder: (_) => LogoHeartbeatOverlay(
        logoSize: logoSize,
        primaryColor: primary,
        onComplete: safeRemove,
      ),
    );
    overlay.insert(entry);
  }

  @override
  State<LogoHeartbeatOverlay> createState() => _LogoHeartbeatOverlayState();
}

class _LogoHeartbeatOverlayState extends State<LogoHeartbeatOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _completed = false;

  // タイムラインのキーポイント (0.0 - 1.0)
  static const _appearEnd = 0.20;
  static const _ringEnd = 0.70;
  static const _exitEnd = 1.00;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _controller.forward().whenComplete(() {
      if (mounted) _fireComplete();
    });
  }

  void _fireComplete() {
    if (_completed) return;
    _completed = true;
    widget.onComplete();
  }

  @override
  void dispose() {
    _controller.dispose();
    // 演出途中で親が破棄された場合でも entry が残らないよう、確実に呼ぶ
    _fireComplete();
    super.dispose();
  }

  /// ロゴのスケール
  double _logoScale(double t) {
    if (t < _appearEnd) {
      final local = t / _appearEnd;
      return 0.8 + Curves.easeOut.transform(local) * 0.2; // 0.8 → 1.0
    } else if (t < _ringEnd) {
      final local = (t - _appearEnd) / (_ringEnd - _appearEnd);
      return 1.0 + Curves.easeOut.transform(local) * 0.1; // 1.0 → 1.1
    } else {
      final local = (t - _ringEnd) / (_exitEnd - _ringEnd);
      return 1.1 + Curves.easeIn.transform(local) * 0.2; // 1.1 → 1.3
    }
  }

  /// ロゴの不透明度
  double _logoOpacity(double t) {
    if (t < _appearEnd) {
      return Curves.easeOut.transform(t / _appearEnd) * 0.7;
    } else if (t < _ringEnd) {
      return 0.7;
    } else {
      final local = (t - _ringEnd) / (_exitEnd - _ringEnd);
      return 0.7 * (1.0 - Curves.easeIn.transform(local));
    }
  }

  /// リングの進捗 (0.0 - 1.0)。リング展開フェーズのみ 0→1
  double _ringProgress(double t) {
    if (t < _appearEnd || t >= _ringEnd) return -1.0;
    return (t - _appearEnd) / (_ringEnd - _appearEnd);
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final t = _controller.value;
            final ringT = _ringProgress(t);

            return LayoutBuilder(
              builder: (context, constraints) {
                // リングは画面の対角線まで広がる
                final maxRadius = constraints.biggest.longestSide;
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    // 1. 拡大していくリング
                    if (ringT >= 0)
                      _Ring(
                        progress: ringT,
                        maxRadius: maxRadius,
                        color: widget.primaryColor,
                      ),
                    // 2. ロゴ
                    Opacity(
                      opacity: _logoOpacity(t),
                      child: Transform.scale(
                        scale: _logoScale(t),
                        child: Image.asset(
                          'assets/icon/app_icon.png',
                          width: widget.logoSize,
                          height: widget.logoSize,
                          filterQuality: FilterQuality.medium,
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}

/// 拡大しながらフェードアウトする1本のリング (Stroke の円)
class _Ring extends StatelessWidget {
  const _Ring({
    required this.progress,
    required this.maxRadius,
    required this.color,
  });

  final double progress;
  final double maxRadius;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final eased = Curves.easeOut.transform(progress);
    final radius = 48 + (maxRadius - 48) * eased;
    final alpha = (1.0 - progress) * 0.30; // 0.30 → 0
    if (alpha <= 0) return const SizedBox.shrink();
    return IgnorePointer(
      child: CustomPaint(
        size: Size.square(radius * 2),
        painter: _RingPainter(
          radius: radius,
          color: color.withValues(alpha: alpha),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.radius, required this.color});
  final double radius;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      radius,
      paint,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.radius != radius || old.color != color;
}
