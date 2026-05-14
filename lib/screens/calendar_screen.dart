import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_calendar/table_calendar.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/task.dart';
import '../models/category.dart' as model;
import '../providers/category_provider.dart';
import '../providers/task_provider.dart';
import '../theme/colors.dart';
import '../providers/dev_mode_provider.dart';
import '../widgets/task_card.dart';
import '../widgets/task_form_sheet.dart';
import '../widgets/v2/task_card.dart' as v2;
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
    // 初回表示時のみ「AIのおすすめ日 / 期限の日」のコーチマークSnackBarを出す。
    // ?アイコンを廃止する代わりに、 ユーザーが2モードの意味を 1度だけ
    // 自然に学べるようにする (B-11)。
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final prefs = await SharedPreferences.getInstance();
      const key = 'calendar_mode_coachmark_shown';
      if (prefs.getBool(key) == true) return;
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.calendarViewRecommendedTooltip),
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
        ),
      );
      await prefs.setBool(key, true);
    });
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
    final useNewUi = ref.watch(useNewUiProvider);
    // v2: 完了済みも含めて全タスクを表示 (取り消し線付き)
    final tasksAsync = useNewUi
        ? ref.watch(allTasksProvider)
        : ref.watch(tasksProvider);
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
        // v2: 完了済みもグリッド/リストに含める
        // v1: 既存どおり未完了のみ
        final displayTasks =
            useNewUi ? tasks : tasks.where((t) => !t.isCompleted).toList();

        // 期限日でグループ化
        final byDue = <DateTime, List<Task>>{};
        // 推奨日でグループ化（推奨日がないタスクはdue_dateで代替）
        final byRecommended = <DateTime, List<Task>>{};
        for (final t in displayTasks) {
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

        // 「次の予定日」サジェスト用: 選択日より後で最も近いタスクのある日
        DateTime? nextTaskDay;
        int nextTaskCount = 0;
        if (selectedTasks.isEmpty && selectedDayNorm != null) {
          final futureKeys = activeMap.keys
              .where((k) => k.isAfter(selectedDayNorm))
              .toList()
            ..sort();
          if (futureKeys.isNotEmpty) {
            nextTaskDay = futureKeys.first;
            nextTaskCount = activeMap[nextTaskDay]!.length;
          } else {
            // 未来になければ過去で最寄りを探す (期限切れ含む)
            final pastKeys = activeMap.keys
                .where((k) => k.isBefore(selectedDayNorm))
                .toList()
              ..sort((a, b) => b.compareTo(a));
            if (pastKeys.isNotEmpty) {
              nextTaskDay = pastKeys.first;
              nextTaskCount = activeMap[nextTaskDay]!.length;
            }
          }
        }

        // 月全体でタスクが0件かどうか (初回利用者向けの全面メッセージ)
        final monthHasNoTask = displayTasks.isEmpty;

        return Column(
          children: [
            // --- 表示モード切替 (AIのおすすめ日 / 期限の日) ---
            // ?アイコンを廃止し、 初回コーチマーク + tooltip 長押しで学習させる (B-11)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: SegmentedButton<_CalendarViewMode>(
                segments: [
                  ButtonSegment(
                    value: _CalendarViewMode.recommended,
                    label: Text(l10n.calendarViewRecommended),
                    icon: const Icon(Icons.push_pin, size: 16),
                    tooltip: l10n.calendarViewRecommendedTooltip,
                  ),
                  ButtonSegment(
                    value: _CalendarViewMode.due,
                    label: Text(l10n.calendarViewDue),
                    icon: const Icon(Icons.schedule, size: 16),
                    tooltip: l10n.calendarViewDueTooltip,
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
                  size: 32,
                  color: theme.colorScheme.primary,
                ),
                rightChevronIcon: Icon(
                  Icons.chevron_right,
                  size: 32,
                  color: theme.colorScheme.primary,
                ),
                leftChevronPadding: const EdgeInsets.all(8),
                rightChevronPadding: const EdgeInsets.all(8),
              ),
              calendarBuilders: CalendarBuilders(
                defaultBuilder: (context, day, focusedDay) =>
                    _buildDayCell(day, activeMap, theme, isDark, false, false),
                todayBuilder: (context, day, focusedDay) =>
                    _buildDayCell(day, activeMap, theme, isDark, true, false),
                selectedBuilder: (context, day, focusedDay) =>
                    _buildDayCell(day, activeMap, theme, isDark, false, true),
                // デフォルトの黒丸マーカーを無効化 (カラーバーで表現済み)
                markerBuilder: (context, day, events) =>
                    const SizedBox.shrink(),
              ),
              calendarStyle: const CalendarStyle(
                outsideDaysVisible: false,
                cellMargin: EdgeInsets.zero,
                cellPadding: EdgeInsets.zero,
              ),
            ),
            // --- 凡例 ---
            _CalendarLegend(l10n: l10n, isDark: isDark),
            Divider(height: 1, color: theme.dividerColor),
            // --- 選択日のタスクリスト ---
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: selectedTasks.isEmpty
                    ? _emptyState(
                        key: const ValueKey('empty'),
                        theme: theme,
                        l10n: l10n,
                        locale: locale,
                        nextTaskDay: nextTaskDay,
                        nextTaskCount: nextTaskCount,
                        monthHasNoTask: monthHasNoTask,
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

  /// 選択日にタスクがない場合の表示。
  /// - 月全体にタスクが無ければ "今月の予定はありません" を出す
  /// - 月内に他の日付があれば「次の予定: 5月15日 (2件)」とサジェスト + ジャンプ
  Widget _emptyState({
    Key? key,
    required ThemeData theme,
    required AppLocalizations l10n,
    required String locale,
    required DateTime? nextTaskDay,
    required int nextTaskCount,
    required bool monthHasNoTask,
  }) {
    final color = theme.colorScheme.outline;
    if (monthHasNoTask) {
      return Center(
        key: key,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.event_note_outlined, size: 36, color: color),
              const SizedBox(height: 10),
              Text(
                l10n.calendarMonthEmpty,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                l10n.emptyTaskMessage,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11.5, color: color),
              ),
              const SizedBox(height: 14),
              // 初回ユーザー向け: 月内0件のときに「タスクを追加」CTAを設置。
              // ここからの追加でカレンダー機能の発見率を上げる。
              FilledButton.icon(
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  TaskFormSheet.show(context);
                },
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text(l10n.addTask),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 10),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // 選択日にはタスクないが、他の日にはある
    return Center(
      key: key,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.event_available, size: 28, color: color),
            const SizedBox(height: 8),
            // この分岐は monthHasNoTask=false かつ selectedTasks 空 ⇒ 必ず近接日が存在
            Text(
              l10n.calendarNoTasksNextHint(
                DateFormat.MMMd(locale).add_E().format(nextTaskDay!),
                nextTaskCount,
              ),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () {
                HapticFeedback.selectionClick();
                setState(() {
                  _selectedDay = nextTaskDay;
                  _focusedDay = nextTaskDay;
                });
              },
              icon: const Icon(Icons.arrow_forward_rounded, size: 16),
              label: Text(l10n.calendarJumpToNext,
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              style: OutlinedButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              ),
            ),
          ],
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
    final useNewUi = ref.watch(useNewUiProvider);

    Future<void> onComplete() async {
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
    }

    // 新UI: v2 デザインのカード (高コントラスト + ネオン)
    if (useNewUi) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        child: v2.V2TaskCard(
          task: task,
          category: category,
          onTap: () {
            if (task.id != null) context.push('/task/${task.id}');
          },
          onToggleComplete: onComplete,
        ),
      );
    }

    // 旧UI: 既存 TaskCard
    return TaskCard(
      task: task,
      category: category,
      onTap: () => TaskFormSheet.show(context, task: task),
      onToggleComplete: onComplete,
      onDelete: () {
        ref.read(tasksProvider.notifier).deleteTask(task.id!);
      },
    );
  }

  /// カスタム日付セル
  /// - 今日: Primaryの丸い背景 + 白文字
  /// - 選択: Primary薄色の背景
  /// - タスクあり: 背景に priority色 5% を被せる
  /// - タスク数だけ priority色の 3px 高さバーを横並びで表示
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

    // タスクがある日: priority最高(1=赤)の薄い色を背景に
    Color? bgColor;
    if (displayTasks.isNotEmpty && !isToday && !isSelected) {
      final firstColor = _getTaskColor(displayTasks.first, isDark);
      bgColor = firstColor.withValues(alpha: 0.05);
    }

    // ↑ ただし isSelected/isToday は強調を優先
    if (isSelected) {
      bgColor = theme.colorScheme.primary.withValues(alpha: 0.12);
    }

    return Padding(
      padding: const EdgeInsets.all(2),
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
          border: isSelected
              ? Border.all(color: theme.colorScheme.primary, width: 1.5)
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 3),
            // 日付番号: 今日は Primary 丸背景 + 白文字
            if (isToday)
              Container(
                width: 24,
                height: 24,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '${day.day}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onPrimary,
                  ),
                ),
              )
            else
              SizedBox(
                height: 24,
                child: Center(
                  child: Text(
                    '${day.day}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? theme.colorScheme.primary : null,
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 2),
            // priorityカラーバー (最大4本、3px高さ、横並び)
            if (displayTasks.isNotEmpty)
              _PriorityBars(
                tasks: displayTasks.take(4).toList(),
                isDark: isDark,
              ),
            // 5件以上は +N 表示
            if (displayTasks.length > 4)
              Padding(
                padding: const EdgeInsets.only(top: 1),
                child: Text(
                  '+${displayTasks.length - 4}',
                  style: TextStyle(
                      fontSize: 9, color: theme.colorScheme.outline),
                ),
              ),
          ],
        ),
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

