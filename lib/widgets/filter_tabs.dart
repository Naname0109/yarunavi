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
    with SingleTickerProviderStateMixin {
  late final AnimationController _bounceController;
  late final Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _bounceAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: -6), weight: 25),
      TweenSequenceItem(tween: Tween(begin: -6, end: 0), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 0, end: -3), weight: 25),
      TweenSequenceItem(tween: Tween(begin: -3, end: 0), weight: 25),
    ]).animate(CurvedAnimation(
      parent: _bounceController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  bool _isBouncing = false;

  void _syncBounce(bool highlight) {
    if (highlight && !_isBouncing) {
      _isBouncing = true;
      _bounceController.repeat();
    } else if (!highlight && _isBouncing) {
      _isBouncing = false;
      _bounceController.stop();
      _bounceController.reset();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final highlight = ref.watch(calendarHighlightProvider);

    _syncBounce(highlight);

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

          if (isCalendar && highlight && !isSelected) {
            chip = _CalendarHighlight(
              bounceAnimation: _bounceAnimation,
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

class _CalendarHighlight extends StatelessWidget {
  const _CalendarHighlight({
    required this.bounceAnimation,
    required this.hintText,
    required this.child,
  });

  final Animation<double> bounceAnimation;
  final String hintText;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: bounceAnimation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, bounceAnimation.value),
              child: child,
            );
          },
          child: child,
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
