import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/category.dart' as model;
import '../models/task.dart';
import '../providers/category_provider.dart';
import '../providers/task_provider.dart';
import '../utils/date_utils.dart' as app_date;
import '../widgets/banner_ad_widget.dart';
import '../widgets/coach_overlay.dart';
import '../widgets/filter_tabs.dart';
import '../widgets/responsive_wrapper.dart';
import '../widgets/task_card.dart';
import '../widgets/ai_sort_button.dart';
import '../widgets/task_form_sheet.dart';
import 'calendar_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key, this.initialTab = 0});
  final int initialTab;

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _fabKey = GlobalKey();
  final _aiSortKey = GlobalKey();
  final _filterTabsKey = GlobalKey();
  final _calendarKey = GlobalKey<CalendarScreenState>();
  late int _tabIndex = widget.initialTab.clamp(0, 2);

  @override
  void initState() {
    super.initState();
    // フィルターを初期タブに合わせる
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncFilter();
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      maybeShowCoachMarks(
        context,
        steps: [
          CoachStep(targetKey: _fabKey, message: l10n.coachAddTask),
          CoachStep(targetKey: _aiSortKey, message: l10n.coachAiSort),
        ],
      );
    });
  }

  void _syncFilter() {
    switch (_tabIndex) {
      case 0:
      case 1: // カレンダータブも未完了タスク基準
        ref.read(filterProvider.notifier).state = 'all';
      case 2:
        ref.read(filterProvider.notifier).state = 'completed';
    }
  }

  void _onTabChanged(int index) {
    setState(() => _tabIndex = index);
    _syncFilter();
    if (index == 1) {
      ref.read(calendarHighlightProvider.notifier).state = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final tasksAsync = ref.watch(tasksProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final showAiBanner = ref.watch(aiCompleteBannerProvider);
    final isCalendarTab = _tabIndex == 1;

    final categoryMap = <int, model.Category>{};
    categoriesAsync.whenData((categories) {
      for (final c in categories) {
        if (c.id != null) categoryMap[c.id!] = c;
      }
    });

    final completedCount =
        ref.watch(completedTaskCountProvider).valueOrNull ?? 0;
    final allOverdue =
        ref.watch(allTasksOverdueProvider).valueOrNull ?? false;

    final todayStr = DateFormat.yMMMd(locale).format(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: Text(todayStr),
        actions: [
          if (isCalendarTab)
            IconButton(
              icon: const Icon(Icons.today),
              tooltip: l10n.calendarToday,
              onPressed: () => _calendarKey.currentState?.goToToday(),
            ),
          AiSortButton(key: _aiSortKey),
          IconButton(
            key: const Key('ai_history_button'),
            icon: const Icon(Icons.history),
            onPressed: () => context.push('/ai-history'),
            tooltip: l10n.aiHistoryTooltip,
          ),
          IconButton(
            key: const Key('settings_button'),
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/settings'),
            tooltip: l10n.settings,
          ),
        ],
      ),
      body: ResponsiveWrapper(
        child: Column(
          children: [
            if (showAiBanner)
              MaterialBanner(
                content: Text(l10n.aiCompleteBanner),
                leading: const Icon(Icons.auto_awesome),
                actions: [
                  TextButton(
                    onPressed: () {
                      ref.read(aiCompleteBannerProvider.notifier).state = false;
                      context.push('/ai-result');
                    },
                    child: Text(l10n.aiResultTitle),
                  ),
                  TextButton(
                    onPressed: () {
                      ref.read(aiCompleteBannerProvider.notifier).state = false;
                    },
                    child: Text(l10n.cancel),
                  ),
                ],
              ),
            FilterTabs(
              key: _filterTabsKey,
              currentTab: _tabIndex,
              onTabChanged: _onTabChanged,
            ),
            const SizedBox(height: 8),
            Expanded(
              child: IndexedStack(
                index: _tabIndex,
                children: [
                  // Tab 0: やること（今日やること + その他）
                  _TodoTab(
                    tasksAsync: tasksAsync,
                    categoryMap: categoryMap,
                    l10n: l10n,
                    locale: locale,
                    completedCount: completedCount,
                    allOverdue: allOverdue,
                  ),
                  // Tab 1: カレンダー
                  CalendarScreen(key: _calendarKey),
                  // Tab 2: 完了済み
                  _CompletedTab(
                    tasksAsync: tasksAsync,
                    categoryMap: categoryMap,
                    l10n: l10n,
                    locale: locale,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const BannerAdWidget(),
      floatingActionButton: isCalendarTab
          ? null
          : FloatingActionButton(
              key: _fabKey,
              onPressed: () {
                HapticFeedback.selectionClick();
                TaskFormSheet.show(context);
              },
              tooltip: l10n.addTask,
              child: const Icon(Icons.add),
            ),
    );
  }
}

/// タスクを5セクションに分類する（今日/期限切れ/今週/来週/再来週以降）
({
  List<Task> today,
  List<Task> overdue,
  List<Task> thisWeek,
  List<Task> nextWeek,
  List<Task> later,
}) _splitTasks(List<Task> tasks) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final daysUntilSunday =
      now.weekday == DateTime.sunday ? 0 : DateTime.sunday - now.weekday;
  final endOfWeek = today.add(Duration(days: daysUntilSunday));
  final endOfNextWeek = endOfWeek.add(const Duration(days: 7));

  final todayList = <Task>[];
  final overdueList = <Task>[];
  final thisWeekList = <Task>[];
  final nextWeekList = <Task>[];
  final laterList = <Task>[];

  for (final t in tasks) {
    final dueDay = DateTime(t.dueDate.year, t.dueDate.month, t.dueDate.day);
    final recDay = t.recommendedDate != null
        ? DateTime(t.recommendedDate!.year, t.recommendedDate!.month,
            t.recommendedDate!.day)
        : null;
    final effectiveDay = recDay ?? dueDay;

    final isOverdue = dueDay.isBefore(today);
    final isDueToday = dueDay == today;
    final isPriority1 = t.priority == 1;
    final isRecToday = recDay != null && recDay == today;

    if (isOverdue) {
      overdueList.add(t);
    } else if (isDueToday || isPriority1 || isRecToday) {
      todayList.add(t);
    } else if (!effectiveDay.isAfter(endOfWeek)) {
      thisWeekList.add(t);
    } else if (!effectiveDay.isAfter(endOfNextWeek)) {
      nextWeekList.add(t);
    } else {
      laterList.add(t);
    }
  }

  todayList.sort((a, b) => a.priority.compareTo(b.priority));
  int Function(Task, Task) byDateThenPriority = (a, b) {
    final aDay = a.recommendedDate ?? a.dueDate;
    final bDay = b.recommendedDate ?? b.dueDate;
    final cmp = aDay.compareTo(bDay);
    return cmp != 0 ? cmp : a.priority.compareTo(b.priority);
  };
  thisWeekList.sort(byDateThenPriority);
  nextWeekList.sort(byDateThenPriority);
  laterList.sort(byDateThenPriority);
  overdueList.sort((a, b) => a.dueDate.compareTo(b.dueDate));

  return (
    today: todayList,
    overdue: overdueList,
    thisWeek: thisWeekList,
    nextWeek: nextWeekList,
    later: laterList,
  );
}

/// 日付ごとにタスクをグルーピング
Map<DateTime, List<Task>> _groupByDate(List<Task> tasks) {
  final map = <DateTime, List<Task>>{};
  for (final t in tasks) {
    final day = t.recommendedDate ?? t.dueDate;
    final key = DateTime(day.year, day.month, day.day);
    map.putIfAbsent(key, () => []).add(t);
  }
  return Map.fromEntries(
      map.entries.toList()..sort((a, b) => a.key.compareTo(b.key)));
}

/// 「やること」タブ: 今日 / 期限切れ / 今週 | 来週 | 再来週以降
class _TodoTab extends ConsumerStatefulWidget {
  const _TodoTab({
    required this.tasksAsync,
    required this.categoryMap,
    required this.l10n,
    required this.locale,
    required this.completedCount,
    required this.allOverdue,
  });

  final AsyncValue<List<Task>> tasksAsync;
  final Map<int, model.Category> categoryMap;
  final AppLocalizations l10n;
  final String locale;
  final int completedCount;
  final bool allOverdue;

  @override
  ConsumerState<_TodoTab> createState() => _TodoTabState();
}

class _TodoTabState extends ConsumerState<_TodoTab> {
  bool _overdueExpanded = false;
  int _weekTabIndex = 0;
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    final theme = Theme.of(context);

    return widget.tasksAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline,
                size: 48, color: theme.colorScheme.error),
            const SizedBox(height: 12),
            Text(l10n.taskLoadError,
                style: TextStyle(fontSize: 15, color: theme.colorScheme.error)),
          ],
        ),
      ),
      data: (tasks) {
        if (tasks.isEmpty) {
          if (widget.completedCount > 0) {
            return _AllCompleteCelebration(l10n: l10n);
          }
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.checklist,
                    size: 64, color: theme.colorScheme.outline),
                const SizedBox(height: 16),
                Text(l10n.emptyTaskMessage,
                    style: TextStyle(
                        fontSize: 16, color: theme.colorScheme.outline)),
              ],
            ),
          );
        }

        final split = _splitTasks(tasks);

        return RefreshIndicator(
          color: theme.colorScheme.primary,
          onRefresh: () async {
            ref.invalidate(tasksProvider);
            await ref.read(tasksProvider.future);
            if (mounted) HapticFeedback.mediumImpact();
          },
          child: Scrollbar(
            controller: _scrollController,
            thumbVisibility: true,
            child: ListView(
              controller: _scrollController,
              padding: const EdgeInsets.only(bottom: 80),
              children: [
                // 全タスク期限切れバナー
                if (widget.allOverdue) _AllExpiredBanner(l10n: l10n),

                // --- 今日やること（今週タブのみ表示） ---
                if (_weekTabIndex == 0) ...[
                  _SectionHeader(
                    title: l10n.todaySection,
                    icon: Icons.push_pin,
                    color: theme.colorScheme.error,
                  ),
                  if (split.today.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      child: Text(l10n.todaySectionEmpty,
                          style: TextStyle(
                              fontSize: 15,
                              color: theme.colorScheme.onSurfaceVariant)),
                    )
                  else
                    ..._buildTaskCards(split.today),

                  // --- 期限切れ（折りたたみ） ---
                  if (split.overdue.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _CollapsibleSection(
                      title: l10n.overdueSectionCount(split.overdue.length),
                      icon: Icons.warning_amber_rounded,
                      color: theme.colorScheme.error,
                      badgeCount: split.overdue.length,
                      expanded: _overdueExpanded,
                      onToggle: () =>
                          setState(() => _overdueExpanded = !_overdueExpanded),
                      children: _buildTaskCards(split.overdue),
                    ),
                  ],
                ],

                // --- 週タブバー ---
                const SizedBox(height: 8),
                _WeekTabBar(
                  selectedIndex: _weekTabIndex,
                  thisWeekCount: split.thisWeek.length,
                  nextWeekCount: split.nextWeek.length,
                  laterCount: split.later.length,
                  l10n: l10n,
                  onSelected: (i) => setState(() => _weekTabIndex = i),
                ),
                const SizedBox(height: 4),

                // --- 週タブコンテンツ ---
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: _buildWeekTabContent(split, l10n, theme),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildWeekTabContent(
    ({
      List<Task> today,
      List<Task> overdue,
      List<Task> thisWeek,
      List<Task> nextWeek,
      List<Task> later,
    }) split,
    AppLocalizations l10n,
    ThemeData theme,
  ) {
    final List<Task> tasks;
    final String emptyMessage;
    switch (_weekTabIndex) {
      case 1:
        tasks = split.nextWeek;
        emptyMessage = l10n.noTasksNextWeek;
      case 2:
        tasks = split.later;
        emptyMessage = l10n.noTasksLater;
      default:
        tasks = split.thisWeek;
        emptyMessage = l10n.emptyTaskMessage;
    }

    if (tasks.isEmpty) {
      return Padding(
        key: ValueKey('empty_$_weekTabIndex'),
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: Text(emptyMessage,
              style: TextStyle(
                  fontSize: 15, color: theme.colorScheme.onSurfaceVariant)),
        ),
      );
    }

    return Column(
      key: ValueKey('content_$_weekTabIndex'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _buildDateGroupedCards(tasks),
    );
  }

  List<Widget> _buildTaskCards(List<Task> tasks) {
    return tasks.asMap().entries.map((entry) {
      return _FadeInItem(
        key: ValueKey(entry.value.id),
        index: entry.key,
        child: _buildTaskCard(entry.value),
      );
    }).toList();
  }

  /// 日付サブヘッダー付きタスクカードリスト
  List<Widget> _buildDateGroupedCards(List<Task> tasks) {
    final groups = _groupByDate(tasks);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final widgets = <Widget>[];
    var idx = 0;

    for (final entry in groups.entries) {
      // 日付サブヘッダー
      widgets.add(_DateSubHeader(date: entry.key, today: today));
      for (final task in entry.value) {
        widgets.add(_FadeInItem(
          key: ValueKey(task.id),
          index: idx++,
          child: _buildTaskCard(task),
        ));
      }
    }
    return widgets;
  }

  Widget _buildTaskCard(Task task) {
    final category =
        task.categoryId != null ? widget.categoryMap[task.categoryId] : null;
    return TaskCard(
      task: task,
      category: category,
      onTap: () => TaskFormSheet.show(context, task: task),
      onToggleComplete: () async {
        final newTask =
            await ref.read(tasksProvider.notifier).completeTask(task);
        if (newTask != null && context.mounted) {
          final dateStr = app_date.formatRelativeDate(
              newTask.dueDate, widget.l10n, widget.locale);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(widget.l10n.recurringTaskCreated(dateStr))),
          );
        }
        // トリガーA: タスク完了後にレビュー依頼
        final reviewService = ref.read(reviewServiceProvider);
        await reviewService.incrementCompletedTaskCount();
        Future.delayed(const Duration(seconds: 1), () {
          reviewService.requestReviewIfEligible();
        });
      },
      onDelete: () => ref.read(tasksProvider.notifier).deleteTask(task.id!),
    );
  }
}

/// 今週 / 来週 / 再来週以降 タブバー
class _WeekTabBar extends StatelessWidget {
  const _WeekTabBar({
    required this.selectedIndex,
    required this.thisWeekCount,
    required this.nextWeekCount,
    required this.laterCount,
    required this.l10n,
    required this.onSelected,
  });

  final int selectedIndex;
  final int thisWeekCount;
  final int nextWeekCount;
  final int laterCount;
  final AppLocalizations l10n;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final labels = [
      l10n.weekTabThisWeek,
      l10n.weekTabNextWeek,
      l10n.weekTabLater,
    ];
    final counts = [thisWeekCount, nextWeekCount, laterCount];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: List.generate(3, (i) {
          final label = counts[i] > 0
              ? l10n.weekTabCount(labels[i], counts[i])
              : labels[i];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(label),
              selected: selectedIndex == i,
              onSelected: (_) => onSelected(i),
              visualDensity: VisualDensity.compact,
            ),
          );
        }),
      ),
    );
  }
}

