import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';
import '../theme/colors.dart';
import '../widgets/responsive_wrapper.dart';

class AiResultScreen extends ConsumerWidget {
  const AiResultScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final tasksAsync = ref.watch(tasksProvider);
    final sortedAtStr = DateFormat.yMMMd(locale)
        .add_Hm()
        .format(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.aiResultTitle),
        automaticallyImplyLeading: false,
      ),
      body: ResponsiveWrapper(
        child: tasksAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('$e')),
          data: (tasks) {
            // 未完了タスクをpriority別にグループ化
            final incompleteTasks =
                tasks.where((t) => !t.isCompleted && t.priority > 0).toList();

            final groups = <int, List<Task>>{};
            for (final t in incompleteTasks) {
              groups.putIfAbsent(t.priority, () => []).add(t);
            }

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  l10n.aiResultSortedAt(sortedAtStr),
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
                const SizedBox(height: 16),
                ..._buildPrioritySection(
                  context,
                  l10n.aiPriorityUrgent,
                  AppColors.priorityUrgent,
                  groups[1] ?? [],
                  locale,
                ),
                ..._buildPrioritySection(
                  context,
                  l10n.aiPriorityWarning,
                  AppColors.priorityWarning,
                  groups[2] ?? [],
                  locale,
                ),
                ..._buildPrioritySection(
                  context,
                  l10n.aiPriorityNormal,
                  Theme.of(context).brightness == Brightness.dark
                      ? AppColors.priorityNormalDark
                      : AppColors.priorityNormal,
                  groups[3] ?? [],
                  locale,
                ),
                ..._buildPrioritySection(
                  context,
                  l10n.aiPriorityRelaxed,
                  Theme.of(context).brightness == Brightness.dark
                      ? AppColors.priorityRelaxedDark
                      : AppColors.priorityRelaxed,
                  groups[4] ?? [],
                  locale,
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () => context.go('/home'),
                  icon: const Icon(Icons.home),
                  label: Text(l10n.backToHome),
                ),
                const SizedBox(height: 32),
              ],
            );
          },
        ),
      ),
    );
  }

  List<Widget> _buildPrioritySection(
    BuildContext context,
    String title,
    Color color,
    List<Task> tasks,
    String locale,
  ) {
    if (tasks.isEmpty) return [];

    return [
      Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 8),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ),
      ...tasks.map((task) => Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 4,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (task.aiComment != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            task.aiComment!,
                            style: TextStyle(
                              fontSize: 13,
                              color: Theme.of(context).colorScheme.outline,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          )),
    ];
  }
}
