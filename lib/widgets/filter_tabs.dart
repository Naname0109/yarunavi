import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/generated/app_localizations.dart';
import '../providers/task_provider.dart';

class FilterTabs extends ConsumerWidget {
  const FilterTabs({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final currentFilter = ref.watch(filterProvider);

    final filters = [
      ('all', l10n.all),
      ('today', l10n.today),
      ('thisWeek', l10n.thisWeek),
      ('overdue', l10n.overdue),
      ('completed', l10n.completed),
    ];

    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: filters.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final (key, label) = filters[index];
          final isSelected = currentFilter == key;

          return FilterChip(
            label: Text(label),
            selected: isSelected,
            onSelected: (_) {
              ref.read(filterProvider.notifier).state = key;
            },
            showCheckmark: false,
          );
        },
      ),
    );
  }
}