/// 日付サブヘッダー
class _DateSubHeader extends StatelessWidget {
  const _DateSubHeader({required this.date, required this.today});

  final DateTime date;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final isToday = date == today;
    final dow = DateFormat.E(locale).format(date);
    final fmt = DateFormat.MMMd(locale);
    final label = '${fmt.format(date)}($dow)';
    final l10n = AppLocalizations.of(context)!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      color: theme.colorScheme.surfaceContainerLow,
      child: Text(
        isToday ? '$label - ${l10n.calendarToday}' : label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: isToday
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// 折りたたみ可能なセクション（アニメーション付き）
class _CollapsibleSection extends StatelessWidget {
  const _CollapsibleSection({
    required this.title,
    required this.expanded,
    required this.onToggle,
    required this.children,
    this.icon,
    this.color,
    this.badgeCount,
  });

  final String title;
  final bool expanded;
  final VoidCallback onToggle;
  final List<Widget> children;
  final IconData? icon;
  final Color? color;
  final int? badgeCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveColor = color ?? theme.colorScheme.onSurface;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: onToggle,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 18, color: effectiveColor),
                  const SizedBox(width: 6),
                ],
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: effectiveColor,
                  ),
                ),
                const Spacer(),
                AnimatedRotation(
                  turns: expanded ? 0.5 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    Icons.expand_more,
                    size: 20,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          child: expanded
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: children,
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}

