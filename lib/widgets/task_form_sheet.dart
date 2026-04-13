import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/task.dart';
import '../models/category.dart' as model;
import '../providers/category_provider.dart';
import '../providers/purchase_provider.dart';
import '../providers/task_provider.dart';
import '../services/calendar_service.dart';
import '../utils/category_helper.dart';
import '../utils/notification_utils.dart';

class TaskFormSheet extends ConsumerStatefulWidget {
  const TaskFormSheet({super.key, this.task});

  final Task? task;

  /// ボトムシートを表示する
  static Future<void> show(BuildContext context, {Task? task}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      constraints: const BoxConstraints(maxWidth: 700),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => TaskFormSheet(task: task),
    );
  }

  @override
  ConsumerState<TaskFormSheet> createState() => _TaskFormSheetState();
}

class _TaskFormSheetState extends ConsumerState<TaskFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _memoController;
  late DateTime _dueDate;
  int? _categoryId;
  String? _estimatedTime;
  int _importance = 1;
  String? _recurrenceType;
  int? _recurrenceValue;
  bool _notifyAiAuto = true;
  List<String> _notifySettings = [];
  bool _addToCalendar = false;
  bool _isSaving = false;
  bool _showAdvanced = false;

  bool get _isEditing => widget.task != null;

  @override
  void initState() {
    super.initState();
    final task = widget.task;
    _titleController = TextEditingController(text: task?.title ?? '');
    _memoController = TextEditingController(text: task?.memo ?? '');
    _dueDate = task?.dueDate ?? DateTime.now().add(const Duration(days: 7));
    _categoryId = task?.categoryId;
    _estimatedTime = task?.estimatedTime;
    _importance = task?.importance ?? 1;
    _recurrenceType = task?.recurrenceType;
    _recurrenceValue = task?.recurrenceValue;
    _addToCalendar = task?.calendarEventId != null;

    // 編集時: 詳細フィールドのいずれかが設定済みなら自動展開
    if (_isEditing) {
      _showAdvanced = (task?.memo != null && task!.memo!.isNotEmpty) ||
          task?.categoryId != null ||
          task?.estimatedTime != null ||
          task?.importance != 1 ||
          task?.recurrenceType != null ||
          (task?.notifySettings != null &&
              task!.notifySettings != '["ai_auto"]') ||
          task?.calendarEventId != null;
    }

    if (task?.notifySettings != null) {
      try {
        final decoded = List<String>.from(
          jsonDecode(task!.notifySettings!) as List,
        );
        if (decoded.length == 1 && decoded.first == 'ai_auto') {
          _notifyAiAuto = true;
          _notifySettings = [];
        } else {
          _notifyAiAuto = false;
          _notifySettings = decoded;
        }
      } catch (_) {
        _notifyAiAuto = true;
        _notifySettings = [];
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final categoriesAsync = ref.watch(categoriesProvider);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return Form(
            key: _formKey,
            child: Column(
              children: [
                _buildHeader(l10n),
                const Divider(height: 1),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(16),
                    children: [
                      // メイン入力: タスク名 + 期限日のみ
                      _buildTitleField(l10n),
                      const SizedBox(height: 16),
                      _buildDueDateField(l10n, locale),
                      const SizedBox(height: 16),
                      // 詳細設定の展開トグル
                      _buildAdvancedToggle(l10n),
                      // 詳細設定（折りたたみ）
                      AnimatedCrossFade(
                        duration: const Duration(milliseconds: 200),
                        crossFadeState: _showAdvanced
                            ? CrossFadeState.showSecond
                            : CrossFadeState.showFirst,
                        firstChild: const SizedBox(width: double.infinity),
                        secondChild: Column(
                          children: [
                            const SizedBox(height: 16),
                            _buildMemoField(l10n),
                            const SizedBox(height: 16),
                            _buildCategoryField(l10n, categoriesAsync),
                            const SizedBox(height: 16),
                            _buildEstimatedTimeField(l10n),
                            const SizedBox(height: 16),
                            _buildImportanceField(l10n),
                            const SizedBox(height: 16),
                            _buildRecurrenceField(l10n),
                            const SizedBox(height: 16),
                            _buildNotifyField(l10n),
                            const SizedBox(height: 16),
                            _buildCalendarToggle(l10n),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.outline.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l10n.cancel),
              ),
              Text(
                _isEditing ? l10n.editTask : l10n.addTask,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: _isSaving ? null : _onSave,
                child: Text(l10n.save),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTitleField(AppLocalizations l10n) {
    return TextFormField(
      controller: _titleController,
      decoration: InputDecoration(
        labelText: l10n.taskName,
        hintText: l10n.taskName,
      ),
      autofocus: !_isEditing,
      textInputAction: TextInputAction.next,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return l10n.taskNameRequired;
        }
        return null;
      },
    );
  }

  Widget _buildDueDateField(AppLocalizations l10n, String locale) {
    final dateStr = DateFormat.yMMMd(locale).format(_dueDate);

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.calendar_today),
      title: Text(l10n.dueDate),
      subtitle: Text(dateStr),
      trailing: const Icon(Icons.chevron_right),
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: _dueDate,
          firstDate: DateTime(2020),
          lastDate: DateTime(2100),
        );
        if (picked != null) {
          setState(() => _dueDate = picked);
        }
      },
    );
  }

  Widget _buildAdvancedToggle(AppLocalizations l10n) {
    return GestureDetector(
      onTap: () => setState(() => _showAdvanced = !_showAdvanced),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              l10n.advancedSettings,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 4),
            AnimatedRotation(
              turns: _showAdvanced ? 0.5 : 0,
              duration: const Duration(milliseconds: 200),
              child: Icon(
                Icons.expand_more,
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMemoField(AppLocalizations l10n) {
    return TextFormField(
      controller: _memoController,
      minLines: 2,
      maxLines: 3,
      decoration: InputDecoration(
        labelText: l10n.memo,
        hintText: l10n.memoHint,
        hintMaxLines: 3,
        prefixIcon: const Icon(Icons.note),
      ),
    );
  }

  Widget _buildCategoryField(
    AppLocalizations l10n,
    AsyncValue<List<model.Category>> categoriesAsync,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.label_outline, size: 24),
            const SizedBox(width: 16),
            Text(l10n.category, style: const TextStyle(fontSize: 16)),
          ],
        ),
        const SizedBox(height: 8),
        categoriesAsync.when(
          loading: () => const SizedBox.shrink(),
          error: (_, _) => const SizedBox.shrink(),
          data: (categories) => Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              ChoiceChip(
                label: Text(l10n.noCategory),
                selected: _categoryId == null,
                onSelected: (_) => setState(() => _categoryId = null),
              ),
              ...categories.map(
                (cat) => ChoiceChip(
                  label: Text(
                    '${cat.icon} ${getCategoryDisplayName(cat.name, l10n)}',
                  ),
                  selected: _categoryId == cat.id,
                  onSelected: (_) => setState(() => _categoryId = cat.id),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEstimatedTimeField(AppLocalizations l10n) {
    final options = <(String?, String)>[
      (null, l10n.estimatedTimeNone),
      ('15min', l10n.estimatedTime15min),
      ('30min', l10n.estimatedTime30min),
      ('1hour', l10n.estimatedTime1hour),
      ('1_5hour', l10n.estimatedTime1_5hour),
      ('2hour', l10n.estimatedTime2hour),
      ('3hour', l10n.estimatedTime3hour),
      ('4hour', l10n.estimatedTime4hour),
      ('half_day', l10n.estimatedTimeHalfDay),
      ('1day', l10n.estimatedTime1day),
      ('several_days', l10n.estimatedTimeSeveralDays),
      ('1week_plus', l10n.estimatedTime1weekPlus),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.timer_outlined, size: 24),
            const SizedBox(width: 16),
            Text(l10n.estimatedTime, style: const TextStyle(fontSize: 16)),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: options.map((o) {
            final (value, label) = o;
            return ChoiceChip(
              label: Text(label),
              selected: _estimatedTime == value,
              onSelected: (_) => setState(() => _estimatedTime = value),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildImportanceField(AppLocalizations l10n) {
    final options = <(int, String, IconData, Color?)>[
      (0, l10n.importanceLow, Icons.arrow_downward, Colors.grey),
      (
        1,
        l10n.importanceMedium,
        Icons.remove,
        Theme.of(context).colorScheme.primary,
      ),
      (
        2,
        l10n.importanceHigh,
        Icons.arrow_upward,
        Theme.of(context).colorScheme.error,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.flag_outlined, size: 24),
            const SizedBox(width: 16),
            Text(l10n.importance, style: const TextStyle(fontSize: 16)),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: options.map((o) {
            final (value, label, icon, color) = o;
            return ChoiceChip(
              showCheckmark: false,
              avatar: Icon(
                icon,
                size: 18,
                color: _importance == value ? null : color,
              ),
              label: Text(label),
              selected: _importance == value,
              onSelected: (_) => setState(() => _importance = value),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildRecurrenceField(AppLocalizations l10n) {
    final options = <(String?, String)>[
      (null, l10n.recurrenceNone),
      ('weekly', l10n.recurrenceWeekly),
      ('monthly', l10n.recurrenceMonthly),
      ('yearly', l10n.recurrenceYearly),
      ('custom', l10n.recurrenceCustom),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String?>(
          key: ValueKey('recurrence_$_recurrenceType'),
          value: _recurrenceType,
          decoration: InputDecoration(
            labelText: l10n.recurrence,
            prefixIcon: const Icon(Icons.repeat),
          ),
          items: options
              .map((o) => DropdownMenuItem(value: o.$1, child: Text(o.$2)))
              .toList(),
          onChanged: (value) {
            setState(() {
              _recurrenceType = value;
              _recurrenceValue = null;
            });
          },
        ),
        if (_recurrenceType != null) ...[
          const SizedBox(height: 12),
          _buildRecurrenceSubField(l10n),
        ],
      ],
    );
  }

  Widget _buildRecurrenceSubField(AppLocalizations l10n) {
    switch (_recurrenceType) {
      case 'weekly':
        return _buildWeekdaySelector();
      case 'monthly':
        return _buildDayOfMonthSelector();
      case 'yearly':
        return _buildMonthDaySelector(l10n);
      case 'custom':
        return _buildCustomIntervalField(l10n);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildWeekdaySelector() {
    final locale = Localizations.localeOf(context).languageCode;
    final dayNames = List.generate(7, (i) {
      final date = DateTime(2024, 1, 1 + i);
      return DateFormat.E(locale).format(date);
    });

    return Wrap(
      spacing: 8,
      children: List.generate(7, (i) {
        final weekday = i + 1;
        return ChoiceChip(
          label: Text(dayNames[i]),
          selected: _recurrenceValue == weekday,
          onSelected: (_) => setState(() => _recurrenceValue = weekday),
        );
      }),
    );
  }

  Widget _buildDayOfMonthSelector() {
    return DropdownButtonFormField<int>(
      key: ValueKey('monthly_$_recurrenceValue'),
      value: _recurrenceValue,
      items: List.generate(31, (i) {
        final day = i + 1;
        return DropdownMenuItem(value: day, child: Text('$day'));
      }),
      onChanged: (value) => setState(() => _recurrenceValue = value),
      decoration: const InputDecoration(prefixIcon: Icon(Icons.calendar_month)),
    );
  }

  Widget _buildMonthDaySelector(AppLocalizations l10n) {
    final currentMonth = _recurrenceValue != null
        ? _recurrenceValue! ~/ 100
        : 0;
    final currentDay = _recurrenceValue != null ? _recurrenceValue! % 100 : 0;

    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<int>(
            key: ValueKey('yearly_month_$currentMonth'),
            value: currentMonth > 0 && currentMonth <= 12 ? currentMonth : null,
            items: List.generate(12, (i) {
              final month = i + 1;
              final locale = Localizations.localeOf(context).languageCode;
              final name = DateFormat.MMM(locale).format(DateTime(2024, month));
              return DropdownMenuItem(value: month, child: Text(name));
            }),
            onChanged: (month) {
              if (month != null) {
                setState(() {
                  _recurrenceValue =
                      month * 100 + (currentDay > 0 ? currentDay : 1);
                });
              }
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: DropdownButtonFormField<int>(
            key: ValueKey('yearly_day_$currentDay'),
            value: currentDay > 0 && currentDay <= 31 ? currentDay : null,
            items: List.generate(31, (i) {
              final day = i + 1;
              return DropdownMenuItem(value: day, child: Text('$day'));
            }),
            onChanged: (day) {
              if (day != null) {
                setState(() {
                  _recurrenceValue =
                      (currentMonth > 0 ? currentMonth : 1) * 100 + day;
                });
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCustomIntervalField(AppLocalizations l10n) {
    return TextFormField(
      initialValue: _recurrenceValue?.toString(),
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: l10n.recurrenceInterval,
        prefixIcon: const Icon(Icons.timelapse),
      ),
      onChanged: (value) {
        final parsed = int.tryParse(value);
        if (parsed != null && parsed > 0) {
          setState(() => _recurrenceValue = parsed);
        }
      },
    );
  }

  Widget _buildNotifyField(AppLocalizations l10n) {
    final isPremium = ref.watch(isPremiumProvider);
    final theme = Theme.of(context);

    final inner = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.notifications_outlined, size: 24),
            const SizedBox(width: 16),
            Text(l10n.notifySettings, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            if (!isPremium)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  l10n.proBadge,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        SegmentedButton<bool>(
          segments: [
            ButtonSegment(value: true, label: Text(l10n.notifyAiAuto)),
            ButtonSegment(value: false, label: Text(l10n.notifyManual)),
          ],
          selected: {_notifyAiAuto},
          onSelectionChanged: (set) {
            setState(() => _notifyAiAuto = set.first);
          },
        ),
        if (!_notifyAiAuto) ...[
          const SizedBox(height: 8),
          _buildManualNotifyChips(l10n),
        ],
        const SizedBox(height: 8),
        _buildNotifyPreview(l10n),
      ],
    );

    if (isPremium) return inner;

    // 無料: ロックして案内 (calendar toggle と同じボトムシート)
    return GestureDetector(
      onTap: () => _showPremiumGate(l10n),
      child: AbsorbPointer(child: Opacity(opacity: 0.6, child: inner)),
    );
  }

  Widget _buildNotifyPreview(AppLocalizations l10n) {
    final outline = Theme.of(context).colorScheme.outline;
    final style = TextStyle(fontSize: 12, color: outline);
    final locale = Localizations.localeOf(context).languageCode;

    if (_notifyAiAuto) {
      return Row(
        children: [
          Icon(Icons.auto_awesome, size: 13, color: outline),
          const SizedBox(width: 4),
          Expanded(child: Text(l10n.aiAutoNotifyHint, style: style)),
        ],
      );
    }

    final json = _notifySettings.isEmpty ? null : jsonEncode(_notifySettings);
    final dates = getScheduledNotificationDates(_dueDate, json);
    if (dates.isEmpty) return const SizedBox.shrink();
    final fmt = DateFormat.Md(locale).add_Hm();
    final formatted = dates.map(fmt.format).join(', ');
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.notifications_outlined, size: 13, color: outline),
        const SizedBox(width: 4),
        Expanded(
          child: Text('${l10n.notifyScheduledLabel}: $formatted', style: style),
        ),
      ],
    );
  }

  Widget _buildManualNotifyChips(AppLocalizations l10n) {
    final options = <(String, String)>[
      ('on_due', l10n.notifyOnDue),
      ('1_day_before', l10n.notifyOneDayBefore),
      ('3_days_before', l10n.notifyThreeDaysBefore),
      ('1_week_before', l10n.notifyOneWeekBefore),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: options.map((o) {
        final (key, label) = o;
        final isSelected = _notifySettings.contains(key);
        return FilterChip(
          label: Text(label),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              if (selected) {
                _notifySettings.add(key);
              } else {
                _notifySettings.remove(key);
              }
            });
          },
        );
      }).toList(),
    );
  }

  Widget _buildCalendarToggle(AppLocalizations l10n) {
    final isPremium = ref.watch(isPremiumProvider);

    final tile = SwitchListTile(
      contentPadding: EdgeInsets.zero,
      secondary: const Icon(Icons.calendar_month),
      title: Row(
        children: [
          Expanded(child: Text(l10n.addToCalendar)),
          if (!isPremium) _proBadge(l10n),
        ],
      ),
      value: isPremium && _addToCalendar,
      onChanged: isPremium
          ? (value) => setState(() => _addToCalendar = value)
          : null,
    );

    if (isPremium) return tile;

    return GestureDetector(
      onTap: () => _showPremiumGate(l10n),
      child: AbsorbPointer(
        child: Opacity(opacity: 0.6, child: tile),
      ),
    );
  }

  Widget _proBadge(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        l10n.proBadge,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Future<void> _showPremiumGate(AppLocalizations l10n) async {
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

  Future<void> _onSave() async {
    if (!_formKey.currentState!.validate()) return;

    final l10n = AppLocalizations.of(context)!;
    setState(() => _isSaving = true);

    try {
      final now = DateTime.now();
      final memo = _memoController.text.trim().isEmpty
          ? null
          : _memoController.text.trim();

      // 通知設定のシリアライズ
      String? notifyJson;
      if (_notifyAiAuto) {
        notifyJson = jsonEncode(['ai_auto']);
      } else if (_notifySettings.isNotEmpty) {
        notifyJson = jsonEncode(_notifySettings);
      }

      CalendarResult? calResult;

      if (_isEditing) {
        final original = widget.task!;
        final updated = Task(
          id: original.id,
          title: _titleController.text.trim(),
          dueDate: _dueDate,
          memo: memo,
          categoryId: _categoryId,
          isCompleted: original.isCompleted,
          completedAt: original.completedAt,
          priority: original.priority,
          aiComment: original.aiComment,
          recurrenceType: _recurrenceType,
          recurrenceValue: _recurrenceValue,
          recurrenceParentId: original.recurrenceParentId,
          notifySettings: notifyJson,
          calendarEventId: original.calendarEventId,
          estimatedTime: _estimatedTime,
          importance: _importance,
          createdAt: original.createdAt,
          updatedAt: now,
        );
        calResult = await ref
            .read(tasksProvider.notifier)
            .updateTask(updated, addToCalendar: _addToCalendar);
      } else {
        final task = Task(
          title: _titleController.text.trim(),
          dueDate: _dueDate,
          memo: memo,
          categoryId: _categoryId,
          recurrenceType: _recurrenceType,
          recurrenceValue: _recurrenceValue,
          notifySettings: notifyJson,
          estimatedTime: _estimatedTime,
          importance: _importance,
          createdAt: now,
          updatedAt: now,
        );
        calResult = await ref
            .read(tasksProvider.notifier)
            .addTask(task, addToCalendar: _addToCalendar);
      }

      if (mounted) {
        if (calResult == CalendarResult.permissionDenied) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.calendarPermissionDenied)),
          );
        } else if (calResult == CalendarResult.failed) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l10n.calendarAddFailed)));
        }
        Navigator.of(context).pop();
      }
    } catch (e) {
      debugPrint('Task save error: $e');
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}
