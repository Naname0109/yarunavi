import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/category.dart' as model;
import '../providers/category_provider.dart';
import '../providers/task_provider.dart';
import '../utils/date_utils.dart' as app_date;
import '../widgets/banner_ad_widget.dart';
import '../widgets/filter_tabs.dart';
import '../widgets/responsive_wrapper.dart';
import '../widgets/task_card.dart';
import '../widgets/ai_sort_button.dart';
import '../widgets/task_form_sheet.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final tasksAsync = ref.watch(tasksProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final currentFilter = ref.watch(filterProvider);

    // カテゴリをMapに変換
    final categoryMap = <int, model.Category>{};
    categoriesAsync.whenData((categories) {
      for (final c in categories) {
        if (c.id != null) categoryMap[c.id!] = c;
      }
    });

    // 今日の日付表示
    final todayStr = DateFormat.yMMMd(locale).format(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: Text(todayStr),
        actions: [
          const AiSortButton(),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.settings)),
              );
            },
            tooltip: l10n.settings,
          ),
        ],
      ),
      body: ResponsiveWrapper(
        child: Column(
          children: [
            const FilterTabs(),
            const SizedBox(height: 8),
            Expanded(
              child: tasksAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(child: Text('$error')),
                data: (tasks) {
                  if (tasks.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.checklist,
                            size: 64,
                            color: Theme.of(context).colorScheme.outline,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _getEmptyMessage(currentFilter, l10n),
                            style: TextStyle(
                              fontSize: 16,
                              color: Theme.of(context).colorScheme.outline,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.only(bottom: 80),
                    itemCount: tasks.length,
                    itemBuilder: (context, index) {
                      final task = tasks[index];
                      final category = task.categoryId != null
                          ? categoryMap[task.categoryId]
                          : null;

                      return TaskCard(
                        task: task,
                        category: category,
                        onTap: () {
                          TaskFormSheet.show(context, task: task);
                        },
                        onToggleComplete: () async {
                          final newTask = await ref
                              .read(tasksProvider.notifier)
                              .completeTask(task);
                          if (newTask != null && context.mounted) {
                            final dateStr = app_date.formatRelativeDate(
                              newTask.dueDate,
                              l10n,
                              locale,
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  l10n.recurringTaskCreated(dateStr),
                                ),
                              ),
                            );
                          }
                        },
                        onDelete: () {
                          ref.read(tasksProvider.notifier).deleteTask(task.id!);
                        },
                      );
                    },
                  );
                },
              ),
            ),
            const BannerAdWidget(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          TaskFormSheet.show(context);
        },
        tooltip: l10n.addTask,
        child: const Icon(Icons.add),
      ),
    );
  }

  String _getEmptyMessage(String filter, AppLocalizations l10n) {
    switch (filter) {
      case 'today':
        return l10n.emptyTodayMessage;
      case 'thisWeek':
        return l10n.emptyWeekMessage;
      case 'overdue':
        return l10n.emptyOverdueMessage;
      case 'completed':
        return l10n.emptyCompletedMessage;
      case 'all':
      default:
        return l10n.emptyTaskMessage;
    }
  }
}
