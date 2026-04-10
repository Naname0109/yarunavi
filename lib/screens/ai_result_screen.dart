import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/task.dart';
import '../providers/purchase_provider.dart';
import '../providers/task_provider.dart';
import '../services/calendar_service.dart';
import '../services/ai_service.dart';
import '../theme/colors.dart';
import '../widgets/ai_sort_button.dart';
import '../widgets/responsive_wrapper.dart';

class AiResultScreen extends ConsumerStatefulWidget {
  const AiResultScreen({super.key});

  @override
  ConsumerState<AiResultScreen> createState() => _AiResultScreenState();
}

class _AiResultScreenState extends ConsumerState<AiResultScreen> {
  final _answerControllers = <int, TextEditingController>{};

  @override
  void dispose() {
    for (final c in _answerControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final tasksAsync = ref.watch(tasksProvider);
    final aiResponse = ref.watch(aiSortResponseProvider);
    final sortedAtStr = DateFormat.yMMMd(
      locale,
    ).add_Hm().format(DateTime.now());
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final resultsMap = <int, AiSortResult>{};
    for (final r in (aiResponse?.tasks ?? [])) {
      resultsMap[r.taskId] = r;
    }

    final summary = locale == 'ja'
        ? aiResponse?.summaryJa
        : aiResponse?.summaryEn;
    final questions = locale == 'ja'
        ? (aiResponse?.questionsJa ?? [])
        : (aiResponse?.questionsEn ?? []);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.aiResultTitle),
        automaticallyImplyLeading: false,
      ),
      body: ResponsiveWrapper(
        child: tasksAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('$e')),
          data: (tasks) {
            final incompleteTasks = tasks
                .where((t) => !t.isCompleted && t.priority > 0)
                .toList();

            final groups = <int, List<Task>>{};
            for (final t in incompleteTasks) {
              groups.putIfAbsent(t.priority, () => []).add(t);
            }

            final p1Count = (groups[1] ?? []).length;
            final p2Count = (groups[2] ?? []).length;
            final laterCount =
                (groups[3] ?? []).length + (groups[4] ?? []).length;

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // サマリカード
                _buildSummaryCard(
                  context,
                  l10n,
                  summary,
                  p1Count,
                  p2Count,
                  laterCount,
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.aiResultSortedAt(sortedAtStr),
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.outline,
                  ),
                ),

                // AI質問セクション
                if (questions.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildQuestionsSection(context, l10n, locale, questions),
                ],

                const SizedBox(height: 12),

                // Priority 1-2: コメント付き表示
                ..._buildPrioritySection(
                  context,
                  l10n,
                  locale,
                  l10n.aiPriorityUrgent,
                  AppColors.priorityUrgent,
                  groups[1] ?? [],
                  resultsMap,
                  expanded: true,
                ),
                ..._buildPrioritySection(
                  context,
                  l10n,
                  locale,
                  l10n.aiPriorityWarning,
                  AppColors.priorityWarning,
                  groups[2] ?? [],
                  resultsMap,
                  expanded: true,
                ),
                // Priority 3-4: 折りたたみ表示
                ..._buildPrioritySection(
                  context,
                  l10n,
                  locale,
                  l10n.aiPriorityNormal,
                  isDark
                      ? AppColors.priorityNormalDark
                      : AppColors.priorityNormal,
                  groups[3] ?? [],
                  resultsMap,
                  expanded: false,
                ),
                ..._buildPrioritySection(
                  context,
                  l10n,
                  locale,
                  l10n.aiPriorityRelaxed,
                  isDark
                      ? AppColors.priorityRelaxedDark
                      : AppColors.priorityRelaxed,
                  groups[4] ?? [],
                  resultsMap,
                  expanded: false,
                ),

