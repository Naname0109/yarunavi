import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/generated/app_localizations.dart';
import '../providers/purchase_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/task_provider.dart';
import '../utils/constants.dart';
import '../widgets/banner_ad_widget.dart';
import '../widgets/coach_overlay.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/responsive_wrapper.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  int _versionTapCount = 0;
  // #1 VIP コード: 10 連続タップで入力フィールド出現 (カウント表示しない)
  bool _showVipField = false;
  final _vipShakeKey = GlobalKey<_ShakeWrapperState>();
  final _vipController = TextEditingController();

  @override
  void dispose() {
    _vipController.dispose();
    super.dispose();
  }

  void _onVersionTap() {
    _versionTapCount++;
    // #1 VIP コード: 10 タップで無言で field 表示。1-9 では何もしない。
    if (_versionTapCount == 10) {
      setState(() => _showVipField = true);
    }
  }

  Future<void> _submitVipCode() async {
    final code = _vipController.text.trim();
    if (code.isEmpty) {
      _vipShakeKey.currentState?.shake();
      return;
    }
    final vip = ref.read(vipServiceProvider);
    final ok = await vip.redeemCode(code);
    if (!mounted) return;
    if (ok) {
      ref.read(isVipProvider.notifier).state = true;
      ref.read(isPremiumProvider.notifier).refresh();
      setState(() {
        _showVipField = false;
        _vipController.clear();
        _versionTapCount = 0;
      });
    } else {
      _vipShakeKey.currentState?.shake();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isPremium = ref.watch(isPremiumProvider);
    final currentLocale = ref.watch(localeProvider);
    final currentTheme = ref.watch(themeModeProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settings),
      ),
      body: ResponsiveWrapper(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                children: [
                  // --- アカウント ---
                  _buildSectionHeader(context, l10n.settingsAccount),
                  ListTile(
                    leading: Icon(
                      isPremium ? Icons.star : Icons.star_border,
                      color: isPremium ? Colors.amber : null,
                    ),
                    title: Text(l10n.settingsPremiumStatus),
                    subtitle: Text(
                      isPremium
                          ? l10n.settingsPremiumActive
                          : l10n.settingsFreeUser,
                    ),
                  ),
                  if (!isPremium)
                    ListTile(
                      key: const Key('upgrade_to_premium'),
                      leading: const Icon(Icons.workspace_premium),
                      title: Text(l10n.settingsUpgradeToPremium),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push('/store'),
                    ),
                  const Divider(),

                  // --- AI整理 ---
                  _buildSectionHeader(context, l10n.settingsAiSection),
                  ListTile(
                    leading: const Icon(Icons.history),
                    title: Text(l10n.aiHistory),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/ai-history'),
                  ),
                  const _ExecutionTimingSlider(),
                  const Divider(),

                  // --- カテゴリ ---
                  ListTile(
                    leading: const Icon(Icons.label_outline),
                    title: Text(l10n.categoryManageTitle),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/category-manage'),
                  ),
                  const Divider(),

                  // --- 通知 ---
                  _buildSectionHeader(context, l10n.notification),
                  ListTile(
                    leading: const Icon(Icons.notifications_outlined),
                    title: Text(l10n.settingsDefaultNotify),
                    subtitle: Text(
                      isPremium
                          ? l10n.notifyOneDayBefore
                          : l10n.premiumOnly,
                    ),
                    enabled: isPremium,
                  ),
                  // #4: 通知タイミング (実行日 / 期限日 / 期限超過 + 時刻)
                  const _NotifyTimingTile(),
                  // サウンドのON/OFF
                  Consumer(
                    builder: (context, ref, _) {
                      final enabled = ref.watch(soundEnabledProvider);
                      return SwitchListTile(
                        secondary: const Icon(Icons.volume_up_outlined),
                        title: Text(l10n.settingsSound),
                        subtitle: Text(l10n.settingsSoundDesc),
                        value: enabled,
                        onChanged: (v) => ref
                            .read(soundEnabledProvider.notifier)
                            .setEnabled(v),
                      );
                    },
                  ),
                  const Divider(),

                  // --- 言語 ---
                  _buildSectionHeader(context, l10n.settingsLanguage),
                  RadioListTile<String>(
                    title: Text(l10n.settingsJapanese),
                    value: 'ja',
                    groupValue: currentLocale.languageCode,
                    onChanged: (value) {
                      ref
                          .read(localeProvider.notifier)
                          .setLocale(const Locale('ja'));
                    },
                  ),
                  RadioListTile<String>(
                    title: Text(l10n.settingsEnglish),
                    value: 'en',
                    groupValue: currentLocale.languageCode,
                    onChanged: (value) {
                      ref
                          .read(localeProvider.notifier)
                          .setLocale(const Locale('en'));
                    },
                  ),
                  const Divider(),

                  // --- 表示 (テーマ + 週の開始曜日) ---
                  _buildSectionHeader(context, l10n.settingsTheme),
                  ListTile(
                    leading: const Icon(Icons.brightness_6_outlined),
                    title: Text(l10n.displayMode),
                    trailing: DropdownButton<ThemeMode>(
                      value: currentTheme,
                      underline: const SizedBox.shrink(),
                      items: [
                        DropdownMenuItem(
                          value: ThemeMode.system,
                          child: Text(l10n.themeModeAuto),
                        ),
                        DropdownMenuItem(
                          value: ThemeMode.light,
                          child: Text(l10n.themeModeLight),
                        ),
                        DropdownMenuItem(
                          value: ThemeMode.dark,
                          child: Text(l10n.themeModeDark),
                        ),
                      ],
                      onChanged: (mode) {
                        if (mode == null) return;
                        ref
                            .read(themeModeProvider.notifier)
                            .setThemeMode(mode);
                      },
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.view_week_outlined),
                    title: Text(l10n.weekStartDay),
                    trailing: DropdownButton<int>(
                      value: ref.watch(startOfWeekProvider),
                      underline: const SizedBox.shrink(),
                      items: [
                        DropdownMenuItem(
                          value: 1,
                          child: Text(l10n.weekStartMonday),
                        ),
                        DropdownMenuItem(
                          value: 7,
                          child: Text(l10n.weekStartSunday),
                        ),
                        DropdownMenuItem(
                          value: 6,
                          child: Text(l10n.weekStartSaturday),
                        ),
                      ],
                      onChanged: (day) {
                        if (day == null) return;
                        ref.read(startOfWeekProvider.notifier).setDay(day);
                      },
                    ),
                  ),
                  const Divider(),

                  // --- タスクのスケジュール (#3) ---
                  _buildSectionHeader(context, l10n.scheduleSection),
                  _WeekdayBusynessTile(),
                  _BlockedDatesTile(),
                  _AvoidEventDaysToggle(),
                  _AiReminderToggle(),
                  const Divider(),

                  // --- データ管理 ---
                  _buildSectionHeader(context, l10n.dataManagement),
                  ListTile(
                    leading: const Icon(Icons.file_download_outlined),
                    title: Text(l10n.settingsExportCsv),
                    onTap: () => _exportCsv(context, ref, l10n),
                  ),
                  ListTile(
                    leading: const Icon(Icons.help_outline),
                    title: Text(l10n.settingsReplayOnboarding),
                    onTap: () async {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setBool('is_onboarding_completed', false);
                      await resetCoachMarksFlag();
                      if (context.mounted) {
                        context.go('/onboarding');
                      }
                    },
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.delete_forever,
                      color: theme.colorScheme.error,
                    ),
                    title: Text(
                      l10n.settingsDeleteAllData,
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                    onTap: () => _showDeleteAllDialog(context, ref, l10n),
                  ),
                  const Divider(),

                  // --- リンク ---
                  ListTile(
                    leading: const Icon(Icons.description_outlined),
                    title: Text(l10n.termsOfUse),
                    trailing: const Icon(Icons.open_in_new, size: 18),
                    onTap: () => launchUrl(
                      Uri.parse(AppConstants.termsOfUseUrl),
                      mode: LaunchMode.externalApplication,
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.privacy_tip_outlined),
                    title: Text(l10n.privacyPolicy),
                    trailing: const Icon(Icons.open_in_new, size: 18),
                    onTap: () => launchUrl(
                      Uri.parse(AppConstants.privacyPolicyUrl),
                      mode: LaunchMode.externalApplication,
                    ),
                  ),
                  const Divider(),

                  // --- アプリ情報（10 回タップで無言で VIP コード入力欄出現 #1） ---
                  Consumer(
                    builder: (context, ref, _) {
                      final vipActive = ref.watch(isVipProvider);
                      return ListTile(
                        key: const Key('app_info_tile'),
                        leading: const Icon(Icons.info_outline),
                        title: Row(
                          children: [
                            Text(l10n.appInfo),
                            if (vipActive) ...[
                              const SizedBox(width: 6),
                              Icon(Icons.star_rounded,
                                  size: 14,
                                  color: Theme.of(context).colorScheme.primary),
                            ],
                          ],
                        ),
                        subtitle: FutureBuilder<PackageInfo>(
                          future: PackageInfo.fromPlatform(),
                          builder: (context, snapshot) {
                            if (snapshot.hasData) {
                              return Text(
                                '${l10n.settingsVersion} ${snapshot.data!.version}'
                                ' (${snapshot.data!.buildNumber})',
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                        onTap: _onVersionTap,
                      );
                    },
                  ),
                  if (_showVipField)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      child: _ShakeWrapper(
                        key: _vipShakeKey,
                        child: TextField(
                          controller: _vipController,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          textInputAction: TextInputAction.go,
                          onSubmitted: (_) => _submitVipCode(),
                        ),
                      ),
                    ),
                  ListTile(
                    leading: const Icon(Icons.article_outlined),
                    title: Text(l10n.settingsLicenses),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => showLicensePage(
                      context: context,
                      applicationName: AppConstants.appName,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
            const BannerAdWidget(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  Future<void> _exportCsv(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) async {
    try {
      final db = ref.read(databaseServiceProvider);
      final tasks = await db.getAllTasks();

      final buffer = StringBuffer();
      buffer.write('\uFEFF');
      buffer.writeln('id,title,due_date,memo,category_id,is_completed,'
          'completed_at,priority,ai_comment,recurrence_type,'
          'recurrence_value,created_at,updated_at');

      for (final task in tasks) {
        buffer.writeln(
          '${task.id},'
          '"${_escapeCsv(task.title)}",'
          '${DateFormat('yyyy-MM-dd').format(task.dueDate)},'
          '"${_escapeCsv(task.memo ?? '')}",'
          '${task.categoryId ?? ''},'
          '${task.isCompleted ? 1 : 0},'
          '${task.completedAt?.toIso8601String() ?? ''},'
          '${task.priority},'
          '"${_escapeCsv(task.aiComment ?? '')}",'
          '${task.recurrenceType ?? ''},'
          '${task.recurrenceValue ?? ''},'
          '${task.createdAt.toIso8601String()},'
          '${task.updatedAt.toIso8601String()}',
        );
      }

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/yarunavi_tasks.csv');
      await file.writeAsString(buffer.toString());

      await Share.shareXFiles([XFile(file.path)]);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.settingsExportSuccess)),
        );
      }
    } catch (e) {
      debugPrint('CSV export error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.settingsExportFailed)),
        );
      }
    }
  }

  String _escapeCsv(String value) {
    return value.replaceAll('"', '""').replaceAll('\n', ' ');
  }


  Future<void> _showDeleteAllDialog(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.settingsDeleteAllConfirmTitle),
        content: Text(l10n.settingsDeleteAllConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final db = ref.read(databaseServiceProvider);
      await db.deleteAllData();
      ref.invalidate(tasksProvider);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.settingsDeleteAllSuccess)),
        );
      }
    }
  }
}