/// 「完了済み」タブ
class _CompletedTab extends ConsumerWidget {
  const _CompletedTab({
    required this.tasksAsync,
    required this.categoryMap,
    required this.l10n,
    required this.locale,
  });

  final AsyncValue<List<Task>> tasksAsync;
  final Map<int, model.Category> categoryMap;
  final AppLocalizations l10n;
  final String locale;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return tasksAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => const SizedBox.shrink(),
      data: (tasks) {
        if (tasks.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle_outline, size: 64,
                    color: Theme.of(context).colorScheme.outline),
                const SizedBox(height: 16),
                Text(l10n.emptyCompletedMessage,
                    style: TextStyle(fontSize: 16,
                        color: Theme.of(context).colorScheme.outline)),
              ],
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(tasksProvider);
            await ref.read(tasksProvider.future);
          },
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 80),
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final task = tasks[index];
              final category = task.categoryId != null
                  ? categoryMap[task.categoryId]
                  : null;
              return _FadeInItem(
                key: ValueKey(task.id),
                index: index,
                child: TaskCard(
                  task: task,
                  category: category,
                  onTap: () => TaskFormSheet.show(context, task: task),
                  onToggleComplete: () async {
                    await ref.read(tasksProvider.notifier).completeTask(task);
                  },
                  onDelete: () =>
                      ref.read(tasksProvider.notifier).deleteTask(task.id!),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

/// セクションヘッダー
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    this.icon,
    this.color,
    this.trailing,
  });

  final String title;
  final IconData? icon;
  final Color? color;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: color ?? theme.colorScheme.primary),
            const SizedBox(width: 6),
          ],
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color ?? theme.colorScheme.onSurface,
            ),
          ),
          if (trailing != null) ...[
            const Spacer(),
            Text(
              trailing!,
              style: TextStyle(
                fontSize: 13,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// タスクリストアイテムのフェードインアニメーション
class _FadeInItem extends StatefulWidget {
  const _FadeInItem({super.key, required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  State<_FadeInItem> createState() => _FadeInItemState();
}

class _FadeInItemState extends State<_FadeInItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _offset;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _offset = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    final delay = widget.index < 10 ? widget.index * 50 : 0;
    Future.delayed(Duration(milliseconds: delay), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(position: _offset, child: widget.child),
    );
  }
}

/// 全タスク完了時の祝福画面
class _AllCompleteCelebration extends StatefulWidget {
  const _AllCompleteCelebration({required this.l10n});

  final AppLocalizations l10n;

  @override
  State<_AllCompleteCelebration> createState() =>
      _AllCompleteCelebrationState();
}

class _AllCompleteCelebrationState extends State<_AllCompleteCelebration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );
    _controller.forward();
    // トリガーA（祝福画面）: 全タスク完了後2秒でレビュー依頼
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      final container = ProviderScope.containerOf(context);
      container.read(reviewServiceProvider).requestReviewIfEligible();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: FadeTransition(
        opacity: _opacity,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ScaleTransition(
              scale: _scale,
              child: Icon(Icons.check_circle, size: 80,
                  color: theme.colorScheme.primary),
            ),
            const SizedBox(height: 16),
            Text(
              '${widget.l10n.allCompleteTitle} 🎉',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              widget.l10n.allCompleteSubtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () {
                HapticFeedback.selectionClick();
                TaskFormSheet.show(context);
              },
              icon: const Icon(Icons.add),
              label: Text(widget.l10n.allCompleteAddTask),
              style: FilledButton.styleFrom(minimumSize: const Size(200, 48)),
            ),
          ],
        ),
      ),
    );
  }
}

/// 全タスク期限切れ時の警告バナー
class _AllExpiredBanner extends ConsumerWidget {
  const _AllExpiredBanner({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final bannerColor = theme.brightness == Brightness.dark
        ? const Color(0xFF4A2800)
        : const Color(0xFFFFF3E0);
    final textColor = theme.brightness == Brightness.dark
        ? const Color(0xFFFFCC80)
        : const Color(0xFFE65100);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Card(
        color: bannerColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: textColor.withValues(alpha: 0.3)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: textColor, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.allExpiredBannerTitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.tonal(
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        TaskFormSheet.show(context);
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: textColor.withValues(alpha: 0.15),
                        foregroundColor: textColor,
                      ),
                      child: Text(l10n.allExpiredAddTask),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        final db = ref.read(databaseServiceProvider);
                        final oldest = await db.getOldestOverdueTask();
                        if (oldest != null && context.mounted) {
                          TaskFormSheet.show(context, task: oldest);
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: textColor,
                        side: BorderSide(
                            color: textColor.withValues(alpha: 0.5)),
                      ),
                      child: Text(l10n.allExpiredUpdateDue),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