                // サブスク訴求バナー（無料ユーザーのみ）
                if (!ref.watch(isPremiumProvider)) ...[
                  const SizedBox(height: 16),
                  _buildPremiumBanner(context, l10n, theme),
                ],

                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () {
                    context.go('/home');
                  },
                  icon: const Icon(Icons.calendar_month),
                  label: Text(l10n.aiViewSchedule),
                ),
                const SizedBox(height: 32),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
    BuildContext context,
    AppLocalizations l10n,
    String? summary,
    int todayCount,
    int weekCount,
    int laterCount,
  ) {
    final theme = Theme.of(context);
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primary.withValues(alpha: 0.08),
              theme.colorScheme.primary.withValues(alpha: 0.02),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.auto_awesome,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  l10n.aiTodayPlan,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            if (summary != null) ...[
              const SizedBox(height: 12),
              Text(summary, style: theme.textTheme.bodyMedium),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                _buildCountChip(
                  context,
                  l10n.aiTodayTasks(todayCount),
                  AppColors.priorityUrgent,
                ),
                const SizedBox(width: 8),
                _buildCountChip(
                  context,
                  l10n.aiWeekTasks(weekCount),
                  AppColors.priorityWarning,
                ),
                const SizedBox(width: 8),
                _buildCountChip(
                  context,
                  l10n.aiLaterTasks(laterCount),
                  AppColors.priorityNormal,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCountChip(BuildContext context, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildQuestionsSection(
    BuildContext context,
    AppLocalizations l10n,
    String locale,
    List<String> questions,
  ) {
    final theme = Theme.of(context);
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.3),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.help_outline,
                  size: 20,
                  color: theme.colorScheme.secondary,
                ),
                const SizedBox(width: 8),
                Text(
                  l10n.aiQuestions,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...questions.asMap().entries.map((entry) {
              final i = entry.key;
              final q = entry.value;
              _answerControllers.putIfAbsent(i, () => TextEditingController());
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${i + 1}. $q', style: const TextStyle(fontSize: 14)),
                    const SizedBox(height: 4),
                    TextField(
                      controller: _answerControllers[i],
                      decoration: InputDecoration(
                        hintText: l10n.aiAnswerHint,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.tonal(
                onPressed: () => _answerAndResort(l10n, locale),
                child: Text(l10n.aiAnswerAndResort),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _answerAndResort(AppLocalizations l10n, String locale) async {
    final answers = <String>[];
    for (final entry in _answerControllers.entries) {
      final text = entry.value.text.trim();
      if (text.isNotEmpty) {
        answers.add(l10n.aiQuestionAnswer(entry.key + 1, text));
      }
    }

    if (answers.isEmpty) return;

    // 回答をタスクのメモに追記してホームへ戻る
    // ユーザーはホームからAI整理を再実行できる
    final aiResponse = ref.read(aiSortResponseProvider);
    final db = ref.read(databaseServiceProvider);
    if (aiResponse != null) {
      for (final r in aiResponse.tasks) {
        final task = await db.getTaskById(r.taskId);
        if (task != null) {
          final existingMemo = task.memo ?? '';
          final answerText = answers.join('\n');
          final newMemo = existingMemo.isEmpty
              ? answerText
              : '$existingMemo\n$answerText';
          await db.updateTask(
            task.copyWith(memo: newMemo, updatedAt: DateTime.now()),
          );
        }
        break; // 最初のタスクのみに追記（回答は全般的な情報）
      }
    }
    ref.invalidate(tasksProvider);

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.aiSorting)));
      context.go('/home');
    }
  }

  List<Widget> _buildPrioritySection(
    BuildContext context,
    AppLocalizations l10n,
    String locale,
    String title,
    Color color,
    List<Task> tasks,
    Map<int, AiSortResult> resultsMap, {
    required bool expanded,
  }) {
    if (tasks.isEmpty) return [];

    return [
      Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 8),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ),
      ...tasks.map((task) {
        final result = task.id != null ? resultsMap[task.id] : null;
        final subtasks = locale == 'ja'
            ? (result?.suggestedSubtasksJa ?? [])
            : (result?.suggestedSubtasksEn ?? []);

        if (expanded) {
          return _buildExpandedCard(
            context,
            l10n,
            locale,
            task,
            color,
            subtasks,
            result,
          );
        } else {
          return _buildCollapsibleCard(
            context,
            l10n,
            locale,
            task,
            color,
            subtasks,
            result,
          );
        }
      }),
    ];
  }

  Widget _buildExpandedCard(
    BuildContext context,
    AppLocalizations l10n,
    String locale,
    Task task,
    Color color,
    List<String> subtasks,
    AiSortResult? result,
  ) {
    final isPremium = ref.watch(isPremiumProvider);
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTaskHeader(context, task, color),
            _buildAiCommentBlock(context, l10n, task, isPremium,
                isUrgent: task.priority == 1),
            _buildPremiumGates(context, l10n, locale, task, result),
            _buildSubtaskSection(context, l10n, task, subtasks),
          ],
        ),
      ),
    );
  }

  Widget _buildCollapsibleCard(
    BuildContext context,
    AppLocalizations l10n,
    String locale,
    Task task,
    Color color,
    List<String> subtasks,
    AiSortResult? result,
  ) {
    final isPremium = ref.watch(isPremiumProvider);
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 12),
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        leading: Container(
          width: 4,
          height: 24,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        title: Text(
          task.title,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
        ),
        children: [
          _buildAiCommentBlock(context, l10n, task, isPremium,
              isUrgent: task.priority == 1),
          _buildPremiumGates(context, l10n, locale, task, result),
          _buildSubtaskSection(context, l10n, task, subtasks),
        ],
      ),
    );
  }

  /// AIコメントブロック: プレミアム=全表示 / 無料=緊急のみ表示、その他はPRO案内
  Widget _buildAiCommentBlock(
    BuildContext context,
    AppLocalizations l10n,
    Task task,
    bool isPremium, {
    required bool isUrgent,
  }) {
    if (task.aiComment == null || task.aiComment!.isEmpty) {
      return const SizedBox.shrink();
    }
    final theme = Theme.of(context);

    if (isPremium || isUrgent) {
      return Padding(
        padding: const EdgeInsets.only(left: 16, top: 6),
        child: Text(
          task.aiComment!,
          style: TextStyle(
            fontSize: 13,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    // 無料 + 非緊急: PRO案内
    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 6),
      child: Row(
        children: [
          Icon(Icons.lock_outline, size: 13, color: theme.colorScheme.outline),
          const SizedBox(width: 4),
          Text(
            l10n.aiCommentLockedHint,
            style: TextStyle(
              fontSize: 12,
              fontStyle: FontStyle.italic,
              color: theme.colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskHeader(BuildContext context, Task task, Color color) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 24,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            task.title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  Widget _buildPremiumGates(
    BuildContext context,
    AppLocalizations l10n,
    String locale,
    Task task,
    AiSortResult? result,
  ) {
    final isPremium = ref.watch(isPremiumProvider);
    final theme = Theme.of(context);
    final activeColor = theme.colorScheme.primary;
    final lockedColor = theme.colorScheme.outline;
    final reason = result == null
        ? null
        : (locale == 'ja' ? result.notifyReasonJa : result.notifyReasonEn);

    Widget row({
      required IconData icon,
      required String label,
      String? sub,
      required VoidCallback onTap,
    }) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
          child: Row(
            children: [
              Icon(icon,
                  size: 16, color: isPremium ? activeColor : lockedColor),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isPremium ? activeColor : lockedColor,
                      ),
                    ),
                    if (sub != null && sub.isNotEmpty)
                      Text(
                        sub,
                        style: TextStyle(
                          fontSize: 11,
                          color: lockedColor,
                        ),
                      ),
                  ],
                ),
              ),
              if (!isPremium)
                Icon(Icons.lock_outline, size: 14, color: lockedColor),
            ],
          ),
        ),
      );
    }

    final notifyDate = result?.notifyDate;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (notifyDate != null && notifyDate.isNotEmpty)
          row(
            icon: Icons.notifications_active_outlined,
            label: l10n.aiNotifyOn(notifyDate),
            sub: reason,
            onTap: () => _onTapNotify(context, l10n, locale, task, notifyDate),
          ),
        row(
          icon: Icons.calendar_month_outlined,
          label: l10n.aiCalendarAdd,
          onTap: () => _onTapCalendar(context, l10n, task),
        ),
      ],
    );
  }

  Future<void> _onTapNotify(
    BuildContext context,
    AppLocalizations l10n,
    String locale,
    Task task,
    String notifyDate,
  ) async {
    final isPremium = ref.read(isPremiumProvider);
    if (!isPremium) {
      await _showPremiumGateSheet(context, l10n);
      return;
    }
    final notifyService = ref.read(notificationServiceProvider);
    await notifyService.scheduleNotificationsForDates(
      task,
      dates: [notifyDate],
      isPremium: true,
      locale: locale,
    );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.notifyScheduled)),
      );
    }
  }

  Future<void> _onTapCalendar(
    BuildContext context,
    AppLocalizations l10n,
    Task task,
  ) async {
    final isPremium = ref.read(isPremiumProvider);
    if (!isPremium) {
      await _showPremiumGateSheet(context, l10n);
      return;
    }
    final cal = ref.read(calendarServiceProvider);
    final (result, _) = await cal.addTaskToCalendar(task);
    if (!context.mounted) return;
    final msg = result == CalendarResult.success
        ? l10n.aiCalendarAdded
        : (result == CalendarResult.permissionDenied
            ? l10n.calendarPermissionDenied
            : l10n.calendarAddFailed);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _showPremiumGateSheet(
    BuildContext context,
    AppLocalizations l10n,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.premiumGateTitle,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(l10n.premiumGateDesc),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                context.push('/store');
              },
              child: Text(l10n.premiumGateUpgrade),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(l10n.premiumGateLater),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubtaskSection(
    BuildContext context,
    AppLocalizations l10n,
    Task task,
    List<String> subtasks,
  ) {
    if (subtasks.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        const Divider(height: 1),
        const SizedBox(height: 8),
        Row(
          children: [
            const Text('💡 ', style: TextStyle(fontSize: 14)),
            Text(
              l10n.aiSubtaskSuggestion,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ...subtasks.map(
          (s) => Padding(
            padding: const EdgeInsets.only(left: 24, top: 2),
            child: Row(
              children: [
                const Text('• ', style: TextStyle(fontSize: 13)),
                Expanded(child: Text(s, style: const TextStyle(fontSize: 13))),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: () => _addSubtasks(context, l10n, task, subtasks),
            icon: const Icon(Icons.add, size: 16),
            label: Text(l10n.aiSubtaskAdd),
          ),
        ),
      ],
    );
  }

  Future<void> _addSubtasks(
    BuildContext context,
    AppLocalizations l10n,
    Task originalTask,
    List<String> subtasks,
  ) async {
    final now = DateTime.now();
    final daysUntilDue = originalTask.dueDate.difference(now).inDays;
    final totalDays = daysUntilDue > 0 ? daysUntilDue : subtasks.length;
    final interval = (totalDays / subtasks.length).ceil().clamp(1, 365);

    for (var i = 0; i < subtasks.length; i++) {
      final subDueDate = now.add(Duration(days: (i + 1) * interval));
      final subTask = Task(
        title: subtasks[i],
        dueDate: daysUntilDue > 0 && subDueDate.isAfter(originalTask.dueDate)
            ? originalTask.dueDate
            : subDueDate,
        categoryId: originalTask.categoryId,
        importance: originalTask.importance,
        createdAt: now,
        updatedAt: now,
      );
      await ref.read(tasksProvider.notifier).addTask(subTask);
    }

    if (!context.mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.aiSubtaskAdded)));

    final shouldComplete = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.aiCompleteOriginal),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.markComplete),
          ),
        ],
      ),
    );

    if (shouldComplete == true) {
      await ref.read(tasksProvider.notifier).toggleComplete(originalTask);
    }
  }

  Widget _buildPremiumBanner(
    BuildContext context,
    AppLocalizations l10n,
    ThemeData theme,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.workspace_premium,
                  size: 18, color: theme.colorScheme.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  l10n.aiPremiumBannerTitle,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            l10n.aiPremiumBannerDesc,
            style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => context.push('/store'),
              child: Text(l10n.aiPremiumBannerButton),
            ),
          ),
        ],
      ),
    );
  }
}
