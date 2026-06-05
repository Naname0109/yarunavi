import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/event.dart';
import '../providers/event_provider.dart';

/// #2: カレンダーに予定 (非タスク) を登録する BottomSheet。
/// 最小 MVP: title + date + (任意で時刻 + memo)。 終日トグル付き。
class EventFormSheet extends ConsumerStatefulWidget {
  const EventFormSheet({super.key, this.initialDate, this.editTarget});

  /// 初期日付 (カレンダー画面で選択中の日付を渡す)。
  final DateTime? initialDate;

  /// 編集モード時に渡す既存 Event。
  final Event? editTarget;

  static Future<void> show(
    BuildContext context, {
    DateTime? initialDate,
    Event? editTarget,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: EventFormSheet(
            initialDate: initialDate, editTarget: editTarget),
      ),
    );
  }

  @override
  ConsumerState<EventFormSheet> createState() => _EventFormSheetState();
}

class _EventFormSheetState extends ConsumerState<EventFormSheet> {
  late TextEditingController _titleCtrl;
  late TextEditingController _memoCtrl;
  late DateTime _date;
  bool _isAllDay = true;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  @override
  void initState() {
    super.initState();
    final t = widget.editTarget;
    _titleCtrl = TextEditingController(text: t?.title ?? '');
    _memoCtrl = TextEditingController(text: t?.memo ?? '');
    _date = t?.date ?? widget.initialDate ?? DateTime.now();
    _isAllDay = t?.isAllDay ?? true;
    if (t?.startTime != null) {
      _startTime = _parseTimeOfDay(t!.startTime!);
    }
    if (t?.endTime != null) {
      _endTime = _parseTimeOfDay(t!.endTime!);
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _memoCtrl.dispose();
    super.dispose();
  }

  TimeOfDay? _parseTimeOfDay(String hhmm) {
    final parts = hhmm.split(':');
    if (parts.length != 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    return TimeOfDay(hour: h, minute: m);
  }

  String? _fmtTime(TimeOfDay? t) {
    if (t == null) return null;
    return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(now.year - 1, 1, 1),
      lastDate: DateTime(now.year + 2, 12, 31),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime(bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart
          ? (_startTime ?? const TimeOfDay(hour: 9, minute: 0))
          : (_endTime ?? const TimeOfDay(hour: 10, minute: 0)),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) return;
    final memo = _memoCtrl.text.trim();
    final event = Event(
      id: widget.editTarget?.id,
      title: title,
      date: DateTime(_date.year, _date.month, _date.day),
      isAllDay: _isAllDay,
      startTime: _isAllDay ? null : _fmtTime(_startTime),
      endTime: _isAllDay ? null : _fmtTime(_endTime),
      memo: memo.isEmpty ? null : memo,
      source: widget.editTarget?.source ?? 'manual',
      externalId: widget.editTarget?.externalId,
      createdAt: widget.editTarget?.createdAt ?? DateTime.now(),
    );
    final notifier = ref.read(eventsProvider.notifier);
    if (widget.editTarget == null) {
      await notifier.add(event);
    } else {
      await notifier.updateEvent(event);
    }
    if (!mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.eventSaved)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final isFromSync = widget.editTarget?.source == 'calendar_sync';

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              widget.editTarget == null ? l10n.eventAdd : l10n.eventEdit,
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w800),
            ),
            if (isFromSync) ...[
              const SizedBox(height: 4),
              Text(l10n.eventReadOnlyNote,
                  style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).hintColor)),
            ],
            const SizedBox(height: 12),
            TextField(
              controller: _titleCtrl,
              enabled: !isFromSync,
              decoration: InputDecoration(
                labelText: l10n.eventTitleLabel,
                border: const OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today),
              title: Text(l10n.eventDateLabel),
              subtitle: Text(DateFormat.yMMMEd(locale).format(_date)),
              onTap: isFromSync ? null : _pickDate,
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.eventAllDayLabel),
              value: _isAllDay,
              onChanged: isFromSync
                  ? null
                  : (v) => setState(() => _isAllDay = v),
            ),
            if (!_isAllDay) ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.schedule, size: 16),
                      onPressed: isFromSync ? null : () => _pickTime(true),
                      label: Text(_startTime == null
                          ? l10n.eventStartTime
                          : _fmtTime(_startTime)!),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.schedule, size: 16),
                      onPressed: isFromSync ? null : () => _pickTime(false),
                      label: Text(_endTime == null
                          ? l10n.eventEndTime
                          : _fmtTime(_endTime)!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
            TextField(
              controller: _memoCtrl,
              enabled: !isFromSync,
              decoration: InputDecoration(
                labelText: l10n.eventMemoLabel,
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: isFromSync ? null : _save,
              child: Text(l10n.save),
            ),
            // #1: 編集モード時のみ「この予定を削除」ボタン (控えめ)。
            // ライト/ダーク両対応のため colorScheme.error を使用。
            // カレンダー同期予定は「同期元には影響しません」を明示。
            if (widget.editTarget != null) ...[
              const SizedBox(height: 6),
              Builder(builder: (ctx) {
                final err = Theme.of(ctx).colorScheme.error;
                return TextButton.icon(
                  onPressed: _confirmDelete,
                  icon: Icon(Icons.delete_outline,
                      size: 18, color: err.withValues(alpha: 0.85)),
                  label: Text(
                    isFromSync
                        ? l10n.eventDeleteThisSync
                        : l10n.eventDeleteThis,
                    style: TextStyle(
                      color: err.withValues(alpha: 0.85),
                      fontSize: 13,
                    ),
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  /// #1: 予定削除の確認 → DB 削除 → BottomSheet 閉じ + SnackBar。
  Future<void> _confirmDelete() async {
    final l10n = AppLocalizations.of(context)!;
    final target = widget.editTarget;
    if (target?.id == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.eventDeleteConfirmTitle),
        content: Text(l10n.eventDeleteConfirmMessage),
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
    // 親 State の mounted を確認後に messenger / navigator を取り出し、
    // await 後でも安全に使う (task_detail_screen と統一)
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    await ref.read(eventsProvider.notifier).delete(target!.id!);
    if (!mounted) return;
    navigator.pop();
    messenger.showSnackBar(
      SnackBar(content: Text(l10n.eventDeletedSnack)),
    );
  }
}
