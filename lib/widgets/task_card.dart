import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/task.dart';
import '../models/category.dart' as model;
import '../theme/colors.dart';
import '../utils/date_utils.dart' as app_date;

class TaskCard extends StatelessWidget {
  const TaskCard({
    super.key,
    required this.task,
    this.category,
    required this.onTap,
    required this.onToggleComplete,
    required this.onDelete,
  });

  final Task task;
  final model.Category? category;
  final VoidCallback onTap;
  final VoidCallback onToggleComplete;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final priorityColor = AppColors.getPriorityColor(task.priority, task.dueDate);

    return Dismissible(
      key: Key('task_${task.id}'),
      // 左スワイプ: 削除
      direction: DismissDirection.horizontal,
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.endToStart) {
          // 左スワイプ: 削除確認ダイアログ
          return showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(l10n.deleteConfirmTitle),
              content: Text(l10n.deleteConfirmMessage),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(l10n.cancel),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text(l10n.delete),
                ),
              ],
            ),
          );
        }
        // 右スワイプ: 完了/未完了トグル（カードは消さずに状態更新）
        onToggleComplete();
        return false;
      },
      onDismissed: (direction) {
        if (direction == DismissDirection.endToStart) {
          onDelete();
        }
      },
      background: _buildSwipeBackground(
        alignment: Alignment.centerLeft,
        color: task.isCompleted ? Colors.orange : Colors.green,
        icon: task.isCompleted ? Icons.undo : Icons.check,
        label: task.isCompleted ? l10n.markIncomplete : l10n.markComplete,
      ),
      secondaryBackground: _buildSwipeBackground(
        alignment: Alignment.centerRight,
        color: AppColors.priorityUrgent,
        icon: Icons.delete,
        label: l10n.delete,
      ),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: IntrinsicHeight(
            child: Row(
              children: [
                // 優先度カラーバー
                Container(
                  width: 4,
                  color: priorityColor,
                ),
                // 完了チェックボックス
                Checkbox(
                  value: task.isCompleted,
                  onChanged: (_) => onToggleComplete(),
                ),
                // タスク情報
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            decoration: task.isCompleted
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          app_date.formatRelativeDate(task.dueDate, l10n, locale),
                          style: TextStyle(
                            fontSize: 13,
                            color: _getDueDateTextColor(task.dueDate, context),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // カテゴリアイコン + 定期タスクアイコン
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (task.recurrenceType != null)
                        const Padding(
                          padding: EdgeInsets.only(right: 4),
                          child: Text('🔄', style: TextStyle(fontSize: 16)),
                        ),
                      if (category != null)
                        Text(category!.icon, style: const TextStyle(fontSize: 18)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getDueDateTextColor(DateTime dueDate, BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(dueDate.year, dueDate.month, dueDate.day);
    final diff = due.difference(today).inDays;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (diff < 0) return AppColors.priorityUrgent;
    if (diff == 0) return AppColors.priorityUrgent;
    if (diff <= 3) return AppColors.priorityWarning;
    return isDark ? AppColors.priorityRelaxedDark : AppColors.priorityRelaxed;
  }

  Widget _buildSwipeBackground({
    required Alignment alignment,
    required Color color,
    required IconData icon,
    required String label,
  }) {
    return Container(
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      color: color,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