/// 実行日タイミングスライダー
class _ExecutionTimingSlider extends ConsumerWidget {
  const _ExecutionTimingSlider();

  String _getDescription(double factor, AppLocalizations l10n) {
    if (factor <= 0.2) return l10n.executionTimingDesc0;
    if (factor <= 0.4) return l10n.executionTimingDesc1;
    if (factor <= 0.5) return l10n.executionTimingDesc2;
    if (factor <= 0.7) return l10n.executionTimingDesc3;
    return l10n.executionTimingDesc4;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final factor = ref.watch(executionTimingProvider);
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.tune, size: 20, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: 12),
              Text(l10n.executionTimingLabel, style: const TextStyle(fontSize: 16)),
            ],
          ),
          const SizedBox(height: 4),
          // スライダーの目的を1行で説明 (B-4 改善)
          Padding(
            padding: const EdgeInsets.only(left: 32, right: 4, top: 2, bottom: 6),
            child: Text(
              l10n.executionTimingHint,
              style: TextStyle(
                fontSize: 11.5,
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.45,
              ),
            ),
          ),
          Center(
            child: Text(
              _getDescription(factor, l10n),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          Row(
            children: [
              Text(l10n.executionTimingDeadline,
                  style: TextStyle(fontSize: 11, color: theme.colorScheme.outline)),
              Expanded(
                child: Slider(
                  value: factor,
                  min: 0.0,
                  max: 1.0,
                  divisions: 10,
                  onChanged: (v) {
                    ref.read(executionTimingProvider.notifier).setFactor(v);
                  },
                ),
              ),
              Text(l10n.executionTimingEarly,
                  style: TextStyle(fontSize: 11, color: theme.colorScheme.outline)),
            ],
          ),
        ],
      ),
    );
  }
}

