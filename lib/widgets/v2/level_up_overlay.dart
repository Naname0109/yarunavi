import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../services/gamification_service.dart';
import '../../theme/yaru_colors.dart';
import '../../theme/yaru_theme.dart';

/// レベルアップ全画面演出。 ~1.4秒 自動消滅 + タップで即閉じ。
class LevelUpOverlay {
  LevelUpOverlay._();

  static OverlayEntry? _currentEntry;

  static void show(BuildContext context, int newLevel) {
    HapticFeedback.heavyImpact();
    _currentEntry?.remove();
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(builder: (_) {
      return _LevelUpBurst(
        newLevel: newLevel,
        onDone: () {
          if (_currentEntry == entry) {
            entry.remove();
            _currentEntry = null;
          }
        },
      );
    });
    _currentEntry = entry;
    overlay.insert(entry);
  }
}

class _LevelUpBurst extends StatefulWidget {
  const _LevelUpBurst({required this.newLevel, required this.onDone});
  final int newLevel;
  final VoidCallback onDone;

  @override
  State<_LevelUpBurst> createState() => _LevelUpBurstState();
}

class _LevelUpBurstState extends State<_LevelUpBurst>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..forward();
    _ctrl.addStatusListener((status) {
      if (status == AnimationStatus.completed) widget.onDone();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final yaru = context.yaru;
    final l10n = AppLocalizations.of(context)!;
    final levelName = _localizedLevelName(l10n, widget.newLevel);

    final fadeIn = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0, 0.18, curve: Curves.easeOut),
    );
    final fadeOut = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.78, 1.0, curve: Curves.easeIn),
    );
    final pop = TweenSequence([
      TweenSequenceItem(
        tween: Tween(begin: 0.4, end: 1.15)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 22,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.15, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 12,
      ),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 50),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.85)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 16,
      ),
    ]).animate(_ctrl);

    return GestureDetector(
      onTap: widget.onDone,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, _) {
          final alpha = (fadeIn.value - fadeOut.value).clamp(0.0, 1.0);
          return Container(
            color: Colors.black.withValues(alpha: 0.55 * alpha),
            alignment: Alignment.center,
            child: Opacity(
              opacity: alpha,
              child: Transform.scale(
                scale: pop.value,
                child: _Card(
                  yaru: yaru,
                  l10n: l10n,
                  level: widget.newLevel,
                  name: levelName,
                  pulse: _ctrl.value,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({
    required this.yaru,
    required this.l10n,
    required this.level,
    required this.name,
    required this.pulse,
  });
  final YaruTheme yaru;
  final AppLocalizations l10n;
  final int level;
  final String name;
  final double pulse;

  @override
  Widget build(BuildContext context) {
    final ringAngle = pulse * math.pi * 2;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 32),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: yaru.neonGradient,
        boxShadow: [
          BoxShadow(
            color: yaru.accent.withValues(alpha: 0.55),
            blurRadius: 80,
            spreadRadius: -10,
          ),
          BoxShadow(
            color: yaru.sparkle.withValues(alpha: 0.35),
            blurRadius: 60,
            spreadRadius: -20,
            offset: const Offset(0, 24),
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: YaruColors.bgDark1,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 120,
              height: 120,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Transform.rotate(
                    angle: ringAngle,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: yaru.aiOrbGradient,
                      ),
                    ),
                  ),
                  Container(
                    width: 96,
                    height: 96,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: YaruColors.bgDark1,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$level',
                      style: const TextStyle(
                        fontSize: 56,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Text(
              l10n.levelUpTitle,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: YaruColors.cyan,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              l10n.levelUpMessage(level, name),
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _localizedLevelName(AppLocalizations l10n, int level) {
  return switch (level) {
    1 => l10n.levelName1,
    2 => l10n.levelName2,
    3 => l10n.levelName3,
    4 => l10n.levelName4,
    5 => l10n.levelName5,
    6 => l10n.levelName6,
    7 => l10n.levelName7,
    8 => l10n.levelName8,
    _ => l10n.levelNameHigh(level),
  };
}

// Hook used by the home shell.
extension LevelUpGamificationServiceLink on GamificationService {
  // Placeholder so importing `GamificationService` from this file
  // (for type-only reference) keeps tree-shaking simple.
}
