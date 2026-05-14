import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../models/category.dart' as model;
import '../../models/task.dart';
import '../../theme/yaru_colors.dart';
import '../../theme/yaru_theme.dart';

/// V2TaskCard の表示モード。
/// - active: 通常のタスク (priority色バー + 期日テキスト + ⚡)
/// - archived: 完了済みアーカイブ用 (グレーバー + 完了日 + ✓)
enum V2TaskCardMode { active, archived }

/// 新デザインのタスクカード（テーマ自動切替）。
///
/// ライト: 白カード + 5px 左バー (優先度色) + 控えめな影 + 1px枠線
/// ダーク: ガラス + 3px ネオン左バー (グロー) + ネオンチェックボックス枠
class V2TaskCard extends StatelessWidget {
  const V2TaskCard({
    super.key,
    required this.task,
    required this.onTap,
    required this.onToggleComplete,
    this.category,
    this.expanded = false,
    this.note,
    this.mode = V2TaskCardMode.active,
  });

  final Task task;
  final model.Category? category;
  final VoidCallback onTap;
  final VoidCallback onToggleComplete;

  /// 展開状態（AIアドバイスやメタチップを下に出す）
  final bool expanded;

  /// 展開時に表示するAIアドバイス
  final String? note;

  /// active = 通常、 archived = 完了済みアーカイブ専用 (灰色化 + 完了日表示)
  final V2TaskCardMode mode;

  bool get _isArchivedView => mode == V2TaskCardMode.archived;

  @override
  Widget build(BuildContext context) {
    final yaru = context.yaru;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final done = task.isCompleted;

    // 完了済みのアーカイブ表示では priority色 ではなく落ち着いたグレーに切替。
    // 「達成記録」として未完了タスクと視覚的に区別する。
    final basePriorityColor = YaruColors.getPriorityColor(
      task.priority,
      task.dueDate,
      isDark: isDark,
    );
    final priorityColor = _isArchivedView
        ? yaru.calm.withValues(alpha: 0.55)
        : basePriorityColor;

    final barWidth = isDark ? 3.0 : 5.0;
    // 完了済み (archived OR done) はネオングローも消す (ライト時の影も別途抑制)
    final suppressShadow = _isArchivedView || done;
    final glow = (isDark && !suppressShadow)
        ? [
            BoxShadow(
              color: priorityColor.withValues(alpha: 0.5),
              blurRadius: 12,
            ),
            BoxShadow(
              color: priorityColor.withValues(alpha: 0.3),
              blurRadius: 24,
            ),
          ]
        : const <BoxShadow>[];

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          decoration: BoxDecoration(
            color: yaru.paper,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: yaru.line, width: 1),
            // 完了済み/アーカイブカードは「もう動かない記録」感を出すため影を消す
            boxShadow: suppressShadow ? const [] : yaru.cardShadow,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: IntrinsicHeight(
              child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Priority bar (with neon glow in dark)
                Container(
                  width: barWidth,
                  margin: isDark
                      ? const EdgeInsets.symmetric(vertical: 8)
                      : EdgeInsets.zero,
                  decoration: BoxDecoration(
                    color: priorityColor,
                    borderRadius:
                        isDark ? BorderRadius.circular(999) : null,
                    boxShadow: glow,
                  ),
                ),
                const SizedBox(width: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: _CheckCircle(
                    done: done,
                    color: priorityColor,
                    isDark: isDark,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      onToggleComplete();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(0, 14, 14, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.title,
                          style: TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w700,
                            color: yaru.inkPrimary,
                            decoration: done ? TextDecoration.lineThrough : null,
                          ).copyWith(
                            color: done
                                ? yaru.inkPrimary.withValues(alpha: 0.5)
                                : yaru.inkPrimary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              _isArchivedView
                                  ? Icons.check_circle_rounded
                                  : Icons.bolt_rounded,
                              size: 11,
                              color: priorityColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _formatDateLabel(context, l10n, locale),
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: priorityColor,
                                fontFeatures: const [
                                  FontFeature.tabularFigures()
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (expanded) ...[
                          const SizedBox(height: 12),
                          _MetaChips(
                            task: task,
                            category: category,
                            l10n: l10n,
                            locale: locale,
                          ),
                          if (note != null && note!.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            _AIAdviceCard(note: note!),
                          ],
                        ],
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Icon(
                    expanded ? Icons.expand_less : Icons.chevron_right_rounded,
                    color: yaru.inkQuaternary,
                    size: 18,
                  ),
                ),
              ],
            ),
            ),
          ),
        ),
      ),
    );
  }

  /// archived モードでは「5月7日 完了」、 active モードでは期日。
  /// 完了済みでも active モードのときは取り消し線でアクティブセクションに表示。
  String _formatDateLabel(
      BuildContext context, AppLocalizations l10n, String locale) {
    if (_isArchivedView) {
      final completedAt = task.completedAt ?? task.updatedAt;
      return l10n.taskCompletedOn(DateFormat.MMMd(locale).format(completedAt));
    }
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(task.dueDate.year, task.dueDate.month, task.dueDate.day);
    final diff = due.difference(today).inDays;
    if (diff == 0) return l10n.today;
    if (diff == 1) {
      // 明日表示 (今のところ l10n に "tomorrow" が無いので日付フォーマット)
      return DateFormat.MMMd(locale).format(task.dueDate);
    }
    if (diff < 0) return l10n.overdue;
    return DateFormat.MMMd(locale).format(task.dueDate);
  }
}

