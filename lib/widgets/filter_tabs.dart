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
  bool _isAnimating = false;
  final _calendarChipKey = GlobalKey();

  void _startRipple() {
    if (_isAnimating) return;
    _isAnimating = true;

    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _rippleController!.repeat();
    setState(() {});
  }

  void _stopRipple() {
    if (!_isAnimating) return;
    _isAnimating = false;
    _rippleController?.stop();
    _rippleController?.dispose();
    _rippleController = null;
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _rippleController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final highlight = ref.watch(calendarHighlightProvider);

    if (highlight && !_isAnimating) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && ref.read(calendarHighlightProvider)) _startRipple();
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
            key: isCalendar ? _calendarChipKey : Key('filter_tab_$tabIndex'),
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
            side: isCalendar && highlight && !isSelected
                ? BorderSide(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
                    width: 2,
                  )
                : null,
          );

          if (isCalendar && highlight && !isSelected && _isAnimating) {
            chip = _CalendarRippleHighlight(
              rippleController: _rippleController!,
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
    required this.hintText,
    required this.child,
  });

  final AnimationController rippleController;
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
          child: AnimatedBuilder(
            animation: rippleController,
            builder: (context, child) {
              return CustomPaint(
                painter: _EllipseRipplePainter(
                  progress: rippleController.value,
                  color: primaryColor,
                ),
                child: child,
              );
            },
            child: child,
          ),
        ),
        Container(
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
      ],
    );
  }
}

class _EllipseRipplePainter extends CustomPainter {
  _EllipseRipplePainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final baseRect = Rect.fromCenter(
      center: center,
      width: size.width,
      height: size.height,
    );

    for (var i = 0; i < 2; i++) {
      final t = (progress + i * 0.5) % 1.0;
      final scale = 1.0 + t * 0.5;
      final opacity = 0.6 * (1.0 - t);

      final rippleRect = Rect.fromCenter(
        center: center,
        width: baseRect.width * scale,
        height: baseRect.height * scale,
      );

      final paint = Paint()
        ..color = color.withValues(alpha: opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      final rrect = RRect.fromRectAndRadius(rippleRect, const Radius.circular(20));
      canvas.drawRRect(rrect, paint);
    }
  }

  @override
  bool shouldRepaint(_EllipseRipplePainter old) => old.progress != progress;
}