/// 日付セル下部の priority カラーバー (3px 高さ、横並び)。
///
/// 完了済みタスクは半透明 + 斜線パターンで描画し、 priority=0 (未整理)の
/// グレーバーと視覚的に区別する。
class _PriorityBars extends StatelessWidget {
  const _PriorityBars({required this.tasks, required this.isDark});

  final List<Task> tasks;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: tasks.map((t) {
          final isDone = t.isCompleted;
          final baseColor = t.priority == 0
              ? (isDark ? Colors.grey.shade400 : Colors.grey.shade600)
              : AppColors.getPriorityColor(t.priority, t.dueDate,
                  isDark: isDark);
          // 完了済み: 落ち着いた calm色に切替 (priorityに関係なく)
          final color = isDone
              ? (isDark
                  ? const Color(0xFF8AA0BC).withValues(alpha: 0.45)
                  : const Color(0xFFB5C2D5))
              : baseColor;
          return Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 1),
              height: 3,
              child: CustomPaint(
                painter: _BarPainter(
                  color: color,
                  glow: isDark && !isDone,
                  striped: isDone,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// priority bar 用 painter。 完了タスクは diagonal stripes で描画。
class _BarPainter extends CustomPainter {
  _BarPainter({required this.color, required this.glow, required this.striped});

  final Color color;
  final bool glow;
  final bool striped;

  @override
  void paint(Canvas canvas, Size size) {
    final r = const Radius.circular(1.5);
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndCorners(rect,
        topLeft: r, topRight: r, bottomLeft: r, bottomRight: r);

    if (glow) {
      final glowPaint = Paint()
        ..color = color.withValues(alpha: 0.6)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawRRect(rrect, glowPaint);
    }

    if (!striped) {
      canvas.drawRRect(rrect, Paint()..color = color);
      return;
    }

    // 完了タスク: 薄い背景 + diagonal stripes
    canvas.drawRRect(rrect, Paint()..color = color.withValues(alpha: 0.35));
    final stripePaint = Paint()
      ..color = color
      ..strokeWidth = 0.8;
    canvas.save();
    canvas.clipRRect(rrect);
    final step = 3.0;
    final h = size.height;
    final w = size.width;
    for (double x = -h; x < w + h; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x + h, h), stripePaint);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_BarPainter old) =>
      old.color != color || old.glow != glow || old.striped != striped;
}

/// カレンダー下部の凡例
class _CalendarLegend extends StatelessWidget {
  const _CalendarLegend({required this.l10n, required this.isDark});

  final AppLocalizations l10n;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = <(String, Color)>[
      (
        l10n.calendarLegendUrgent,
        isDark ? AppColors.priorityUrgentDark : AppColors.priorityUrgent,
      ),
      (
        l10n.calendarLegendWeek,
        isDark ? AppColors.priorityWarningDark : AppColors.priorityWarning,
      ),
      (
        l10n.calendarLegendLater,
        isDark ? AppColors.priorityNormalDark : AppColors.priorityNormal,
      ),
      (
        l10n.calendarLegendUnsorted,
        isDark ? Colors.grey.shade400 : Colors.grey.shade600,
      ),
      (
        l10n.calendarLegendDone,
        isDark
            ? const Color(0xFF8AA0BC).withValues(alpha: 0.6)
            : const Color(0xFFB5C2D5),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 12,
        runSpacing: 4,
        children: items.map((it) {
          final (label, color) = it;
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}
