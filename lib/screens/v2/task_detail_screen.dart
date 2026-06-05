import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../models/task.dart';
import '../../providers/task_provider.dart';
import '../../theme/yaru_colors.dart';
import '../../theme/yaru_theme.dart';
import '../../utils/date_utils.dart' as app_date;
import '../../widgets/glass_card.dart';
import '../../widgets/neon_button.dart';
import '../../widgets/responsive_wrapper.dart';
import '../../widgets/sparkle_badge.dart';
import '../../widgets/task_form_sheet.dart';

/// v2 タスク詳細画面 (新規)。
///
/// - 緊急度バッジ + カテゴリ/繰り返しチップ
/// - 大型タイトル
/// - リアルタイムカウントダウン (HH:MM:SS) — 期限が今日以前なら赤グロー
/// - AIアドバイスカード (グラデ枠線)
/// - メタ情報リスト (期限/繰り返し/カテゴリ/通知/想定時間)
/// - メモ
/// - 完了CTA
class V2TaskDetailScreen extends ConsumerStatefulWidget {
  const V2TaskDetailScreen({super.key, required this.taskId});
  final int taskId;

  @override
  ConsumerState<V2TaskDetailScreen> createState() => _V2TaskDetailScreenState();
}

class _V2TaskDetailScreenState extends ConsumerState<V2TaskDetailScreen> {
  Timer? _ticker;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final yaru = context.yaru;
    final l10n = AppLocalizations.of(context)!;
    // #4: 完了済みタスクも含めて検索するため allTasksProvider を watch する。
    final allTasksAsync = ref.watch(allTasksProvider);