/// #3-1: 曜日ごとの忙しさ (1=暇〜5=多忙)。 Slider × 7 曜日。
class _WeekdayBusynessTile extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final asyncValue = ref.watch(weekdayBusynessProvider);
    final values = asyncValue.valueOrNull ?? defaultWeekdayBusyness;
    final weekdayLabels = [
      l10n.weekdayMonShort,
      l10n.weekdayTueShort,
      l10n.weekdayWedShort,
      l10n.weekdayThuShort,
      l10n.weekdayFriShort,
      l10n.weekdaySatShort,
      l10n.weekdaySunShort,
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 4),
            child: Text(
              l10n.scheduleBusynessLabel,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
          ),
          for (var i = 0; i < 7; i++)
            Row(
              children: [
                SizedBox(
                  width: 36,
                  child: Text(weekdayLabels[i],
                      style:
                          const TextStyle(fontWeight: FontWeight.w700)),
                ),
                Expanded(
                  child: Slider(
                    value: values[i].toDouble(),
                    min: 1,
                    max: 5,
                    divisions: 4,
                    label: '${values[i]}',
                    onChanged: (v) {
                      ref
                          .read(weekdayBusynessProvider.notifier)
                          .setBusyness(i, v.round());
                    },
                  ),
                ),
                SizedBox(
                  width: 24,
                  child: Text('${values[i]}',
                      textAlign: TextAlign.end,
                      style:
                          const TextStyle(fontWeight: FontWeight.w700)),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

/// #3-2 / #1: タスク実行不可日 (カレンダーグリッド一括選択)。
class _BlockedDatesTile extends ConsumerStatefulWidget {
  @override
  ConsumerState<_BlockedDatesTile> createState() => _BlockedDatesTileState();
}

class _BlockedDatesTileState extends ConsumerState<_BlockedDatesTile> {
  /// 表示中の月 (1日固定)
  late DateTime _viewMonth;

  /// 編集中の選択日セット (yyyy-MM-dd ローカル)。
  /// build 中に blockedDatesProvider と同期し、 保存ボタンで一括反映。
  Set<String> _selected = <String>{};
  bool _dirty = false;
  bool _hydrated = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _viewMonth = DateTime(now.year, now.month, 1);
  }

  String _key(DateTime d) {
    final dd = DateTime(d.year, d.month, d.day);
    return dd.toIso8601String().substring(0, 10);
  }

  void _toggle(DateTime d) {
    final k = _key(d);
    setState(() {
      if (_selected.contains(k)) {
        _selected.remove(k);
      } else {
        _selected.add(k);
      }
      _dirty = true;
    });
  }

  Future<void> _save() async {
    final dates = _selected
        .map((k) => DateTime.parse(k))
        .toList()
      ..sort();
    await ref.read(blockedDatesProvider.notifier).setAll(dates);
    if (!mounted) return;
    setState(() => _dirty = false);
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.blockedDatesSaved)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final asyncDates = ref.watch(blockedDatesProvider);
    final stored = asyncDates.valueOrNull ?? const <DateTime>[];
    // 初回 (または編集前) はサーバ状態を取り込み
    if (!_hydrated && asyncDates.hasValue) {
      _selected = stored.map(_key).toSet();
      _hydrated = true;
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(l10n.blockedDatesLabel,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700)),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_left, size: 22),
                onPressed: () => setState(() {
                  _viewMonth =
                      DateTime(_viewMonth.year, _viewMonth.month - 1, 1);
                }),
              ),
              Text(
                DateFormat.yMMM(
                        Localizations.localeOf(context).toLanguageTag())
                    .format(_viewMonth),
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right, size: 22),
                onPressed: () => setState(() {
                  _viewMonth =
                      DateTime(_viewMonth.year, _viewMonth.month + 1, 1);
                }),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            l10n.blockedDatesPickerHint,
            style: TextStyle(
                fontSize: 11.5, color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          _MonthGrid(
            month: _viewMonth,
            selected: _selected,
            startOfWeek: ref.watch(startOfWeekProvider),
            onTap: _toggle,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                l10n.blockedDatesSelectedCount(_selected.length),
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: _dirty ? _save : null,
                icon: const Icon(Icons.save_outlined, size: 18),
                label: Text(l10n.save),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 単月カレンダーグリッド (7列、 週の開始曜日は [startOfWeek] で指定)。
/// 過去日はグレーアウトし tap 不可。 選択は accent 色で塗り。
class _MonthGrid extends StatelessWidget {
  const _MonthGrid({
    required this.month,
    required this.selected,
    required this.startOfWeek,
    required this.onTap,
  });

  final DateTime month;
  final Set<String> selected;

  /// ISO weekday: 1=月 / 6=土 / 7=日
  final int startOfWeek;
  final ValueChanged<DateTime> onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final first = DateTime(month.year, month.month, 1);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final leading = (first.weekday - startOfWeek + 7) % 7;
    final locale = Localizations.localeOf(context).toLanguageTag();
    // 2024-01-01 は月曜 → 開始曜日に合わせて 7 個生成
    final weekdays = List<String>.generate(7, (i) {
      final ref = DateTime(2024, 1, 1 + ((startOfWeek - 1 + i) % 7));
      return DateFormat.E(locale).format(ref);
    });

    final cells = <Widget>[];
    for (final w in weekdays) {
      cells.add(Center(
        child: Text(w,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurfaceVariant,
            )),
      ));
    }
    for (var i = 0; i < leading; i++) {
      cells.add(const SizedBox.shrink());
    }
    for (var day = 1; day <= daysInMonth; day++) {
      final d = DateTime(month.year, month.month, day);
      final isPast = d.isBefore(today);
      final key = d.toIso8601String().substring(0, 10);
      final isSelected = selected.contains(key);
      cells.add(_GridDayCell(
        day: day,
        isPast: isPast,
        isSelected: isSelected,
        isToday: d == today,
        onTap: isPast ? null : () => onTap(d),
      ));
    }
    return GridView.count(
      crossAxisCount: 7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.1,
      mainAxisSpacing: 2,
      crossAxisSpacing: 2,
      children: cells,
    );
  }
}

class _GridDayCell extends StatelessWidget {
  const _GridDayCell({
    required this.day,
    required this.isPast,
    required this.isSelected,
    required this.isToday,
    required this.onTap,
  });

  final int day;
  final bool isPast;
  final bool isSelected;
  final bool isToday;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    Color bg;
    Color fg;
    if (isSelected) {
      bg = cs.primary;
      fg = cs.onPrimary;
    } else if (isPast) {
      bg = Colors.transparent;
      fg = cs.onSurface.withValues(alpha: 0.3);
    } else {
      bg = cs.surfaceContainerHighest.withValues(alpha: 0.6);
      fg = cs.onSurface;
    }
    return Material(
      color: bg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: isToday && !isSelected
            ? BorderSide(color: cs.primary, width: 1.5)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Center(
          child: Text(
            '$day',
            style: TextStyle(
              fontSize: 13,
              fontWeight: isToday ? FontWeight.w800 : FontWeight.w600,
              color: fg,
            ),
          ),
        ),
      ),
    );
  }
}

