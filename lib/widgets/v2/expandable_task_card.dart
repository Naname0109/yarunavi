import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../models/category.dart' as model;
import '../../models/task.dart';
import '../../providers/task_provider.dart';
import '../../theme/yaru_theme.dart';
import 'task_card.dart';

/// V2TaskCard を「タップで展開 / 二度目のタップで詳細へ」 のラッパーとして提供する。
///
/// 展開時に `_RecommendedDateRow` の ✏️ が押されると DatePicker が開き、
/// `tasksProvider.updateRecommendedDate` で永続化する (#1-1 編集導線)。
///
/// 展開状態のときは "詳細" リンクで `/task/$id` に遷移できる。
class ExpandableV2TaskCard extends ConsumerStatefulWidget {
  const ExpandableV2TaskCard({
    super.key,
    required this.task,
    required this.category,
    required this.onComplete,
  });

  final Task task;
  final model.Category? category;
  final VoidCallback onComplete;

  @override
  ConsumerState<ExpandableV2TaskCard> createState() =>
      _ExpandableV2TaskCardState();
}

class _ExpandableV2TaskCardState extends ConsumerState<ExpandableV2TaskCard> {
  bool _expanded = false;

  void _toggle() => setState(() => _expanded = !_expanded);

  Future<void> _pickRecommendedDate() async {
    final task = widget.task;
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
    if (!mounted) return;
    await ref
        .read(tasksProvider.notifier)
        .updateRecommendedDate(task.id!, picked);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.executionDayUpdated)),
    );
  }

  void _openDetail() {
    final id = widget.task.id;
    if (id != null) context.push('/task/$id');
  }

  @override
  Widget build(BuildContext context) {
    final yaru = context.yaru;
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        V2TaskCard(
          task: widget.task,
          category: widget.category,
          expanded: _expanded,
          onTap: _toggle,
          onToggleComplete: widget.onComplete,
          onEditRecommendedDate: _expanded ? _pickRecommendedDate : null,
        ),
        if (_expanded)
          Padding(
            padding: const EdgeInsets.only(top: 6, right: 4),
            child: Align(
              alignment: Alignment.centerRight,
              child: InkWell(
                onTap: _openDetail,
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
    );
  }
}
