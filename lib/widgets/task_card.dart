import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/task.dart';
import '../models/category.dart' as model;
import '../providers/purchase_provider.dart';
import '../theme/colors.dart';
import '../utils/date_utils.dart' as app_date;
import '../utils/notification_utils.dart';

class TaskCard extends ConsumerStatefulWidget {
  const TaskCard({
    super.key,
    required this.task,
    this.category,
    required this.onTap,
    required this.onToggleComplete,
    required this.onDelete,
    this.disableSwipe = false,
  });

  final Task task;
  final model.Category? category;
  final VoidCallback onTap;
  final VoidCallback onToggleComplete;
  final VoidCallback onDelete;
  /// ReorderableListView内ではスワイプ無効化
  final bool disableSwipe;

  @override
  ConsumerState<TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends ConsumerState<TaskCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _completeAnimController;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;
  bool _isCompletingAnimation = false;
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    _completeAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnim = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _completeAnimController, curve: Curves.easeOut),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _completeAnimController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _completeAnimController.dispose();
    super.dispose();
  }

  void _handleComplete() {
    HapticFeedback.lightImpact();
    if (widget.task.isCompleted) {
      // 未完了に戻す場合はアニメーションなし
      widget.onToggleComplete();
      return;
    }
    // 完了アニメーション
    setState(() => _isCompletingAnimation = true);
    _completeAnimController.forward().then((_) {
      if (mounted) {
        widget.onToggleComplete();
        // アニメーションリセット（リストが再構築されるため）
        _completeAnimController.reset();
        setState(() => _isCompletingAnimation = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final priorityColor =
        AppColors.getPriorityColor(widget.task.priority, widget.task.dueDate);

    Widget card = Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => setState(() => _expanded = !_expanded),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IntrinsicHeight(
              child: Row(
                children: [
                  Container(width: 4, color: priorityColor),
                  Checkbox(
                    value: widget.task.isCompleted || _isCompletingAnimation,
                    onChanged: (_) => _handleComplete(),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.task.title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              decoration: widget.task.isCompleted
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            app_date.formatRelativeDate(
                                widget.task.dueDate, l10n, locale),
                            style: TextStyle(
                              fontSize: 13,
                              color: _getDueDateTextColor(
                                  widget.task.dueDate, context),
                            ),
                          ),
                          // 折りたたみ時のAIコメントプレビュー
                          if (!_expanded &&
                              widget.task.aiComment != null &&
                              widget.task.aiComment!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                widget.task.aiComment!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.task.recurrenceType != null)
                          const Padding(
                            padding: EdgeInsets.only(right: 4),
                            child: Text('🔄', style: TextStyle(fontSize: 16)),
                          ),
                        if (widget.category != null)
                          Text(widget.category!.icon,
                              style: const TextStyle(fontSize: 18)),
                        Icon(
                          _expanded ? Icons.expand_less : Icons.expand_more,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 200),
              crossFadeState: _expanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              firstChild: const SizedBox(width: double.infinity),
              secondChild: _buildExpandedContent(context, l10n, locale),
            ),
          ],
        ),
      ),
    );

    // 完了アニメーション
    if (_isCompletingAnimation) {
      card = FadeTransition(
        opacity: _fadeAnim,
        child: ScaleTransition(
          scale: _scaleAnim,
          child: card,
        ),
      );
    }

    if (widget.disableSwipe) {
      return card;
    }

    return Dismissible(
      key: Key('task_${widget.task.id}'),
      direction: DismissDirection.horizontal,
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.endToStart) {
          HapticFeedback.mediumImpact();
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
        // 右スワイプ: 完了/未完了トグル
        _handleComplete();
        return false;
      },
      onDismissed: (direction) {
        if (direction == DismissDirection.endToStart) {
          widget.onDelete();
        }
      },
      background: _SwipeBackground(
        alignment: Alignment.centerLeft,
        color: widget.task.isCompleted ? Colors.orange : Colors.green,
        icon: widget.task.isCompleted ? Icons.undo : Icons.check,
        label: widget.task.isCompleted ? l10n.swipeUndo : l10n.swipeComplete,
      ),
      secondaryBackground: _SwipeBackground(
        alignment: Alignment.centerRight,
        color: AppColors.priorityUrgent,
        icon: Icons.delete,
        label: l10n.swipeDelete,
      ),
      child: card,
    );
  }

  Widget _buildExpandedContent(
    BuildContext context,
    AppLocalizations l10n,
    String locale,
  ) {
    final outline = Theme.of(context).colorScheme.outline;
    final task = widget.task;
    final children = <Widget>[];

    // 推奨日 (期限と異なる場合)
    if (task.recommendedStart != null && task.recommendedEnd != null) {
      final start = task.recommendedStart!;
      final end = task.recommendedEnd!;
      final fmt = DateFormat.Md(locale);
      final isSameDay = start.year == end.year &&
          start.month == end.month &&
          start.day == end.day;
      final label = isSameDay
          ? l10n.recommendedDateHint(fmt.format(start))
          : l10n.recommendedDateHint('${fmt.format(start)}〜${fmt.format(end)}');
      children.add(Text(
        label,
        style: TextStyle(
          fontSize: 13,
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ));
      children.add(const SizedBox(height: 4));
    }

    // 既存サブ情報 (🔔/📅/AIコメント)
    children.addAll(_buildSubInfo(context, l10n, locale));

    // メモ (最初の2行)
    if (task.memo != null && task.memo!.isNotEmpty) {
      children.add(const SizedBox(height: 4));
      children.add(Text(
        task.memo!,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: 12, color: outline),
      ));
    }

    // 未整理ヒント (AI整理されていないタスク)
    if (task.priority == 0 &&
        (task.aiComment == null || task.aiComment!.isEmpty)) {
      children.add(const SizedBox(height: 6));
      children.add(Text(
        l10n.aiNotOrganizedHint,
        style: TextStyle(
          fontSize: 12,
          fontStyle: FontStyle.italic,
          color: outline,
        ),
      ));
    }

    // 編集ボタン
    children.add(const SizedBox(height: 8));
    children.add(Align(
      alignment: Alignment.centerRight,
      child: OutlinedButton.icon(
        onPressed: widget.onTap,
        icon: const Icon(Icons.edit, size: 16),
        label: Text(l10n.taskCardEdit),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          minimumSize: const Size(0, 32),
        ),
      ),
    ));

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  List<Widget> _buildSubInfo(
    BuildContext context,
    AppLocalizations l10n,
    String locale,
  ) {
    final children = <Widget>[];
    final outline = Theme.of(context).colorScheme.outline;
    final smallStyle = TextStyle(fontSize: 12, color: outline);

    final notifyDates = getScheduledNotificationDates(
      widget.task.dueDate,
      widget.task.notifySettings,
    );
    if (notifyDates.isNotEmpty) {
      final next = notifyDates.first;
      final fmt = DateFormat.Md(locale).add_Hm();
      children.add(const SizedBox(height: 2));
      children.add(Row(
        children: [
          Icon(Icons.notifications_outlined, size: 13, color: outline),
          const SizedBox(width: 3),
          Flexible(
            child: Text(
              fmt.format(next),
              style: smallStyle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ));
    }

    if (widget.task.calendarEventId != null) {
      children.add(const SizedBox(height: 2));
      children.add(Row(
        children: [
          Icon(Icons.calendar_month_outlined, size: 13, color: outline),
          const SizedBox(width: 3),
          Flexible(
            child: Text(
              l10n.calendarAddedBadge,
              style: smallStyle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ));
    }

    final isPremium = ref.watch(isPremiumProvider);
    if (isPremium &&
        widget.task.aiComment != null &&
        widget.task.aiComment!.isNotEmpty) {
      children.add(const SizedBox(height: 4));
      children.add(Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.auto_awesome,
                size: 14,
                color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                widget.task.aiComment!,
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ));
    }

    return children;
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
}

/// スワイプ背景 — アイコンにスケールアニメーション付き
class _SwipeBackground extends StatefulWidget {
  const _SwipeBackground({
    required this.alignment,
    required this.color,
    required this.icon,
    required this.label,
  });

  final Alignment alignment;
  final Color color;
  final IconData icon;
  final String label;

  @override
  State<_SwipeBackground> createState() => _SwipeBackgroundState();
}

class _SwipeBackgroundState extends State<_SwipeBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );
    _scaleController.forward();
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: widget.alignment,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      color: widget.color,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ScaleTransition(
            scale: _scaleAnimation,
            child: Icon(widget.icon, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 8),
          Text(
            widget.label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}