/// #2: 予定がある日のタスク割り当てを避ける toggle。
class _AvoidEventDaysToggle extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final asyncEnabled = ref.watch(avoidEventDaysProvider);
    final enabled = asyncEnabled.valueOrNull ?? false;
    return SwitchListTile(
      secondary: const Icon(Icons.event_busy_outlined),
      title: Text(l10n.avoidEventDaysToggle),
      subtitle: Text(l10n.avoidEventDaysDesc),
      value: enabled,
      onChanged: (v) {
        ref.read(avoidEventDaysProvider.notifier).setEnabled(v);
      },
    );
  }
}

/// #6-2: タスク整理リマインド ON/OFF トグル。
class _AiReminderToggle extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final asyncEnabled = ref.watch(aiReminderEnabledProvider);
    final enabled = asyncEnabled.valueOrNull ?? true;
    return SwitchListTile(
      secondary: const Icon(Icons.notifications_active_outlined),
      title: Text(l10n.aiReminderToggle),
      subtitle: Text(l10n.aiReminderToggleDesc),
      value: enabled,
      onChanged: (v) {
        ref.read(aiReminderEnabledProvider.notifier).setEnabled(v);
      },
    );
  }
}

/// #1 VIP コード入力フィールド用: 失敗時に揺らす効果。
class _ShakeWrapper extends StatefulWidget {
  const _ShakeWrapper({super.key, required this.child});
  final Widget child;

