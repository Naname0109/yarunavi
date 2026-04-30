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
import '../utils/notification_utils.dart';
import '../widgets/ai_sort_button.dart';
import '../widgets/responsive_wrapper.dart';

class AiResultScreen extends ConsumerStatefulWidget {
  const AiResultScreen({super.key});

  @override
  ConsumerState<AiResultScreen> createState() => _AiResultScreenState();
}

class _AiResultScreenState extends ConsumerState<AiResultScreen> {
  final _answerControllers = <int, TextEditingController>{};
  bool _autoSetupDone = false;
  String? _autoSetupMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _runAutoSetup());
  }

  /// プレミアムユーザー: 通知+カレンダーを全自動設定
  Future<void> _runAutoSetup() async {
    final isPremium = ref.read(isPremiumProvider);
    if (!isPremium || _autoSetupDone) return;

    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final aiResponse = ref.read(aiSortResponseProvider);
    final notifyService = ref.read(notificationServiceProvider);
    final calendarService = ref.read(calendarServiceProvider);
    final db = ref.read(databaseServiceProvider);

    if (aiResponse == null) return;

    try {
      final tasks = await db.getTasksByFilter('all');
      final taskMap = {for (final t in tasks) t.id: t};

      final hasCalendarPermission = await calendarService.requestPermission();
      bool calendarAdded = false;

      for (final r in aiResponse.tasks) {
        final task = taskMap[r.taskId];
        if (task == null || task.isCompleted) continue;

        try {
          final hasManualNotify = task.notifySettings != null &&
              !isAiAutoNotify(task.notifySettings);

          if (!hasManualNotify &&
              r.notifyDate != null &&
              r.notifyDate!.isNotEmpty) {
            await notifyService.scheduleNotificationsForDates(
              task,
              dates: [r.notifyDate!],
              isPremium: true,
              locale: locale,
            );
          }

          if (hasCalendarPermission &&
              task.priority <= 2 &&
              task.calendarEventId == null) {
            final (result, eventId) =
                await calendarService.addTaskToCalendar(task);
            if (result == CalendarResult.success && eventId != null) {
              await db.updateTask(task.copyWith(calendarEventId: eventId));
              calendarAdded = true;
            }
          }
        } catch (e) {
          debugPrint('Auto-setup error for task ${task.id}: $e');
        }
      }

      if (mounted) {
        setState(() {
          _autoSetupDone = true;
          if (calendarAdded) {
            _autoSetupMessage = l10n.aiAutoSettingsComplete;
          } else if (hasCalendarPermission) {
            _autoSetupMessage = l10n.aiAutoNotifyOnly;
          } else {
            _autoSetupMessage =
                '${l10n.aiAutoNotifyOnly}\n${l10n.aiAutoCalendarPermission}';
          }
        });
        ref.invalidate(tasksProvider);
      }
    } catch (e) {
      debugPrint('Auto-setup failed: $e');
      if (mounted) {
        setState(() {
          _autoSetupDone = true;
          _autoSetupMessage = l10n.aiAutoNotifyOnly;
        });
      }
    }
  }

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
    final isPremium = ref.watch(isPremiumProvider);
    final sortedAtStr = DateFormat.yMMMd(locale).add_Hm().format(DateTime.now());
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
            final aiTasks = aiResponse?.tasks ?? [];
            int p1Count = 0, p2Count = 0, laterCount = 0;
            for (final r in aiTasks) {
              switch (r.priority) {
                case 1: p1Count++;
                case 2: p2Count++;
                case 3 || 4: laterCount++;
              }
            }

            final incompleteTasks = tasks
                .where((t) => !t.isCompleted && t.priority > 0)
                .toList();
            final groups = <int, List<Task>>{};
            for (final t in incompleteTasks) {
              groups.putIfAbsent(t.priority, () => []).add(t);
            }

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (isPremium && _autoSetupMessage != null)
                  _buildAutoSetupBanner(theme),

                if (!isPremium)
                  _buildFreePremiumBanner(context, l10n, theme),

                _buildSummaryCard(context, l10n, summary, p1Count, p2Count, laterCount),
                const SizedBox(height: 8),
                Text(
                  l10n.aiResultSortedAt(sortedAtStr),
                  style: TextStyle(fontSize: 12, color: theme.colorScheme.outline),
                ),

                if (questions.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildQuestionsSection(context, l10n, locale, questions),
                ],

                const SizedBox(height: 12),

                ..._buildPrioritySection(
                  context, l10n, locale,
                  l10n.aiPriorityUrgent,
                  isDark ? AppColors.priorityUrgentDark : AppColors.priorityUrgent,
                  groups[1] ?? [], resultsMap, isPremium,
                ),
                ..._buildPrioritySection(
                  context, l10n, locale,
                  l10n.aiPriorityWarning,
                  isDark ? AppColors.priorityWarningDark : AppColors.priorityWarning,
                  groups[2] ?? [], resultsMap, isPremium,
                ),
                ..._buildPrioritySection(
                  context, l10n, locale,
                  l10n.aiPriorityNormal,
                  isDark ? AppColors.priorityNormalDark : AppColors.priorityNormal,
                  groups[3] ?? [], resultsMap, isPremium,
                ),
                ..._buildPrioritySection(
                  context, l10n, locale,
                  l10n.aiPriorityRelaxed,
                  isDark ? AppColors.priorityRelaxedDark : AppColors.priorityRelaxed,
                  groups[4] ?? [], resultsMap, isPremium,
                ),

                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () {
                    ref.invalidate(tasksProvider);
                    context.go('/home');
                  },
                  icon: const Icon(Icons.home),
                  label: Text(l10n.backToHome),
                ),
                const SizedBox(height: 32),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildAutoSetupBanner(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _autoSetupMessage!,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: theme.brightness == Brightness.dark
                      ? Colors.green.shade300
                      : Colors.green.shade800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFreePremiumBanner(BuildContext context, AppLocalizations l10n, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.workspace_premium, size: 18, color: theme.colorScheme.primary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    l10n.aiPremiumAutoPrompt,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: () => context.push('/store'),
                child: Text(l10n.aiPremiumAutoTrial),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
    BuildContext context, AppLocalizations l10n, String? summary,
    int todayCount, int weekCount, int laterCount,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
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
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome, size: 20, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(l10n.aiTodayPlan,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
            if (summary != null) ...[
              const SizedBox(height: 12),
              Text(summary, style: theme.textTheme.bodyMedium),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8, runSpacing: 6,
              children: [
                _buildCountChip(context, l10n.aiTodayTasks(todayCount),
                    isDark ? AppColors.priorityUrgentDark : AppColors.priorityUrgent),
                _buildCountChip(context, l10n.aiWeekTasks(weekCount),
                    isDark ? AppColors.priorityWarningDark : AppColors.priorityWarning),
                _buildCountChip(context, l10n.aiLaterTasks(laterCount),
                    isDark ? AppColors.priorityNormalDark : AppColors.priorityNormal),
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
      child: Text(text, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
    );
  }

  Widget _buildQuestionsSection(
    BuildContext context, AppLocalizations l10n, String locale, List<String> questions,
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
                Icon(Icons.help_outline, size: 20, color: theme.colorScheme.secondary),
                const SizedBox(width: 8),
                Text(l10n.aiQuestions,
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
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
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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

    final aiResponse = ref.read(aiSortResponseProvider);
    final db = ref.read(databaseServiceProvider);
    if (aiResponse != null) {
      for (final r in aiResponse.tasks) {
        final task = await db.getTaskById(r.taskId);
        if (task != null) {
          final existingMemo = task.memo ?? '';
          final answerText = answers.join('\n');
          final newMemo = existingMemo.isEmpty ? answerText : '$existingMemo\n$answerText';
          await db.updateTask(task.copyWith(memo: newMemo, updatedAt: DateTime.now()));
        }
        break;
      }
    }
    ref.invalidate(tasksProvider);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.aiSorting)));
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
    Map<int, AiSortResult> resultsMap,
    bool isPremium,
  ) {
    if (tasks.isEmpty) return [];
    return [
      Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 8),
        child: Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
      ),
      ...tasks.map((task) {
        final result = task.id != null ? resultsMap[task.id] : null;
        final subtasks = locale == 'ja'
            ? (result?.suggestedSubtasksJa ?? [])
            : (result?.suggestedSubtasksEn ?? []);
        final aiComment = locale == 'ja'
            ? (result?.commentJa ?? task.aiComment)
            : (result?.commentEn ?? task.aiComment);
        final taskWithComment = aiComment != null && aiComment != task.aiComment
            ? task.copyWith(aiComment: aiComment)
            : task;
        final notifyReason = locale == 'ja' ? result?.notifyReasonJa : result?.notifyReasonEn;

        return _AiTaskCard(
          task: taskWithComment,
          color: color,
          subtasks: subtasks,
          isPremium: isPremium,
          notifyDate: result?.notifyDate,
          notifyReason: notifyReason,
        );
      }),
    ];
  }
}