class _CheckCircle extends StatelessWidget {
  const _CheckCircle({
    required this.done,
    required this.color,
    required this.isDark,
    required this.onTap,
  });

  final bool done;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final yaru = context.yaru;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: done ? yaru.primaryGradient : null,
          color: done ? null : Colors.transparent,
          border: Border.all(
            color: done ? Colors.transparent : color.withValues(alpha: 0.6),
            width: 2,
          ),
          boxShadow: done && isDark
              ? [
                  BoxShadow(
                    color: yaru.accent.withValues(alpha: 0.6),
                    blurRadius: 12,
                  ),
                ]
              : null,
        ),
        child: done
            ? Icon(
                Icons.check_rounded,
                size: 16,
                color: isDark ? YaruColors.bgDark0 : Colors.white,
              )
            : null,
      ),
    );
  }
}

class _MetaChips extends StatelessWidget {
  const _MetaChips({
    required this.task,
    required this.category,
    required this.l10n,
    required this.locale,
  });

  final Task task;
  final model.Category? category;
  final AppLocalizations l10n;
  final String locale;

  @override
  Widget build(BuildContext context) {
    final yaru = context.yaru;
    final chips = <Widget>[];
    if (category != null) {
      chips.add(_chip(
        context,
        icon: Text(category!.icon, style: const TextStyle(fontSize: 12)),
        label: _categoryName(l10n, category!.name),
      ));
    }
    if (task.recurrenceType != null) {
      chips.add(_chip(
        context,
        icon: Icon(Icons.repeat_rounded, size: 12, color: yaru.inkTertiary),
        label: l10n.recurrence,
      ));
    }
    if (task.estimatedTime != null && task.estimatedTime!.isNotEmpty) {
      chips.add(_chip(
        context,
        icon: Icon(Icons.timer_outlined, size: 12, color: yaru.inkTertiary),
        label: task.estimatedTime!,
      ));
    }
    return Wrap(spacing: 6, runSpacing: 6, children: chips);
  }

  static String _categoryName(AppLocalizations l10n, String key) {
    return switch (key) {
      'categoryPayment' => l10n.categoryPayment,
      'categoryPaperwork' => l10n.categoryPaperwork,
      'categoryShopping' => l10n.categoryShopping,
      'categoryHousehold' => l10n.categoryHousehold,
      'categoryWork' => l10n.categoryWork,
      'categoryOther' => l10n.categoryOther,
      _ => key,
    };
  }

  Widget _chip(BuildContext context,
      {required Widget icon, required String label}) {
    final yaru = context.yaru;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: yaru.useGlassBlur
            ? Colors.white.withValues(alpha: 0.05)
            : yaru.lineStrong.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: yaru.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          icon,
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: yaru.inkSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _AIAdviceCard extends StatelessWidget {
  const _AIAdviceCard({required this.note});
  final String note;

  @override
  Widget build(BuildContext context) {
    final yaru = context.yaru;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            yaru.sparkle.withValues(alpha: 0.08),
            yaru.accent.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: yaru.sparkle.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.auto_awesome, size: 14, color: yaru.sparkle),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI ADVICE',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: yaru.sparkle,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  note,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: yaru.inkPrimary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