    return allTasksAsync.when(
      loading: () => Scaffold(
        backgroundColor: yaru.scaffoldBg,
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: yaru.scaffoldBg,
        body: Center(child: Text('$e')),
      ),
      data: (tasks) {
        Task? task;
        for (final t in tasks) {
          if (t.id == widget.taskId) {
            task = t;
            break;
          }
        }
        if (task == null) {
          // タスクが見つからない (削除されたなど): ホームに戻る
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) context.pop();
          });
          return Scaffold(
            backgroundColor: yaru.scaffoldBg,
            body: const SizedBox.shrink(),
          );
        }
        return Scaffold(
          backgroundColor: yaru.scaffoldBg,
          body: SafeArea(
            child: ResponsiveWrapper(
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                      child: _topBar(context, yaru, task)),
                  SliverToBoxAdapter(
                      child: _titleBlock(context, yaru, l10n, task)),
                  SliverToBoxAdapter(
                      child: _countdownCard(yaru, l10n, task)),
                  if (task.aiComment != null && task.aiComment!.isNotEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                        child: _aiAdvice(yaru, l10n, task),
                      ),
                    ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                      child: _infoRows(yaru, l10n, task),
                    ),
                  ),
                  if (task.memo != null && task.memo!.isNotEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                        child: GlassCard(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'MEMO',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                  color: yaru.inkTertiary,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                task.memo!,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: yaru.inkPrimary,
                                  height: 1.7,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
                      child: Column(
                        children: [
                          // #1: 削除ボタンを完了ボタンの上に控えめに配置 (赤、opacity 0.7)
                          TextButton.icon(
                            onPressed: () =>
                                _confirmDeleteTask(context, l10n, task!),
                            icon: Icon(
                              Icons.delete_outline,
                              size: 18,
                              color:
                                  Colors.red.withValues(alpha: 0.7),
                            ),
                            label: Text(
                              l10n.taskDeleteThis,
                              style: TextStyle(
                                color:
                                    Colors.red.withValues(alpha: 0.7),
                                fontSize: 14,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          // #4: 完了済みなら「未完了に戻す」、 未完了なら「完了にする」
                          NeonButton(
                            label: task.isCompleted
                                ? l10n.uncompleteTask
                                : l10n.taskCompleteAction,
                            icon: task.isCompleted
                                ? Icons.undo_rounded
                                : Icons.check_rounded,
                            height: 54,
                            onPressed: () async {
                              if (task!.isCompleted) {
                                await ref
                                    .read(tasksProvider.notifier)
                                    .uncompleteTask(task);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context)
                                      .clearSnackBars();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content:
                                          Text(l10n.taskUncompletedSnack),
                                      duration: const Duration(seconds: 4),
                                    ),
                                  );
                                  context.pop();
                                }
                              } else {
                                await ref
                                    .read(tasksProvider.notifier)
                                    .completeTask(task);
                                if (context.mounted) context.pop();
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// #1: タスク削除の確認 → DB 削除 → 前画面に戻る + SnackBar。
  Future<void> _confirmDeleteTask(
    BuildContext context,
    AppLocalizations l10n,
    Task task,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.taskDeleteConfirmTitle),
        content: Text(l10n.taskDeleteConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    // 親 State の mounted を確認後に messenger を取り出し、 await 後でも安全に使う
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    if (task.id != null) {
      await ref.read(tasksProvider.notifier).deleteTask(task.id!);
    }
    if (!mounted) return;
    router.pop();
    messenger
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(l10n.taskDeletedSnack)));
  }

  Widget _topBar(BuildContext context, YaruTheme yaru, Task task) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              context.pop();
            },
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: yaru.paper,
                border: Border.all(color: yaru.line),
              ),
              child: Icon(Icons.chevron_left_rounded,
                  size: 18, color: yaru.inkSecondary),
            ),
          ),
          const Spacer(),
          OutlinedButton.icon(
            onPressed: () {
              context.pop();
              TaskFormSheet.show(context, task: task);
            },
            icon: const Icon(Icons.edit_rounded, size: 14),
            label: Text(AppLocalizations.of(context)!.editTask),
          ),
        ],
      ),
    );
  }

  Widget _titleBlock(
    BuildContext context,
    YaruTheme yaru,
    AppLocalizations l10n,
    Task task,
  ) {
    final priorityColor = YaruColors.getPriorityColor(
      task.priority,
      task.dueDate,
      isDark: Theme.of(context).brightness == Brightness.dark,
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _chip(
                yaru: yaru,
                label: _priorityLabel(l10n, task.priority),
                color: priorityColor,
                strong: true,
              ),
              if (task.recurrenceType != null)
                _chip(yaru: yaru, label: l10n.recurrence, color: yaru.inkSecondary),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            task.title,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: yaru.inkPrimary,
              height: 1.2,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip({
    required YaruTheme yaru,
    required String label,
    required Color color,
    bool strong = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: strong
            ? color.withValues(alpha: 0.15)
            : Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: strong ? color.withValues(alpha: 0.35) : yaru.line,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
          color: strong ? color : yaru.inkSecondary,
          letterSpacing: 0.6,
        ),
      ),
    );
  }

  /// #4: 期限カウントダウンを 日/時/分/秒 単位で表示。
  /// - 1 日以上残: N日 H時間 M分 (秒は省略)
  /// - 1 日未満:   H時間 M分 S秒
  /// - 期限切れ:    (N日) H時間 超過
  String _formatCountdown(
      Duration remaining, bool overdue, AppLocalizations l10n) {
    final days = remaining.inDays;
    final hours = remaining.inHours % 24;
    final minutes = remaining.inMinutes % 60;
    final seconds = remaining.inSeconds % 60;
    final isJa = l10n.localeName == 'ja';
    if (overdue) {
      if (days > 0) {
        return isJa
            ? '$days日 ${hours}時間 超過'
            : '${days}d ${hours}h overdue';
      }
      return isJa ? '${hours}時間 超過' : '${hours}h overdue';
    }
    if (days > 0) {
      return isJa
          ? '$days日 ${hours}時間 ${minutes}分'
          : '${days}d ${hours}h ${minutes}m';
    }
    return isJa
        ? '${hours}時間 ${minutes}分 ${seconds}秒'
        : '${hours}h ${minutes}m ${seconds}s';
  }

  String _priorityLabel(AppLocalizations l10n, int priority) {
    return switch (priority) {
      1 => l10n.labelUrgent,
      2 => l10n.labelNow,
      3 => l10n.labelLater,
      4 => l10n.labelThisWeek,
      _ => l10n.labelNormal,
    };
  }

  Widget _countdownCard(YaruTheme yaru, AppLocalizations l10n, Task task) {
    // #4: 完了済みタスクではカウントダウンを「完了済み」 + 完了日に切り替え
    final isCompleted = task.isCompleted;
    final diff = task.dueDate.difference(_now);
    final overdue = !isCompleted && diff.isNegative;
    final remaining = diff.abs();
    final locale = Localizations.localeOf(context).languageCode;
    final countdownText = isCompleted
        ? l10n.completed
        : _formatCountdown(remaining, overdue, l10n);
    final accent = isCompleted
        ? yaru.calm
        : overdue
            ? yaru.urgent
            : yaru.flame;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        borderColor: accent.withValues(alpha: 0.25),
        child: Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 2,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [accent, yaru.sparkle]),
                  boxShadow: yaru.useGlassBlur
                      ? [BoxShadow(color: accent.withValues(alpha: 0.7), blurRadius: 12)]
                      : null,
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: accent,
                        shape: BoxShape.circle,
                        boxShadow: yaru.useGlassBlur
                            ? [BoxShadow(color: accent.withValues(alpha: 0.6), blurRadius: 6)]
                            : null,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isCompleted
                          ? l10n.completed
                          : (overdue
                              ? l10n.labelOverdue
                              : l10n.taskDetailCountdown),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: accent,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  countdownText,
                  style: TextStyle(
                    fontSize: isCompleted ? 24 : 32,
                    fontWeight: FontWeight.w800,
                    color: yaru.inkPrimary,
                    height: 1.1,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isCompleted && task.completedAt != null
                      ? l10n.taskCompletedOn(
                          app_date.formatDateWithWeekday(
                              task.completedAt!, locale))
                      : app_date.formatDateWithWeekday(task.dueDate, locale),
                  style: TextStyle(
                    fontSize: 11,
                    color: yaru.inkTertiary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _aiAdvice(YaruTheme yaru, AppLocalizations l10n, Task task) {
    return Container(
      padding: const EdgeInsets.all(1),
      decoration: BoxDecoration(
        gradient: yaru.neonGradient,
        borderRadius: BorderRadius.circular(22),
        boxShadow: yaru.useGlassBlur
            ? [
                BoxShadow(
                  color: yaru.sparkle.withValues(alpha: 0.5),
                  blurRadius: 60,
                  spreadRadius: -20,
                  offset: const Offset(0, 24),
                ),
              ]
            : null,
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: yaru.paper,
          borderRadius: BorderRadius.circular(21),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SparkleBadge(size: 32),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.aiNaviAdviceBadge,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: yaru.accent,
                        letterSpacing: 1.4,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.aiNaviAdviceLabel,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: yaru.inkPrimary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              task.aiComment ?? '',
              style: TextStyle(
                fontSize: 13.5,
                color: yaru.inkPrimary,
                height: 1.75,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRows(YaruTheme yaru, AppLocalizations l10n, Task task) {
    final locale = Localizations.localeOf(context).languageCode;
    return GlassCard(
      padding: EdgeInsets.zero,
      borderRadius: 16,
      child: Column(
        children: [
          _row(
            icon: Icons.event_rounded,
            label: l10n.labelDue,
            value: app_date.formatDateWithWeekday(task.dueDate, locale),
            yaru: yaru,
          ),
          if (task.recommendedDate != null) ...[
            _divider(yaru),
            // #1: 実行日 (rec_date) はタップで DatePicker → 変更可能
            InkWell(
              onTap: () => _pickRecommendedDate(context, task),
              child: _row(
                icon: Icons.flag_outlined,
                label: l10n.labelExecutionDay,
                value: app_date.formatDateWithWeekday(
                    task.recommendedDate!, locale),
                yaru: yaru,
                trailing: Icon(Icons.edit, size: 16, color: yaru.inkSecondary),
              ),
            ),
          ],
          if (task.recurrenceType != null)
            _divider(yaru),
          if (task.recurrenceType != null)
            _row(
              icon: Icons.repeat_rounded,
              label: l10n.labelRepeat,
              value: _recurrenceLabel(l10n, task.recurrenceType!),
              yaru: yaru,
            ),
          if (task.estimatedTime != null && task.estimatedTime!.isNotEmpty) ...[
            _divider(yaru),
            _row(
              icon: Icons.bolt_rounded,
              label: l10n.labelEst,
              value: task.estimatedTime!,
              yaru: yaru,
            ),
          ],
        ],
      ),
    );
  }

  Widget _divider(YaruTheme yaru) =>
      Container(height: 1, color: yaru.line);

  Widget _row({
    required IconData icon,
    required String label,
    required String value,
    required YaruTheme yaru,
    Widget? trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 14, color: yaru.inkTertiary),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: yaru.inkTertiary,
              letterSpacing: 1.2,
            ),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: yaru.inkPrimary,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 6), trailing],
        ],
      ),
    );
  }

  /// #1: 実行日 (rec_date) を DatePicker で変更。 due_date が lastDate。
  Future<void> _pickRecommendedDate(BuildContext context, Task task) async {
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastDate = task.dueDate.isBefore(today)
        ? today.add(const Duration(days: 30))
        : task.dueDate;
    final initial = task.recommendedDate ?? today;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(today) ? today : initial,
      firstDate: today,
      lastDate: lastDate,
      helpText: l10n.pickExecutionDayTooltip,
    );
    if (picked == null || task.id == null) return;
    if (!context.mounted) return;
    await ref
        .read(tasksProvider.notifier)
        .updateRecommendedDate(task.id!, picked);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.executionDayUpdated)),
    );
  }

  String _recurrenceLabel(AppLocalizations l10n, String type) {
    return switch (type) {
      'daily' => l10n.recurrenceWeekly, // 既存キー流用 (none/weekly/monthly/yearly)
      'weekly' => l10n.recurrenceWeekly,
      'monthly' => l10n.recurrenceMonthly,
      'yearly' => l10n.recurrenceYearly,
      _ => type,
    };
  }
}
