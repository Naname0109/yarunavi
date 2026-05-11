import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/category.dart' as model;
import '../models/task.dart';
import '../providers/category_provider.dart';
import '../providers/sound_provider.dart';
import '../providers/task_provider.dart';
import '../services/sound_service.dart';
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

    final now = DateTime.now();
    final todayStr = DateFormat.MMMd(locale).format(now);
    final dow = DateFormat.E(locale).format(now);
    final showHistoryBadge = ref.watch(aiHistoryBadgeProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('$todayStr($dow)'),
        actions: [
          if (isCalendarTab)
            IconButton(
              icon: const Icon(Icons.today),
              tooltip: l10n.calendarToday,
              onPressed: () => _calendarKey.currentState?.goToToday(),
            ),
          AiSortButton(key: _aiSortKey),
          InkWell(
            key: const Key('ai_history_button'),
            borderRadius: BorderRadius.circular(8),
            onTap: () {
              ref.read(aiHistoryBadgeProvider.notifier).state = false;
              context.push('/ai-history');
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Badge(
                    isLabelVisible: showHistoryBadge,
                    child: Icon(Icons.history,
                        size: 20,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    l10n.aiHistoryLabel,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
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

/// 全タスク完了時の祝福画面（紙吹雪＋パルスボタン）
class _AllCompleteCelebration extends ConsumerStatefulWidget {
  const _AllCompleteCelebration({required this.l10n});

  final AppLocalizations l10n;

  @override
  ConsumerState<_AllCompleteCelebration> createState() =>
      _AllCompleteCelebrationState();
}

class _AllCompleteCelebrationState
    extends ConsumerState<_AllCompleteCelebration>
    with TickerProviderStateMixin {
  late final AnimationController _checkController;
  late final AnimationController _confettiController;
  late final AnimationController _pulseController;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;

  bool _showNextPrompt = false;
  bool _confettiTriggered = false;

  @override
  void initState() {
    super.initState();
    _checkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _scale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _checkController, curve: Curves.elasticOut),
    );
    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _checkController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _checkController.forward();
    _confettiController.forward();

    // サウンド + 紙吹雪トリガー
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _confettiTriggered) return;
      _confettiTriggered = true;
      final sound = ref.read(soundServiceProvider);
      // ignore: discarded_futures
      sound.play(SoundEvent.allTasksComplete);
    });

    // 紙吹雪が落ち着いた後（2秒後）に「次のやること」促進UIを表示
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _showNextPrompt = true);
    });

    // トリガーA（祝福画面）: 全タスク完了後2秒でレビュー依頼
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      ref.read(reviewServiceProvider).requestReviewIfEligible();
    });
  }

  @override
  void dispose() {
    _checkController.dispose();
    _confettiController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Stack(
      children: [
        Center(
          child: FadeTransition(
            opacity: _opacity,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                  horizontal: 24, vertical: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // チェックマーク (大バウンス + 背景の光リング)
                  SizedBox(
                    height: 120,
                    child: Stack(
                      alignment: Alignment.center,
                      clipBehavior: Clip.none,
                      children: [
                        // 背景の光彩リング (登場と同時に拡散してフェードアウト)
                        AnimatedBuilder(
                          animation: _checkController,
                          builder: (context, _) {
                            final t = _checkController.value;
                            final ringT =
                                Curves.easeOutCubic.transform(t);
                            final size = 70 + ringT * 90;
                            final alpha = (1.0 - ringT) * 0.6;
                            if (alpha <= 0) return const SizedBox.shrink();
                            return Container(
                              width: size,
                              height: size,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: theme.colorScheme.primary
                                      .withValues(alpha: alpha),
                                  width: 3,
                                ),
                              ),
                            );
                          },
                        ),
                        ScaleTransition(
                          scale: _scale,
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: theme.colorScheme.primary
                                      .withValues(alpha: 0.35),
                                  blurRadius: 28,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Icon(Icons.check_circle,
                                size: 104,
                                color: theme.colorScheme.primary),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
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
                  // 次のタスク入力促進（2秒後にフェードイン）
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 600),
                    opacity: _showNextPrompt ? 1.0 : 0.0,
                    curve: Curves.easeOut,
                    child: AnimatedSlide(
                      duration: const Duration(milliseconds: 600),
                      offset: _showNextPrompt
                          ? Offset.zero
                          : const Offset(0, 0.1),
                      curve: Curves.easeOutCubic,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.l10n.allCompleteNextPrompt,
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: theme.colorScheme.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          // パルスグロウ付き「タスクを追加する」ボタン
                          _PulsingPrimaryButton(
                            pulseController: _pulseController,
                            primaryColor: theme.colorScheme.primary,
                            onTap: () {
                              HapticFeedback.selectionClick();
                              TaskFormSheet.show(context);
                            },
                            label: widget.l10n.allCompleteAddTask,
                          ),
                          const SizedBox(height: 12),
                          // 「AIで整理」アウトラインボタン (タスク無しの状態案内)
                          OutlinedButton.icon(
                            onPressed: () {
                              HapticFeedback.selectionClick();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      widget.l10n.allCompleteNoTaskForAi),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                            icon: const Icon(Icons.auto_awesome, size: 18),
                            label: Text(widget.l10n.allCompleteAiSort),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(220, 48),
                              foregroundColor: theme.colorScheme.primary,
                              side: BorderSide(
                                color: theme.colorScheme.primary
                                    .withValues(alpha: 0.5),
                                width: 1.2,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // 紙吹雪オーバーレイ
        IgnorePointer(
          child: RepaintBoundary(
            child: AnimatedBuilder(
              animation: _confettiController,
              builder: (context, _) {
                return CustomPaint(
                  size: Size.infinite,
                  painter: _ConfettiPainter(
                    progress: _confettiController.value,
                    primaryColor: theme.colorScheme.primary,
                    secondaryColor: theme.colorScheme.secondary,
                    tertiaryColor: theme.colorScheme.tertiary,
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

/// グロウリング + 軽いscale でパルスする Primary ボタン
class _PulsingPrimaryButton extends StatelessWidget {
  const _PulsingPrimaryButton({
    required this.pulseController,
    required this.primaryColor,
    required this.onTap,
    required this.label,
  });

  final AnimationController pulseController;
  final Color primaryColor;
  final VoidCallback onTap;
  final String label;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulseController,
      builder: (context, _) {
        final t = pulseController.value;
        // 1.0 → 1.04 の控えめなscale + 外側に光が広がる
        final scale = 1.0 + t * 0.04;
        return Transform.scale(
          scale: scale,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withValues(alpha: 0.35 * (1 - t * 0.5)),
                  blurRadius: 12 + t * 24,
                  spreadRadius: t * 4,
                ),
              ],
            ),
            child: FilledButton.icon(
              onPressed: onTap,
              icon: const Icon(Icons.add),
              label: Text(label),
              style: FilledButton.styleFrom(
                minimumSize: const Size(220, 52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
                elevation: 0,
              ),
            ),
          ),
        );
      },
    );
  }
}

/// 紙吹雪用のCustomPainter
/// 60個の紙片が上から重力 + 初速 + 横揺れ + 自由回転で落下
/// 形状: 四角 / 丸 / 三角を混在、サイズ・速度・色を多様化
class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter({
    required this.progress,
    required this.primaryColor,
    required this.secondaryColor,
    required this.tertiaryColor,
  });

  /// 0.0 → 1.0 で 3 秒進む
  final double progress;
  final Color primaryColor;
  final Color secondaryColor;
  final Color tertiaryColor;

  static const _particleCount = 60;
  static final _seeds = List<_ConfettiSeed>.generate(_particleCount, (i) {
    final rng = math.Random(i * 9973 + 7);
    return _ConfettiSeed(
      xRatio: rng.nextDouble(),
      delay: rng.nextDouble() * 0.35,
      // 落下速度の幅を広く: 0.5 (ゆっくり) 〜 1.4 (速い)
      speed: 0.5 + rng.nextDouble() * 0.9,
      colorIdx: rng.nextInt(5),
      rotateSpeed: (rng.nextDouble() - 0.5) * 6 * math.pi,
      // 横ドリフト: 左右に -0.15 〜 0.15 の方向初速
      driftX: (rng.nextDouble() - 0.5) * 0.3,
      // 横揺れ: ±20 の振幅、頻度 0.6〜1.4 周期
      swayAmp: rng.nextDouble() * 24 + 4,
      swayFreq: 0.6 + rng.nextDouble() * 0.8,
      startRotation: rng.nextDouble() * 2 * math.pi,
      shape: rng.nextInt(3),
      size: 5.0 + rng.nextDouble() * 7.0,
    );
  });

  @override
  void paint(Canvas canvas, Size size) {
    final colors = [
      primaryColor,
      _goldColor,
      tertiaryColor,
      secondaryColor,
      const Color(0xFFE91E63), // pink (アクセント)
    ];

    // 全体フェード: 0.85〜1.0 で消える
    final overallFade =
        progress < 0.85 ? 1.0 : (1.0 - (progress - 0.85) / 0.15);

    for (final s in _seeds) {
      final localProgress =
          ((progress - s.delay) / (1.0 - s.delay)).clamp(0.0, 1.0);
      if (localProgress <= 0) continue;
      final t = localProgress;

      // --- 軌跡計算: 重力ベース ---
      // 初速 + 重力加速で y = v0*t + 0.5*g*t^2
      const initialVy = 0.12; // 初期下向き速度 (画面比)
      const gravity = 0.9; // 重力加速度 (画面比)
      final yProgress = initialVy * t + 0.5 * gravity * t * t;
      final y = -30 + (size.height + 60) * yProgress * s.speed;

      // 横方向: 直線ドリフト + sin揺れ
      final xDrift = s.driftX * t * size.width;
      final xSway = math.sin(t * math.pi * 2 * s.swayFreq) * s.swayAmp;
      final x = s.xRatio * size.width + xDrift + xSway;

      // 画面外に出たらスキップ
      if (y > size.height + 20) continue;

      final color = colors[s.colorIdx].withValues(alpha: overallFade);
      final rotation = s.startRotation + t * s.rotateSpeed;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(rotation);
      final paint = Paint()..color = color;
      switch (s.shape) {
        case 0:
          // 紙片 (薄い四角)
          final w = s.size;
          final h = s.size * 0.55;
          canvas.drawRect(Rect.fromLTWH(-w / 2, -h / 2, w, h), paint);
        case 1:
          // 丸
          canvas.drawCircle(Offset.zero, s.size / 2, paint);
        case 2:
          // 三角形
          final r = s.size / 2;
          final path = Path()
            ..moveTo(0, -r)
            ..lineTo(r * 0.866, r * 0.5)
            ..lineTo(-r * 0.866, r * 0.5)
            ..close();
          canvas.drawPath(path, paint);
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _ConfettiSeed {
  const _ConfettiSeed({
    required this.xRatio,
    required this.delay,
    required this.speed,
    required this.colorIdx,
    required this.rotateSpeed,
    required this.driftX,
    required this.swayAmp,
    required this.swayFreq,
    required this.startRotation,
    required this.shape,
    required this.size,
  });
  final double xRatio;
  final double delay;
  final double speed;
  final int colorIdx;
  final double rotateSpeed;
  final double driftX;
  final double swayAmp;
  final double swayFreq;
  final double startRotation;
  final int shape;
  final double size;
}

const Color _goldColor = Color(0xFFFFC107);

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
