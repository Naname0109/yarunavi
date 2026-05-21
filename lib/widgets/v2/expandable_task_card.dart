import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../models/category.dart' as model;
import '../../models/task.dart';
import '../../providers/task_provider.dart';
import '../../theme/yaru_theme.dart';
import 'task_card.dart';

/// V2TaskCard を「タップで展開 / もう一度タップで閉じる」 ラッパーとして提供する。
///
/// 展開状態は親が `isExpanded` + `onToggleExpand` で管理する。
/// これにより 1 リスト内で同時に開けるカードを 1 つに制限できる (Gmail 風)。
///
/// 展開時に `_RecommendedDateRow` の ✏️ が押されると DatePicker が開き、
/// `tasksProvider.updateRecommendedDate` で永続化する (#1-1 編集導線)。
/// 展開状態では "詳細" リンクで `/task/$id` に遷移可能。
class ExpandableV2TaskCard extends ConsumerWidget {
  const ExpandableV2TaskCard({
    super.key,
    required this.task,
    required this.category,
    required this.onComplete,
    required this.isExpanded,
    required this.onToggleExpand,
  });

  final Task task;
  final model.Category? category;
  final VoidCallback onComplete;
  final bool isExpanded;
  final VoidCallback onToggleExpand;

  Future<void> _pickRecommendedDate(
      BuildContext context, WidgetRef ref) async {
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

  void _openDetail(BuildContext context) {
    final id = task.id;
    if (id != null) context.push('/task/$id');
  }

  /// #3: 左スワイプ削除確認ダイアログ
  Future<bool> _confirmDelete(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final res = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteConfirmTitle),
        content: Text(l10n.deleteConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.delete,
                style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    return res == true;
  }

  /// #3: スワイプ完了 (未完了→完了) 後の処理
  Future<void> _swipeComplete(BuildContext context, WidgetRef ref) async {
    await ref.read(tasksProvider.notifier).completeTask(task);
  }

  /// #3: スワイプで未完了に戻す
  Future<void> _swipeUncomplete(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    await ref.read(tasksProvider.notifier).uncompleteTask(task);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.taskUncompletedSnack),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  /// #3: スワイプ削除を実行
  Future<void> _swipeDelete(WidgetRef ref) async {
    final id = task.id;
    if (id == null) return;
    await ref.read(tasksProvider.notifier).deleteTask(id);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final yaru = context.yaru;
    final l10n = AppLocalizations.of(context)!;
    final isCompleted = task.isCompleted;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget swipeBg({
      required IconData icon,
      required Color color,
      required Alignment alignment,
    }) {
      return Container(
        alignment: alignment,
        padding: EdgeInsets.symmetric(
          horizontal: 24,
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: isDark ? 0.3 : 0.18),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, size: 28, color: color),
      );
    }

    // #3: 右スワイプ = 完了/未完了戻し、 左スワイプ = 削除確認
    final leftBg = isCompleted
        ? swipeBg(
            icon: Icons.undo_rounded,
            color: Colors.blue,
            alignment: Alignment.centerLeft,
          )
        : swipeBg(
            icon: Icons.check_circle_rounded,
            color: Colors.green,
            alignment: Alignment.centerLeft,
          );
    final rightBg = swipeBg(
      icon: Icons.delete_outline_rounded,
      color: Colors.red,
      alignment: Alignment.centerRight,
    );

    final card = Semantics(
      button: true,
      expanded: isExpanded,
      label: isExpanded
          ? l10n.taskCardExpandedSemantics(task.title)
          : l10n.taskCardCollapsedSemantics(task.title),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          V2TaskCard(
            task: task,
            category: category,
            expanded: isExpanded,
            onTap: onToggleExpand,
            onToggleComplete: onComplete,
            onEditRecommendedDate:
                isExpanded ? () => _pickRecommendedDate(context, ref) : null,
          ),
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.only(top: 6, right: 4),
              child: Align(
                alignment: Alignment.centerRight,
                child: InkWell(
                  onTap: () => _openDetail(context),
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          l10n.viewDetails,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: yaru.accent,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Icon(Icons.chevron_right_rounded,
                            size: 16, color: yaru.accent),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );

    // #3: Dismissible で右/左スワイプを実装
    // ID が無いタスク (saved していない) は key 衝突を避けるためスワイプ不可
    if (task.id == null) return card;
    return Dismissible(
      key: ValueKey('task_swipe_${task.id}'),
      background: leftBg,
      secondaryBackground: rightBg,
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          // 右スワイプ
          if (isCompleted) {
            await _swipeUncomplete(context, ref);
          } else {
            await _swipeComplete(context, ref);
          }
          return false; // tasksProvider invalidation で再描画されるため、 自前で消さない
        } else {
          // 左スワイプ: 削除確認
          final ok = await _confirmDelete(context);
          if (ok) {
            await _swipeDelete(ref);
          }
          return false;
        }
      },
      child: card,
    );
  }
}
