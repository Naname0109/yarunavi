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

enum _CalendarViewMode { recommended, due }

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => CalendarScreenState();
}

class CalendarScreenState extends ConsumerState<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  _CalendarViewMode _viewMode = _CalendarViewMode.recommended;

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
  }

  void goToToday() {
    setState(() {
      _focusedDay = DateTime.now();
      _selectedDay = DateTime.now();
    });
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
        final incompleteTasks = tasks.where((t) => !t.isCompleted).toList();

        // 期限日でグループ化
        final byDue = <DateTime, List<Task>>{};
        // 推奨日でグループ化（推奨日がないタスクはdue_dateで代替）
        final byRecommended = <DateTime, List<Task>>{};
        for (final t in incompleteTasks) {
          final dueKey =
              DateTime(t.dueDate.year, t.dueDate.month, t.dueDate.day);
          byDue.putIfAbsent(dueKey, () => []).add(t);
          final recDate = t.recommendedDate ?? t.dueDate;
          final recKey = DateTime(recDate.year, recDate.month, recDate.day);
          byRecommended.putIfAbsent(recKey, () => []).add(t);
        }

        // viewModeに応じたマップを使用
        final activeMap = _viewMode == _CalendarViewMode.recommended
            ? byRecommended
            : byDue;

        final selectedDayNorm = _selectedDay != null
            ? DateTime(
                _selectedDay!.year, _selectedDay!.month, _selectedDay!.day)
            : null;
        final selectedTasks = selectedDayNorm != null
            ? (activeMap[selectedDayNorm] ?? <Task>[])
            : <Task>[];

        return Column(
          children: [
            // --- SegmentedButton ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: SegmentedButton<_CalendarViewMode>(
                segments: [
                  ButtonSegment(
                    value: _CalendarViewMode.recommended,
                    label: Text(l10n.calendarViewRecommended),
                    icon: const Icon(Icons.push_pin, size: 16),
                  ),
                  ButtonSegment(
                    value: _CalendarViewMode.due,
                    label: Text(l10n.calendarViewDue),
                    icon: const Icon(Icons.schedule, size: 16),
                  ),
                ],
                selected: {_viewMode},
                onSelectionChanged: (set) {
                  setState(() => _viewMode = set.first);
                },
                style: SegmentedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ),
            // --- 月カレンダー ---
            TableCalendar<Task>(
              firstDay: DateTime(2020),
              lastDay: DateTime(2100),
              focusedDay: _focusedDay,
              calendarFormat: CalendarFormat.month,
              availableCalendarFormats: const {CalendarFormat.month: 'Month'},
              startingDayOfWeek: StartingDayOfWeek.monday,
              locale: locale,
              rowHeight: 48,
              daysOfWeekHeight: 24,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },
              onPageChanged: (focusedDay) {
                setState(() => _focusedDay = focusedDay);
              },
              eventLoader: (day) {
                final key = DateTime(day.year, day.month, day.day);
                return activeMap[key] ?? [];
              },
              headerStyle: HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: theme.textTheme.titleMedium!.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                leftChevronIcon: Icon(
                  Icons.chevron_left,
                  color: theme.colorScheme.onSurface,
                ),
                rightChevronIcon: Icon(
                  Icons.chevron_right,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              calendarBuilders: CalendarBuilders(
                defaultBuilder: (context, day, focusedDay) =>
                    _buildDayCell(day, activeMap, theme, isDark, false, false),
                todayBuilder: (context, day, focusedDay) =>
                    _buildDayCell(day, activeMap, theme, isDark, true, false),
                selectedBuilder: (context, day, focusedDay) =>
                    _buildDayCell(day, activeMap, theme, isDark, false, true),
              ),
              calendarStyle: const CalendarStyle(
                outsideDaysVisible: false,
                cellMargin: EdgeInsets.zero,
                cellPadding: EdgeInsets.zero,
              ),
            ),
            Divider(height: 1, color: theme.dividerColor),
            // --- 選択日のタスクリスト ---
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: selectedTasks.isEmpty
                    ? Center(
                        key: const ValueKey('empty'),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.event_available,
                                size: 48, color: theme.colorScheme.outline),
                            const SizedBox(height: 12),
                            Text(l10n.calendarNoTasks,
                                style: TextStyle(
                                    fontSize: 15,
                                    color: theme.colorScheme.outline)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        key: ValueKey('$_viewMode-$selectedDayNorm'),
                        padding: EdgeInsets.only(
                            left: 4, right: 4, top: 4,
                            bottom: 100 + MediaQuery.of(context).padding.bottom),
                        itemCount: selectedTasks.length,
                        itemBuilder: (context, index) =>
                            _buildTaskTile(selectedTasks[index], categoryMap, l10n, locale),
                      ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTaskTile(
    Task task,
    Map<int, model.Category> categoryMap,
    AppLocalizations l10n,
    String locale,
  ) {
    final category =
        task.categoryId != null ? categoryMap[task.categoryId] : null;
    return TaskCard(
      task: task,
      category: category,
      onTap: () => TaskFormSheet.show(context, task: task),
      onToggleComplete: () async {
        final newTask =
            await ref.read(tasksProvider.notifier).completeTask(task);
        if (!mounted) return;
        if (newTask != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                l10n.recurringTaskCreated(
                  app_date.formatRelativeDate(newTask.dueDate, l10n, locale),
                ),
              ),
            ),
          );
        }
      },
      onDelete: () {
        ref.read(tasksProvider.notifier).deleteTask(task.id!);
      },
    );
  }

  /// カスタム日付セル
  Widget _buildDayCell(
    DateTime day,
    Map<DateTime, List<Task>> activeMap,
    ThemeData theme,
    bool isDark,
    bool isToday,
    bool isSelected,
  ) {
    final key = DateTime(day.year, day.month, day.day);
    final displayTasks = List.of(activeMap[key] ?? <Task>[])
      ..sort((a, b) => a.priority.compareTo(b.priority));

    return Container(
      margin: EdgeInsets.zero,
      decoration: BoxDecoration(
        color: isSelected
            ? theme.colorScheme.primary.withValues(alpha: 0.15)
            : isToday
                ? theme.colorScheme.primary.withValues(alpha: 0.06)
                : null,
        borderRadius: BorderRadius.circular(6),
        border: isToday
            ? Border.all(color: theme.colorScheme.primary, width: 1.5)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 2),
          // 日付番号
          Text(
            '${day.day}',
            style: TextStyle(
              fontSize: 12,
              fontWeight:
                  isToday || isSelected ? FontWeight.bold : FontWeight.normal,
              color:
                  isSelected || isToday ? theme.colorScheme.primary : null,
            ),
          ),
          // タスク表示（最大1件 + N）
          if (displayTasks.isNotEmpty)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 1),
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
                      decoration: displayTasks.first.priority > 0
                          ? BoxDecoration(
                              color: _getTaskColor(displayTasks.first, isDark)
                                  .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(3),
                            )
                          : null,
                      child: Text(
                        displayTasks.first.title,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: _getTaskColor(displayTasks.first, isDark),
                          height: 1.1,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (displayTasks.length > 1)
                      Text(
                        '+${displayTasks.length - 1}',
                        style: TextStyle(
                            fontSize: 10, color: theme.colorScheme.outline),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Color _getTaskColor(Task task, bool isDark) {
    if (task.priority == 0) {
      return isDark ? Colors.grey.shade400 : Colors.grey.shade600;
    }
    return AppColors.getPriorityColor(task.priority, task.dueDate,
        isDark: isDark);
  }
}
