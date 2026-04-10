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
import '../utils/notification_utils.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => CalendarScreenState();
}

class CalendarScreenState extends ConsumerState<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

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
        final byDue = <DateTime, List<Task>>{};
        final byRange = <DateTime, List<Task>>{};
        for (final t in tasks) {
          final dueKey =
              DateTime(t.dueDate.year, t.dueDate.month, t.dueDate.day);
          byDue.putIfAbsent(dueKey, () => []).add(t);
          if (t.recommendedStart != null && t.recommendedEnd != null) {
            var d = DateTime(t.recommendedStart!.year,
                t.recommendedStart!.month, t.recommendedStart!.day);
            final end = DateTime(t.recommendedEnd!.year,
                t.recommendedEnd!.month, t.recommendedEnd!.day);
            while (!d.isAfter(end)) {
              byRange.putIfAbsent(d, () => []).add(t);
              d = d.add(const Duration(days: 1));
            }
          }
        }

        final selectedDayNorm = _selectedDay != null
            ? DateTime(
                _selectedDay!.year,
                _selectedDay!.month,
                _selectedDay!.day,
              )
            : null;
        final selectedRecommended = selectedDayNorm != null
            ? (byRange[selectedDayNorm] ?? <Task>[])
                .where((t) => !t.isCompleted)
                .toList()
            : <Task>[];
        final selectedRecIds = selectedRecommended.map((t) => t.id).toSet();
        final selectedDueOnly = selectedDayNorm != null
            ? (byDue[selectedDayNorm] ?? <Task>[])
                .where(
                    (t) => !t.isCompleted && !selectedRecIds.contains(t.id))
                .toList()
            : <Task>[];
        final hasAny =
            selectedRecommended.isNotEmpty || selectedDueOnly.isNotEmpty;

        return Column(
          children: [
            // --- 月カレンダー（上半分） ---
            TableCalendar<Task>(
              firstDay: DateTime(2020),
              lastDay: DateTime(2100),
              focusedDay: _focusedDay,
              calendarFormat: CalendarFormat.month,
              availableCalendarFormats: const {CalendarFormat.month: 'Month'},
              startingDayOfWeek: StartingDayOfWeek.monday,
              locale: locale,
              rowHeight: 56,
              daysOfWeekHeight: 24,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },
              onPageChanged: (focusedDay) {
                setState(() {
                  _focusedDay = focusedDay;
                });
              },
              eventLoader: (day) {
                final key = DateTime(day.year, day.month, day.day);
                return byDue[key] ?? [];
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
                defaultBuilder: (context, day, focusedDay) => _buildDayCell(
                  day, byDue, byRange, theme, isDark, false, false),
                todayBuilder: (context, day, focusedDay) => _buildDayCell(
                  day, byDue, byRange, theme, isDark, true, false),
                selectedBuilder: (context, day, focusedDay) => _buildDayCell(
                  day, byDue, byRange, theme, isDark, false, true),
              ),
              calendarStyle: const CalendarStyle(
                outsideDaysVisible: false,
                cellMargin: EdgeInsets.zero,
                cellPadding: EdgeInsets.zero,
              ),
            ),
            Divider(height: 1, color: theme.dividerColor),
            // --- 選択日のタスクリスト（下半分） ---
            Expanded(
              child: !hasAny
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.event_available,
                            size: 48,
                            color: theme.colorScheme.outline,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            l10n.calendarNoTasks,
                            style: TextStyle(
                              fontSize: 15,
                              color: theme.colorScheme.outline,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 4,
                      ),
                      children: [
                        if (selectedRecommended.isNotEmpty) ...[
                          _sectionHeader(theme, l10n.calendarSectionRecommended),
                          ...selectedRecommended.map(
                            (t) => _buildTaskTile(
                                t, categoryMap, l10n, locale),
                          ),
                        ],
                        if (selectedDueOnly.isNotEmpty) ...[
                          _sectionHeader(theme, l10n.calendarSectionDue),
                          ...selectedDueOnly.map(
                            (t) => _buildTaskTile(
                                t, categoryMap, l10n, locale),
                          ),
                        ],
                      ],
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _sectionHeader(ThemeData theme, String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 4),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.primary,
        ),
      ),
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

  /// カスタム日付セル: 推奨期間バー + 期限マーク
  Widget _buildDayCell(
    DateTime day,
    Map<DateTime, List<Task>> byDue,
    Map<DateTime, List<Task>> byRange,
    ThemeData theme,
    bool isDark,
    bool isToday,
    bool isSelected,
  ) {
    final key = DateTime(day.year, day.month, day.day);
    // 推奨期間内のタスク
    final rangeTasks = (byRange[key] ?? [])
        .where((t) => !t.isCompleted)
        .toList()
      ..sort((a, b) => a.priority.compareTo(b.priority));
    final rangeIds = rangeTasks.map((t) => t.id).toSet();
    // 期限のみ (AI未整理) のタスク
    final dueOnlyTasks = (byDue[key] ?? [])
        .where((t) => !t.isCompleted && !rangeIds.contains(t.id))
        .toList();
    final displayTasks = [...rangeTasks, ...dueOnlyTasks];
    final hasDueMark = (byDue[key] ?? []).any((t) => !t.isCompleted);

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
          // 日付番号 (期限日には ▼ マーク)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${day.day}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isToday || isSelected
                      ? FontWeight.bold
                      : FontWeight.normal,
                  color: isSelected || isToday
                      ? theme.colorScheme.primary
                      : null,
                ),
              ),
              if (hasDueMark) ...[
                const SizedBox(width: 1),
                Text(
                  '▼',
                  style: TextStyle(
                    fontSize: 8,
                    color: theme.colorScheme.outline,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 1),
          // タスクバー (最大2件)
          ...displayTasks.take(2).map((task) {
            return _buildTaskBar(task, day, isDark);
          }),
          if (displayTasks.length > 2)
            Text(
              '+${displayTasks.length - 2}',
              style: TextStyle(fontSize: 8, color: theme.colorScheme.outline),
            ),
        ],
      ),
    );
  }

  Widget _buildTaskBar(Task task, DateTime day, bool isDark) {
    final hasRange =
        task.recommendedStart != null && task.recommendedEnd != null;
    final start = hasRange
        ? DateTime(task.recommendedStart!.year, task.recommendedStart!.month,
            task.recommendedStart!.day)
        : null;
    final end = hasRange
        ? DateTime(task.recommendedEnd!.year, task.recommendedEnd!.month,
            task.recommendedEnd!.day)
        : null;
    final key = DateTime(day.year, day.month, day.day);
    final isStart = start != null && key.isAtSameMomentAs(start);
    final isEnd = end != null && key.isAtSameMomentAs(end);
    final isSingle = isStart && isEnd;
    final isDueOnly = !hasRange;

    final Color baseColor;
    if (isDueOnly) {
      baseColor = Colors.grey.shade500;
    } else if (task.priority == 0) {
      baseColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;
    } else {
      baseColor = AppColors.getPriorityColor(task.priority, task.dueDate);
    }

    final radius = const Radius.circular(6);
    final borderRadius = isSingle
        ? BorderRadius.all(radius)
        : isStart
            ? BorderRadius.only(topLeft: radius, bottomLeft: radius)
            : isEnd
                ? BorderRadius.only(topRight: radius, bottomRight: radius)
                : BorderRadius.zero;

    final showText = isStart || isSingle || isDueOnly;
    final hasNotify =
        getScheduledNotificationDates(task.dueDate, task.notifySettings)
            .isNotEmpty;
    final label = hasNotify ? '🔔${task.title}' : task.title;

    return Container(
      margin: const EdgeInsets.only(top: 1),
      height: 12,
      decoration: BoxDecoration(
        color: baseColor.withValues(alpha: 0.22),
        borderRadius: borderRadius,
      ),
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: showText
          ? Text(
              label,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: baseColor,
                height: 1.0,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )
          : null,
    );
  }
}