  @override
  State<_ShakeWrapper> createState() => _ShakeWrapperState();
}

class _ShakeWrapperState extends State<_ShakeWrapper>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void shake() {
    _ctrl.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        final t = _ctrl.value;
        // 4 回振動、 振幅 12px
        final dx = (t == 0)
            ? 0.0
            : 12 *
                (1 - t) *
                (t < 0.25
                    ? t * 4
                    : t < 0.5
                        ? 1 - (t - 0.25) * 4
                        : t < 0.75
                            ? -((t - 0.5) * 4)
                            : -1 + (t - 0.75) * 4);
        return Transform.translate(offset: Offset(dx, 0), child: child);
      },
      child: widget.child,
    );
  }
}

/// #4: 通知タイミング設定 (3 トグル + 時刻 TimePicker)。
class _NotifyTimingTile extends ConsumerWidget {
  const _NotifyTimingTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final asyncPrefs = ref.watch(notifyTimingProvider);
    final prefs = asyncPrefs.valueOrNull;
    if (prefs == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: SizedBox(
          height: 24,
          child: Center(
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
      );
    }
    final theme = Theme.of(context);
    final notifier = ref.read(notifyTimingProvider.notifier);
    final timeLabel =
        '${prefs.hour.toString().padLeft(2, '0')}:${prefs.minute.toString().padLeft(2, '0')}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
          child: Text(
            l10n.notifyTimingHeader,
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w700),
          ),
        ),
        SwitchListTile(
          dense: true,
          value: prefs.onRecommended,
          onChanged: (v) => notifier.setOnRecommended(v),
          title: Text(l10n.notifyOnRecommended),
        ),
        SwitchListTile(
          dense: true,
          value: prefs.onDue,
          onChanged: (v) => notifier.setOnDue(v),
          title: Text(l10n.notifyOnDue),
        ),
        SwitchListTile(
          dense: true,
          value: prefs.onOverdue,
          onChanged: (v) => notifier.setOnOverdue(v),
          title: Text(l10n.notifyOnOverdue),
        ),
        ListTile(
          dense: true,
          leading: const Icon(Icons.schedule_rounded),
          title: Text(l10n.notifyTimeLabel),
          subtitle: Text(timeLabel,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.primary)),
          onTap: () async {
            final picked = await showTimePicker(
              context: context,
              initialTime: TimeOfDay(hour: prefs.hour, minute: prefs.minute),
            );
            if (picked == null) return;
            await notifier.setTime(picked.hour, picked.minute);
          },
        ),
      ],
    );
  }
}
