import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../models/category.dart' as model;
import '../../models/task.dart';
import '../../providers/category_provider.dart';
import '../../providers/task_provider.dart';
import '../../theme/yaru_theme.dart';
import '../../utils/date_utils.dart' as app_date;
import '../../widgets/responsive_wrapper.dart';
import '../../widgets/task_form_sheet.dart';
import '../../widgets/v2/glass_bottom_nav.dart';
import '../../widgets/v2/hero_ai_card.dart';
import '../../widgets/v2/task_card.dart';
import '../settings_screen.dart';
import 'calendar_screen.dart';
import 'stats_screen.dart';

/// v2のメインシェル: ボトムナビ + 4タブ (Home/Calendar/Stats/Settings) + 中央FAB
class V2HomeShell extends ConsumerStatefulWidget {
  const V2HomeShell({super.key, this.initialTab = 0});
  final int initialTab;

  @override
  ConsumerState<V2HomeShell> createState() => _V2HomeShellState();
}

class _V2HomeShellState extends ConsumerState<V2HomeShell> {
  late int _index = widget.initialTab.clamp(0, 3);

  void _onAdd() {
    HapticFeedback.mediumImpact();
    TaskFormSheet.show(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _index,
        children: const [
          _V2HomeTab(),
          V2CalendarScreen(),
          V2StatsScreen(),
          SettingsScreen(),
        ],
      ),
      bottomNavigationBar: GlassBottomNav(
        items: [
          GlassNavItem(icon: Icons.home_rounded, label: l10n.navHome),
          GlassNavItem(icon: Icons.calendar_month_rounded, label: l10n.navCalendar),
          GlassNavItem(icon: Icons.emoji_events_rounded, label: l10n.navStats),
          GlassNavItem(icon: Icons.settings_rounded, label: l10n.navSettings),
        ],
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        onAddPressed: _onAdd,
      ),
    );
  }
}

class _V2HomeTab extends ConsumerWidget {
  const _V2HomeTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final yaru = context.yaru;
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final tasksAsync = ref.watch(tasksProvider);
    final categoriesAsync = ref.watch(categoriesProvider);

    final categoryMap = <int, model.Category>{};
    categoriesAsync.whenData((categories) {
      for (final c in categories) {
        if (c.id != null) categoryMap[c.id!] = c;
      }
    });

