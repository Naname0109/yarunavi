import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/generated/app_localizations.dart';
import 'ai_sort_button.dart';

typedef OnTabChanged = void Function(int tabIndex);

class FilterTabs extends ConsumerStatefulWidget {
  const FilterTabs(
      {super.key, required this.onTabChanged, required this.currentTab});

  final OnTabChanged onTabChanged;
  final int currentTab;

  @override
  ConsumerState<FilterTabs> createState() => _FilterTabsState();
}

class _FilterTabsState extends ConsumerState<FilterTabs>
    with TickerProviderStateMixin {
  AnimationController? _rippleController;
  AnimationController? _badgeFadeController;
  bool _isAnimating = false;
  int _cycleCount = 0;
  static const _maxCycles = 3;

  void _startRipple() {
    if (_isAnimating) return;
    _isAnimating = true;
    _cycleCount = 0;

    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _rippleController!.addStatusListener(_onRippleStatus);
    _rippleController!.forward();

    _badgeFadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
      value: 1.0,
    );
    Future.delayed(const Duration(seconds: 3), () {
      if (_isAnimating) {
        _badgeFadeController?.reverse();
      }
    });
  }

  void _onRippleStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      _cycleCount++;
      if (_cycleCount < _maxCycles && _isAnimating) {
        _rippleController?.forward(from: 0);
      } else {
        _stopRipple();
      }
    }
  }

  void _stopRipple() {
    if (!_isAnimating) return;
    _isAnimating = false;
    _rippleController?.removeStatusListener(_onRippleStatus);
    _rippleController?.dispose();
    _rippleController = null;
    _badgeFadeController?.dispose();
    _badgeFadeController = null;
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _rippleController?.removeStatusListener(_onRippleStatus);
    _rippleController?.dispose();
    _badgeFadeController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final highlight = ref.watch(calendarHighlightProvider);

    if (highlight && !_isAnimating) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && highlight) _startRipple();
      });
    } else if (!highlight && _isAnimating) {
      _stopRipple();
    }

    final tabs = [
      (0, l10n.tabTodo, Icons.list_alt),
      (1, l10n.tabCalendar, Icons.calendar_month),
      (2, l10n.completed, Icons.check_circle_outline),
    ];

    return SizedBox(
      height: highlight ? 64 : 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: tabs.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final (tabIndex, label, icon) = tabs[index];
          final isSelected = widget.currentTab == tabIndex;
          final isCalendar = tabIndex == 1;

          Widget chip = FilterChip(
            key: Key('filter_tab_$tabIndex'),
            avatar: Icon(icon, size: 18),
            label: Text(label),
            selected: isSelected,
            onSelected: (_) {
              if (isCalendar && highlight) {
                ref.read(calendarHighlightProvider.notifier).state = false;
              }
              widget.onTabChanged(tabIndex);
            },
            showCheckmark: false,
          );

          if (isCalendar && highlight && !isSelected && _isAnimating) {
            chip = _CalendarRippleHighlight(
              rippleController: _rippleController!,
              badgeFadeController: _badgeFadeController!,
              hintText: l10n.calendarHintBubble,
              child: chip,
            );
          }

          return chip;
        },
      ),
    );
  }
}

class _CalendarRippleHighlight extends StatelessWidget {
  const _CalendarRippleHighlight({
    required this.rippleController,
    required this.badgeFadeController,
    required this.hintText,
    required this.child,
  });

  final AnimationController rippleController;
  final AnimationController badgeFadeController;
  final String hintText;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        RepaintBoundary(
          child: CustomPaint(
            painter: _RipplePainter(
              animation: rippleController,
              color: primaryColor,
            ),
            child: child,
          ),
        ),
        FadeTransition(
          opacity: badgeFadeController,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              hintText,
              style: TextStyle(
                fontSize: 10,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _RipplePainter extends CustomPainter {
  _RipplePainter({required this.animation, required this.color})
      : super(repaint: animation);

  final Animation<double> animation;
  final Color color;

  static const _minRadius = 12.0;
  static const _maxRadius = 40.0;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    for (var i = 0; i < 2; i++) {
      final offset = i * 0.5;
      final t = (animation.value + offset) % 1.0;
      final radius = _minRadius + (_maxRadius - _minRadius) * t;
      final opacity = 0.4 * (1.0 - t);

      final paint = Paint()
        ..color = color.withValues(alpha: opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      canvas.drawCircle(center, math.max(radius, _minRadius), paint);
    }
  }

  @override
  bool shouldRepaint(_RipplePainter old) => true;
}
