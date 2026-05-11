import 'dart:math' as math;

import 'package:flutter/material.dart';

/// 完了時に画面中央でアプリロゴが鼓動する演出
///
/// タイムライン (合計 3.0秒):
///   0.00 - 0.10 (0.30s) 出現: opacity 0→0.6 / scale 0.5→1.0 (easeOut)
///   0.10 - 0.37 (0.80s) 鼓動1: 1.0 → 1.15 → 1.0 (sin)
///   0.37 - 0.47 (0.30s) 待機
///   0.47 - 0.74 (0.80s) 鼓動2: 1.0 → 1.30 → 1.0 (sin、より大きく)
///   0.74 - 0.94 (0.60s) 拡大消失: scale 1.0→2.0 / opacity 0.6→0
///   0.94 - 1.00 (0.18s) 残像のフェードアウト猶予
///
/// 残像:
///   - パルス1ピーク (t≈0.235) で scale 1.15 / opacity 0.3 の残像を生成
///   - パルス2ピーク (t≈0.605) で scale 1.30 / opacity 0.3 の残像を生成
///   - 各残像は出現から ~1.0秒 (controller の t で 0.333) かけてフェードアウト
class LogoHeartbeatOverlay extends StatefulWidget {
  const LogoHeartbeatOverlay({
    super.key,
    required this.onComplete,
    this.logoSize = 120.0,
  });

  final VoidCallback onComplete;
  final double logoSize;

  /// 演出が再生中かを示すフラグ (連打防御)
  static bool _isPlaying = false;

  /// ナビゲーター直下の rootOverlay に挿入して鼓動演出を再生し、
  /// 完了したら自動的に entry を除去する。
  /// 既に再生中なら何もしない (重複挿入による Overlay 残骸を防ぐ)。
  static void show(BuildContext context, {double logoSize = 120.0}) {
    if (_isPlaying) return;
    _isPlaying = true;

    final overlay = Overlay.of(context, rootOverlay: true);
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
  static const _appearEnd = 0.10;
  static const _pulse1Start = 0.10;
  static const _pulse1End = 0.37;
  static const _pulse1Mid = 0.235; // ピーク
  static const _holdEnd = 0.47;
  static const _pulse2Start = 0.47;
  static const _pulse2End = 0.74;
  static const _pulse2Mid = 0.605; // ピーク
  static const _exitEnd = 0.94;

  // 残像フェード持続時間 (1秒 ≒ controller.value で 0.333)
  static const _afterFadeDuration = 0.333;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
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

  /// メインロゴのスケール
  double _scaleAt(double t) {
    if (t < _appearEnd) {
      final local = t / _appearEnd;
      return 0.5 + Curves.easeOut.transform(local) * 0.5;
    } else if (t < _pulse1End) {
      // 三角波 (sin)
      final local = (t - _pulse1Start) / (_pulse1End - _pulse1Start);
      return 1.0 + math.sin(local * math.pi) * 0.15;
    } else if (t < _holdEnd) {
      return 1.0;
    } else if (t < _pulse2End) {
      final local = (t - _pulse2Start) / (_pulse2End - _pulse2Start);
      return 1.0 + math.sin(local * math.pi) * 0.30;
    } else if (t < _exitEnd) {
      final local = (t - _pulse2End) / (_exitEnd - _pulse2End);
      return 1.0 + Curves.easeOut.transform(local) * 1.0;
    } else {
      return 2.0;
    }
  }

  /// メインロゴの不透明度
  double _opacityAt(double t) {
    if (t < _appearEnd) {
      return Curves.easeOut.transform(t / _appearEnd) * 0.6;
    } else if (t < _pulse2End) {
      return 0.6;
    } else if (t < _exitEnd) {
      final local = (t - _pulse2End) / (_exitEnd - _pulse2End);
      return 0.6 * (1.0 - local);
    } else {
      return 0;
    }
  }

  /// 背景の暗さ (パルス1始まり〜拡大消失終わりまで薄く暗転)
  double _backdropOpacityAt(double t) {
    if (t < _appearEnd) {
      return Curves.easeOut.transform(t / _appearEnd) * 0.10;
    } else if (t < _exitEnd) {
      return 0.10;
    } else {
      final local = (t - _exitEnd) / (1.0 - _exitEnd);
      return 0.10 * (1.0 - local).clamp(0.0, 1.0);
    }
  }

  /// 残像の不透明度 (出現時に 0.3 → 1秒で 0)
  double _afterImageOpacity(double t, double appearAt) {
    if (t < appearAt) return 0;
    final elapsed = t - appearAt;
    if (elapsed >= _afterFadeDuration) return 0;
    return 0.3 * (1.0 - elapsed / _afterFadeDuration);
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final t = _controller.value;
            return Stack(
              alignment: Alignment.center,
              children: [
                // 1. 背景の薄い暗転
                Positioned.fill(
                  child: ColoredBox(
                    color:
                        Colors.black.withValues(alpha: _backdropOpacityAt(t)),
                  ),
                ),
                // 2. パルス1 残像 (1.15x, 0.3 alpha → 1秒フェード)
                _afterImage(t: t, appearAt: _pulse1Mid, scale: 1.15),
                // 3. パルス2 残像 (1.30x)
                _afterImage(t: t, appearAt: _pulse2Mid, scale: 1.30),
                // 4. メインロゴ
                Opacity(
                  opacity: _opacityAt(t),
                  child: Transform.scale(
                    scale: _scaleAt(t),
                    child: _logoImage(),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _afterImage({
    required double t,
    required double appearAt,
    required double scale,
  }) {
    final opacity = _afterImageOpacity(t, appearAt);
    if (opacity <= 0) return const SizedBox.shrink();
    return Opacity(
      opacity: opacity,
      child: Transform.scale(
        scale: scale,
        child: _logoImage(),
      ),
    );
  }

  Widget _logoImage() {
    return Image.asset(
      'assets/icon/app_icon.png',
      width: widget.logoSize,
      height: widget.logoSize,
      // 透過 PNG なので filterQuality を上げる
      filterQuality: FilterQuality.medium,
    );
  }
}
