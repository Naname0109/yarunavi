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

/// 「やること」タブ: 今日やること + その他セクション
class _TodoTab extends ConsumerWidget {
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

  /// 「今日やること」に該当するか判定
  bool _isTodayTask(Task task) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDay = DateTime(task.dueDate.year, task.dueDate.month, task.dueDate.day);
    final isOverdue = dueDay.isBefore(today);
    final isDueToday = dueDay == today;
    final isPriority1 = task.priority == 1;
    final isRecommendedToday = task.recommendedStart != null &&
        DateTime(task.recommendedStart!.year, task.recommendedStart!.month,
                task.recommendedStart!.day) ==
            today;

    return isOverdue || isDueToday || isPriority1 || isRecommendedToday;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return tasksAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline,
                size: 48, color: Theme.of(context).colorScheme.error),
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
          if (completedCount > 0) {
            return _AllCompleteCelebration(l10n: l10n);
          }
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.checklist, size: 64,
                    color: Theme.of(context).colorScheme.outline),
                const SizedBox(height: 16),
                Text(l10n.emptyTaskMessage,
                    style: TextStyle(fontSize: 16,
                        color: Theme.of(context).colorScheme.outline)),
              ],
            ),
          );
        }

        final todayTasks = <Task>[];
        final otherTasks = <Task>[];
        for (final t in tasks) {
          (_isTodayTask(t) ? todayTasks : otherTasks).add(t);
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(tasksProvider);
            await ref.read(tasksProvider.future);
          },
          child: ListView(
            padding: const EdgeInsets.only(bottom: 80),
            children: [
              // 全タスク期限切れバナー
              if (allOverdue) _AllExpiredBanner(l10n: l10n),
              // 今日やることセクション
              _SectionHeader(
                title: l10n.todaySection,
                icon: Icons.push_pin,
                color: Theme.of(context).colorScheme.error,
              ),
              if (todayTasks.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Text(
                    l10n.todaySectionEmpty,
                    style: TextStyle(
                      fontSize: 15,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                )
              else
                ...todayTasks.asMap().entries.map((entry) =>
                  _FadeInItem(
                    key: ValueKey(entry.value.id),
                    index: entry.key,
                    child: _buildTaskCard(context, ref, entry.value),
                  ),
                ),
              // その他のタスクセクション
              if (otherTasks.isNotEmpty) ...[
                const SizedBox(height: 8),
                _SectionHeader(
                  title: l10n.otherTasks,
                  trailing: l10n.taskCount(otherTasks.length),
                ),
                ...otherTasks.asMap().entries.map((entry) =>
                  _FadeInItem(
                    key: ValueKey(entry.value.id),
                    index: entry.key,
                    child: _buildTaskCard(context, ref, entry.value),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildTaskCard(BuildContext context, WidgetRef ref, Task task) {
    final category = task.categoryId != null ? categoryMap[task.categoryId] : null;
    return TaskCard(
      task: task,
      category: category,
      onTap: () => TaskFormSheet.show(context, task: task),
      onToggleComplete: () async {
        final newTask = await ref.read(tasksProvider.notifier).completeTask(task);
        if (newTask != null && context.mounted) {
          final dateStr = app_date.formatRelativeDate(newTask.dueDate, l10n, locale);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.recurringTaskCreated(dateStr))),
          );
        }
      },
      onDelete: () => ref.read(tasksProvider.notifier).deleteTask(task.id!),
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
