import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/task.dart';
import '../models/category.dart' as model;
import '../providers/category_provider.dart';
import '../providers/task_provider.dart';
import '../theme/colors.dart';
import '../widgets/task_card.dart';
import '../widgets/task_form_sheet.dart';
import '../utils/date_utils.dart' as app_date;

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  final CalendarFormat _calendarFormat = CalendarFormat.month;

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final tasksAsync = ref.watch(tasksProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final categoryMap = <int, model.Category>{};
    categoriesAsync.whenData((categories) {
      for (final c in categories) {
        if (c.id != null) categoryMap[c.id!] = c;
      }
    });

    return tasksAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
      data: (tasks) {
        // 全タスク（完了含む）でカレンダーマーカー構築
        final allTasks = tasks;
        final tasksByDate = <DateTime, List<Task>>{};
        for (final t in allTasks) {
          final key =
              DateTime(t.dueDate.year, t.dueDate.month, t.dueDate.day);
          tasksByDate.putIfAbsent(key, () => []).add(t);
        }

        final selectedDayNorm = _selectedDay != null
            ? DateTime(
                _selectedDay!.year, _selectedDay!.month, _selectedDay!.day)
            : null;
        final selectedTasks = selectedDayNorm != null
            ? (tasksByDate[selectedDayNorm] ?? [])
            : <Task>[];

        return Column(
          children: [
            TableCalendar<Task>(
              firstDay: DateTime(2020),
              lastDay: DateTime(2100),
              focusedDay: _focusedDay,
              calendarFormat: _calendarFormat,
              startingDayOfWeek: StartingDayOfWeek.monday,
              locale: locale,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },
              onFormatChanged: (_) {},
              onPageChanged: (focusedDay) {
                _focusedDay = focusedDay;
              },
              eventLoader: (day) {
                final key = DateTime(day.year, day.month, day.day);
                return tasksByDate[key] ?? [];
              },
              calendarBuilders: CalendarBuilders(
                markerBuilder: (context, date, events) {
                  if (events.isEmpty) return null;
                  return Positioned(
                    bottom: 1,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: events.take(4).map((task) {
                        final color = AppColors.getPriorityColor(
                            task.priority, task.dueDate);
                        return Container(
                          width: events.length > 3 ? 5 : 6,
                          height: events.length > 3 ? 5 : 6,
                          margin: const EdgeInsets.symmetric(horizontal: 0.5),
                          decoration: BoxDecoration(
                            color: task.isCompleted
                                ? theme.colorScheme.outline.withValues(alpha: 0.3)
                                : color,
                            shape: BoxShape.circle,
                          ),
                        );
                      }).toList(),
                    ),
                  );
                },
              ),
              calendarStyle: CalendarStyle(
                todayDecoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                selectedDecoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                todayTextStyle: TextStyle(
                  color: isDark ? Colors.white : Colors.black,
                  fontWeight: FontWeight.bold,
                ),
                outsideDaysVisible: false,
              ),
              headerStyle: HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: theme.textTheme.titleMedium!,
              ),
            ),
            const Divider(height: 1),
            // 選択日のタスクリスト
            Expanded(
              child: selectedTasks.isEmpty
                  ? const SizedBox.shrink()
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      itemCount: selectedTasks.length,
                      itemBuilder: (context, index) {
                        final task = selectedTasks[index];
                        final category = task.categoryId != null
                            ? categoryMap[task.categoryId]
                            : null;
                        return TaskCard(
                          task: task,
                          category: category,
                          onTap: () =>
                              TaskFormSheet.show(context, task: task),
                          onToggleComplete: () async {
                            final newTask = await ref
                                .read(tasksProvider.notifier)
                                .completeTask(task);
                            if (newTask != null && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(l10n.recurringTaskCreated(
                                    app_date.formatRelativeDate(
                                        newTask.dueDate, l10n, locale),
                                  )),
                                ),
                              );
                            }
                          },
                          onDelete: () {
                            ref
                                .read(tasksProvider.notifier)
                                .deleteTask(task.id!);
                          },
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}