/// AI整理結果画面のタスクカード（折りたたみ対応）
class _AiTaskCard extends ConsumerStatefulWidget {
  const _AiTaskCard({
    required this.task,
    required this.color,
    required this.subtasks,
    required this.isPremium,
    this.notifyDate,
    this.notifyReason,
  });

  final Task task;
  final Color color;
  final List<String> subtasks;
  final bool isPremium;
  final String? notifyDate;
  final String? notifyReason;

  @override
  ConsumerState<_AiTaskCard> createState() => _AiTaskCardState();
}

class _AiTaskCardState extends ConsumerState<_AiTaskCard> {
  bool _expanded = false;

  Future<void> _pickDate() async {
    final task = widget.task;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: task.recommendedDate ?? today,
      firstDate: today,
      lastDate: task.dueDate,
    );
    if (picked == null || !mounted) return;
    final db = ref.read(databaseServiceProvider);
    await db.updateRecommendedDate(task.id!, picked);
    ref.invalidate(tasksProvider);
  }

  Future<void> _addSubtasks(AppLocalizations l10n, Task originalTask, List<String> subtasks) async {
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
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.aiSubtaskAdded)));

    final shouldComplete = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.aiCompleteOriginal),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(l10n.cancel)),
          FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(l10n.markComplete)),
        ],
      ),
    );

    if (shouldComplete == true) {
      await ref.read(tasksProvider.notifier).toggleComplete(originalTask);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final theme = Theme.of(context);
    final fmt = DateFormat.MMMd(locale);
    final task = widget.task;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => setState(() => _expanded = !_expanded),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 折りたたみヘッダー
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 4,
                    height: 32,
                    decoration: BoxDecoration(
                      color: widget.color,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.title,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (task.recommendedDate != null)
                          Text(
                            '📌 ${fmt.format(task.recommendedDate!)}',
                            style: TextStyle(fontSize: 12, color: theme.colorScheme.primary),
                          ),
                      ],
                    ),
                  ),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    color: theme.colorScheme.outline,
                  ),
                ],
              ),
              // 展開コンテンツ（AnimatedCrossFade）
              AnimatedCrossFade(
                duration: const Duration(milliseconds: 200),
                crossFadeState: _expanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                firstChild: const SizedBox(width: double.infinity),
                secondChild: _buildDetails(context, l10n, fmt, theme),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetails(
    BuildContext context,
    AppLocalizations l10n,
    DateFormat fmt,
    ThemeData theme,
  ) {
    final task = widget.task;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        const Divider(height: 1),
        const SizedBox(height: 8),

        // AIコメント
        if (task.aiComment != null && task.aiComment!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 8),
            child: widget.isPremium || task.priority == 1
                ? Text(
                    task.aiComment!,
                    style: TextStyle(
                        fontSize: 13,
                        color: theme.colorScheme.onSurfaceVariant),
                  )
                : Row(
                    children: [
                      Icon(Icons.lock_outline,
                          size: 13, color: theme.colorScheme.outline),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          l10n.aiCommentLockedHint,
                          style: TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                              color: theme.colorScheme.outline),
                        ),
                      ),
                    ],
                  ),
          ),

        // 推奨実行日（タップで変更）
        if (task.recommendedDate != null)
          Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 4),
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: _pickDate,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.push_pin, size: 14, color: theme.colorScheme.primary),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        l10n.recommendedDateEditHint(fmt.format(task.recommendedDate!)),
                        style: TextStyle(
                            fontSize: 12, color: theme.colorScheme.primary),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.edit, size: 13, color: theme.colorScheme.primary),
                  ],
                ),
              ),
            ),
          ),

        // 期限日
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 4),
          child: Row(
            children: [
              Icon(Icons.schedule, size: 14, color: theme.colorScheme.outline),
              const SizedBox(width: 4),
              Text(
                l10n.dueDateLabel(fmt.format(task.dueDate)),
                style: TextStyle(fontSize: 12, color: theme.colorScheme.outline),
              ),
            ],
          ),
        ),

        // 通知予定 + 通知理由
        if (widget.notifyDate != null && widget.notifyDate!.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Row(
              children: [
                Icon(Icons.notifications_outlined,
                    size: 14, color: theme.colorScheme.outline),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    '🔔 ${widget.notifyDate!}',
                    style: TextStyle(
                        fontSize: 12, color: theme.colorScheme.outline),
                  ),
                ),
              ],
            ),
          ),
          if (widget.notifyReason != null && widget.notifyReason!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 32, top: 2, bottom: 4),
              child: Text(
                widget.notifyReason!,
                style: TextStyle(
                    fontSize: 11,
                    color: theme.colorScheme.outline,
                    fontStyle: FontStyle.italic),
              ),
            )
          else
            const SizedBox(height: 4),
        ],

        // サブタスク提案
        if (widget.subtasks.isNotEmpty) ...[
          const SizedBox(height: 4),
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
                    color: theme.colorScheme.primary),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ...widget.subtasks.map((s) => Padding(
                padding: const EdgeInsets.only(left: 24, top: 2),
                child: Row(
                  children: [
                    const Text('• ', style: TextStyle(fontSize: 13)),
                    Expanded(
                        child: Text(s, style: const TextStyle(fontSize: 13))),
                  ],
                ),
              )),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () =>
                  _addSubtasks(l10n, task, widget.subtasks),
              icon: const Icon(Icons.add, size: 16),
              label: Text(l10n.aiSubtaskAdd),
            ),
          ),
        ],
      ],
    );
  }
}
