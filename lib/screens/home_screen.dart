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
  final _bottomNavKey = GlobalKey();
  final _calendarKey = GlobalKey<CalendarScreenState>();
  late int _tabIndex = widget.initialTab.clamp(0, 1);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      await maybeShowCoachMarks(
        context,
        steps: [
          CoachStep(targetKey: _fabKey, message: l10n.coachAddTask),
          CoachStep(targetKey: _aiSortKey, message: l10n.coachAiSort),
          CoachStep(
            targetKey: _bottomNavKey,
            message: l10n.coachCalendarToggle,
          ),
        ],
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final tasksAsync = ref.watch(tasksProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final currentFilter = ref.watch(filterProvider);
    final showAiBanner = ref.watch(aiCompleteBannerProvider);
    final isCalendarTab = _tabIndex == 1;

    final categoryMap = <int, model.Category>{};
    categoriesAsync.whenData((categories) {
      for (final c in categories) {
        if (c.id != null) categoryMap[c.id!] = c;
      }
    });

    final todayStr = DateFormat.yMMMd(locale).format(DateTime.now());

    final listTab = Column(
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
        FilterTabs(key: _filterTabsKey),
        const SizedBox(height: 8),
        Expanded(
          child: tasksAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline,
                      size: 48,
                      color: Theme.of(context).colorScheme.error),
                  const SizedBox(height: 12),
                  Text(l10n.taskLoadError,
                      style: TextStyle(
                        fontSize: 15,
                        color: Theme.of(context).colorScheme.error,
                      )),
                ],
              ),
            ),
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
              return RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(tasksProvider);
                  await ref.read(tasksProvider.future);
                },
                child: currentFilter == 'all'
                    ? _ReorderableTaskList(
                        tasks: tasks,
                        categoryMap: categoryMap,
                        l10n: l10n,
                        locale: locale,
                      )
                    : _StandardTaskList(
                        tasks: tasks,
                        categoryMap: categoryMap,
                        l10n: l10n,
                        locale: locale,
                      ),
              );
            },
          ),
        ),
      ],
    );

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
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/settings'),
            tooltip: l10n.settings,
          ),
        ],
      ),
      body: ResponsiveWrapper(
        child: IndexedStack(
          index: _tabIndex,
          children: [
            listTab,
            CalendarScreen(key: _calendarKey),
          ],
        ),
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const BannerAdWidget(),
          NavigationBar(
            key: _bottomNavKey,
            selectedIndex: _tabIndex,
            onDestinationSelected: (i) => setState(() => _tabIndex = i),
            destinations: [
              NavigationDestination(
                icon: const Icon(Icons.list_alt_outlined),
                selectedIcon: const Icon(Icons.list_alt),
                label: l10n.tabList,
              ),
              NavigationDestination(
                icon: const Icon(Icons.calendar_month_outlined),
                selectedIcon: const Icon(Icons.calendar_month),
                label: l10n.tabCalendar,
              ),
            ],
          ),
        ],
      ),
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

/// 「すべて」フィルター時: ドラッグ＆ドロップ並び替え対応リスト
class _ReorderableTaskList extends ConsumerWidget {
  const _ReorderableTaskList({
    required this.tasks,
    required this.categoryMap,
    required this.l10n,
    required this.locale,
  });

  final List<Task> tasks;
  final Map<int, model.Category> categoryMap;
  final AppLocalizations l10n;
  final String locale;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ReorderableListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: tasks.length,
      onReorderStart: (_) {
        HapticFeedback.selectionClick();
      },
      onReorder: (oldIndex, newIndex) async {
        if (oldIndex < newIndex) newIndex -= 1;
        final db = ref.read(databaseServiceProvider);
        // 新しい並び順を計算
        final reordered = List.of(tasks);
        final item = reordered.removeAt(oldIndex);
        reordered.insert(newIndex, item);

        final orders = <({int id, int sortOrder})>[];
        for (var i = 0; i < reordered.length; i++) {
          final t = reordered[i];
          if (t.id == null) continue;
          orders.add((id: t.id!, sortOrder: i + 1));
        }
        await db.updateTaskSortOrders(orders);
        ref.invalidate(tasksProvider);
      },
      proxyDecorator: (child, index, animation) {
        return AnimatedBuilder(
          animation: animation,
          builder: (context, child) {
            final elevation = Tween<double>(
              begin: 0,
              end: 6,
            ).animate(animation).value;
            return Material(
              elevation: elevation,
              borderRadius: BorderRadius.circular(16),
              child: child,
            );
          },
          child: child,
        );
      },
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
            disableSwipe: true,
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
                  SnackBar(content: Text(l10n.recurringTaskCreated(dateStr))),
                );
              }
            },
            onDelete: () {
              ref.read(tasksProvider.notifier).deleteTask(task.id!);
            },
          ),
        );
      },
    );
  }
}

/// その他フィルター時: 通常リスト
class _StandardTaskList extends ConsumerWidget {
  const _StandardTaskList({
    required this.tasks,
    required this.categoryMap,
    required this.l10n,
    required this.locale,
  });

  final List<Task> tasks;
  final Map<int, model.Category> categoryMap;
  final AppLocalizations l10n;
  final String locale;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView.builder(
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
                  SnackBar(content: Text(l10n.recurringTaskCreated(dateStr))),
                );
              }
            },
            onDelete: () {
              ref.read(tasksProvider.notifier).deleteTask(task.id!);
            },
          ),
        );
      },
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
