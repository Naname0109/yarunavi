import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/generated/app_localizations.dart';

/// ホーム画面のメインタブ切替コールバック
typedef OnTabChanged = void Function(int tabIndex);

class FilterTabs extends ConsumerWidget {
  const FilterTabs({super.key, required this.onTabChanged, required this.currentTab});

  final OnTabChanged onTabChanged;
  final int currentTab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    final tabs = [
      (0, l10n.tabTodo, Icons.list_alt),
      (1, l10n.tabCalendar, Icons.calendar_month),
      (2, l10n.completed, Icons.check_circle_outline),
    ];

    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: tabs.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final (tabIndex, label, icon) = tabs[index];
          final isSelected = currentTab == tabIndex;

          return FilterChip(
            avatar: Icon(icon, size: 18),
            label: Text(label),
            selected: isSelected,
            onSelected: (_) => onTabChanged(tabIndex),
            showCheckmark: false,
          );
        },
      ),
    );
  }
}
