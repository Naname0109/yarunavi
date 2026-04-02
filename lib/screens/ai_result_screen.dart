import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';
import '../services/ai_service.dart';
import '../theme/colors.dart';
import '../widgets/ai_sort_button.dart';
import '../widgets/responsive_wrapper.dart';

class AiResultScreen extends ConsumerWidget {
  const AiResultScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final tasksAsync = ref.watch(tasksProvider);
    final aiResults = ref.watch(aiSortResultsProvider);
    final sortedAtStr =
        DateFormat.yMMMd(locale).add_Hm().format(DateTime.now());

    // AI結果をtaskIdでマップ化
    final resultsMap = <int, AiSortResult>{};
    for (final r in aiResults) {
      resultsMap[r.taskId] = r;
    }

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
            final incompleteTasks =
                tasks.where((t) => !t.isCompleted && t.priority > 0).toList();

            final groups = <int, List<Task>>{};
            for (final t in incompleteTasks) {
              groups.putIfAbsent(t.priority, () => []).add(t);
            }

            final isDark = Theme.of(context).brightness == Brightness.dark;

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
                  context, ref, l10n, locale,
                  l10n.aiPriorityUrgent, AppColors.priorityUrgent,
                  groups[1] ?? [], resultsMap,
                ),
                ..._buildPrioritySection(
                  context, ref, l10n, locale,
                  l10n.aiPriorityWarning, AppColors.priorityWarning,
                  groups[2] ?? [], resultsMap,
                ),
                ..._buildPrioritySection(
                  context, ref, l10n, locale,
                  l10n.aiPriorityNormal,
                  isDark ? AppColors.priorityNormalDark : AppColors.priorityNormal,
                  groups[3] ?? [], resultsMap,
                ),
                ..._buildPrioritySection(
                  context, ref, l10n, locale,
                  l10n.aiPriorityRelaxed,
                  isDark ? AppColors.priorityRelaxedDark : AppColors.priorityRelaxed,
                  groups[4] ?? [], resultsMap,
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
    WidgetRef ref,
    AppLocalizations l10n,
    String locale,
    String title,
    Color color,
    List<Task> tasks,
    Map<int, AiSortResult> resultsMap,
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
      ...tasks.map((task) {
        final result = task.id != null ? resultsMap[task.id] : null;
        final subtasks = locale == 'ja'
            ? (result?.suggestedSubtasksJa ?? [])
            : (result?.suggestedSubtasksEn ?? []);

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
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
                                color:
                                    Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                // サブタスク提案
                if (subtasks.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  const Divider(height: 1),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text('💡 ', style: TextStyle(fontSize: 14)),
                      Text(
                        l10n.aiSubtaskSuggestion,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ...subtasks.map((s) => Padding(
                        padding: const EdgeInsets.only(left: 24, top: 2),
                        child: Row(
                          children: [
                            const Text('• ', style: TextStyle(fontSize: 13)),
                            Expanded(
                              child:
                                  Text(s, style: const TextStyle(fontSize: 13)),
                            ),
                          ],
                        ),
                      )),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () => _addSubtasks(
                        context, ref, l10n, task, subtasks,
                      ),
                      icon: const Icon(Icons.add, size: 16),
                      label: Text(l10n.aiSubtaskAdd),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      }),
    ];
  }

  Future<void> _addSubtasks(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    Task originalTask,
    List<String> subtasks,
  ) async {
    final now = DateTime.now();
    // 期限切れの場合は今日から各サブタスクに1日ずつ割り振り
    final daysUntilDue = originalTask.dueDate.difference(now).inDays;
    final totalDays = daysUntilDue > 0 ? daysUntilDue : subtasks.length;
    final interval = (totalDays / subtasks.length).ceil().clamp(1, 365);

    for (var i = 0; i < subtasks.length; i++) {
      final subDueDate = now.add(Duration(days: (i + 1) * interval));
      final subTask = Task(
        title: subtasks[i],
        dueDate: daysUntilDue > 0 && subDueDate.isAfter(originalTask.dueDate)
            ? originalTask.dueDate
            : subDueDate,
        categoryId: originalTask.categoryId,
        importance: originalTask.importance,
        createdAt: now,
        updatedAt: now,
      );
      await ref.read(tasksProvider.notifier).addTask(subTask);
    }

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.aiSubtaskAdded)),
    );

    // 元タスクを完了にするか確認
    final shouldComplete = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.aiCompleteOriginal),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.markComplete),
          ),
        ],
      ),
    );

    if (shouldComplete == true) {
      await ref.read(tasksProvider.notifier).toggleComplete(originalTask);
    }
  }
}