    return Scaffold(
      backgroundColor: yaru.scaffoldBg,
      body: SafeArea(
        bottom: false,
        child: ResponsiveWrapper(
          child: tasksAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => Center(child: Text(l10n.taskLoadError)),
            data: (tasks) {
              final split = _splitTasks(tasks);
              final (done, total) = _todayDoneTotal(tasks);
              return RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(tasksProvider);
                  await ref.read(tasksProvider.future);
                  if (context.mounted) HapticFeedback.mediumImpact();
                },
                child: ListView(
                  padding: const EdgeInsets.only(top: 8, bottom: 120),
                  children: [
                    _greetingHeader(context, locale, yaru),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: HeroAiCard(
                        todayDone: done,
                        todayTotal: total,
                      ),
                    ),
                    const SizedBox(height: 22),
                    if (split.today.isNotEmpty) ...[
                      _sectionHeader(
                        context: context,
                        label: l10n.sectionNow,
                        count: split.today.length,
                        color: yaru.urgent,
                      ),
                      const SizedBox(height: 8),
                      _taskList(split.today, categoryMap, ref),
                      const SizedBox(height: 22),
                    ],
                    if (split.thisWeek.isNotEmpty ||
                        split.nextWeek.isNotEmpty) ...[
                      _sectionHeader(
                        context: context,
                        label: l10n.sectionUpcoming,
                        count: split.thisWeek.length + split.nextWeek.length,
                        color: yaru.later,
                      ),
                      const SizedBox(height: 8),
                      _taskList(
                        [...split.thisWeek, ...split.nextWeek],
                        categoryMap,
                        ref,
                      ),
                      const SizedBox(height: 22),
                    ],
                    if (split.later.isNotEmpty) ...[
                      _sectionHeader(
                        context: context,
                        label: l10n.sectionLater,
                        count: split.later.length,
                        color: yaru.inkTertiary,
                      ),
                      const SizedBox(height: 8),
                      _taskList(split.later, categoryMap, ref),
                    ],
                    if (tasks.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 40),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(Icons.checklist_rtl_rounded,
                                  size: 56, color: yaru.inkQuaternary),
                              const SizedBox(height: 12),
                              Text(l10n.emptyTaskMessage,
                                  style: TextStyle(color: yaru.inkTertiary)),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _greetingHeader(BuildContext context, String locale, YaruTheme yaru) {
    final now = DateTime.now();
    final dateStr = DateFormat.MMMMd(locale).format(now);
    final dow = DateFormat.E(locale).format(now);
    final h = now.hour;
    final greetingKey = h < 10
        ? 'goodMorning'
        : h < 18
            ? 'goodAfternoon'
            : 'goodEvening';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _greeting(context, greetingKey),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: yaru.inkTertiary,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 2),
          RichText(
            text: TextSpan(
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w800,
                height: 1.05,
                color: yaru.inkPrimary,
                letterSpacing: -0.5,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
              children: [
                TextSpan(text: dateStr),
                TextSpan(
                  text: ' $dow',
                  style: TextStyle(
                    fontSize: 16,
                    color: yaru.inkQuaternary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _greeting(BuildContext context, String key) {
    final l10n = AppLocalizations.of(context)!;
    // i18nに無いキーは "Today" で代用
    return switch (key) {
      'goodMorning' => l10n.greetingMorning,
      'goodAfternoon' => l10n.greetingAfternoon,
      'goodEvening' => l10n.greetingEvening,
      _ => l10n.today,
    };
  }

  Widget _sectionHeader({
    required BuildContext context,
    required String label,
    required int count,
    required Color color,
  }) {
    final yaru = context.yaru;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: yaru.useGlassBlur
                  ? [BoxShadow(color: color.withValues(alpha: 0.6), blurRadius: 6)]
                  : null,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: yaru.inkSecondary,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: yaru.inkQuaternary,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 12),
              height: 1,
              color: yaru.line,
            ),
          ),
        ],
      ),
    );
  }

  Widget _taskList(
    List<Task> tasks,
    Map<int, model.Category> categoryMap,
    WidgetRef ref,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          for (final t in tasks)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: V2TaskCard(
                task: t,
                category: t.categoryId != null ? categoryMap[t.categoryId] : null,
                onTap: () {
                  if (t.id != null) ref.context.push('/task/${t.id}');
                },
                onToggleComplete: () {
                  ref.read(tasksProvider.notifier).completeTask(t);
                },
              ),
            ),
        ],
      ),
    );
  }
}

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
    if (t.isCompleted) continue;
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
      todayList.add(t); // 期限切れも今日扱い
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
  return (
    today: todayList,
    overdue: overdueList,
    thisWeek: thisWeekList,
    nextWeek: nextWeekList,
    later: laterList,
  );
}

(int, int) _todayDoneTotal(List<Task> tasks) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final todayKey = app_date.formatDateForDb(today);
  int total = 0;
  int done = 0;
  for (final t in tasks) {
    final dueKey = app_date.formatDateForDb(t.dueDate);
    final isTodayDue = dueKey == todayKey;
    final isPriority1 = t.priority == 1;
    final recKey = t.recommendedDate != null
        ? app_date.formatDateForDb(t.recommendedDate!)
        : null;
    final isRecToday = recKey == todayKey;
    final include = isTodayDue || isPriority1 || isRecToday;
    if (include) {
      total++;
      if (t.isCompleted) done++;
    }
  }
  return (done, total);
}
