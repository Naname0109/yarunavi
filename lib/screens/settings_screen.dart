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
import '../providers/dev_mode_provider.dart';
import '../utils/constants.dart';
import '../utils/test_data.dart';
import '../widgets/banner_ad_widget.dart';
import '../widgets/coach_overlay.dart';
import '../providers/secure_storage_provider.dart';
import '../services/secure_storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/responsive_wrapper.dart';

/// 開発者モード解放状態（バージョン7回タップで有効化）
final _devModeEnabledProvider = StateProvider<bool>((ref) => false);

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  int _versionTapCount = 0;

  void _onVersionTap() {
    _versionTapCount++;
    final l10n = AppLocalizations.of(context)!;

    if (_versionTapCount >= 7) {
      ref.read(_devModeEnabledProvider.notifier).state = true;
      _versionTapCount = 0;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.devModeEnabled)),
      );
    } else if (_versionTapCount >= 4) {
      final remaining = 7 - _versionTapCount;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.devModeRemaining(remaining)),
          duration: const Duration(milliseconds: 800),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isPremium = ref.watch(isPremiumProvider);
    final currentLocale = ref.watch(localeProvider);
    final currentTheme = ref.watch(themeModeProvider);
    final theme = Theme.of(context);
    final devModeEnabled = ref.watch(_devModeEnabledProvider);

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

                  // --- テーマ ---
                  _buildSectionHeader(context, l10n.settingsTheme),
                  RadioListTile<ThemeMode>(
                    title: Text(l10n.lightTheme),
                    value: ThemeMode.light,
                    groupValue: currentTheme,
                    onChanged: (value) {
                      ref
                          .read(themeModeProvider.notifier)
                          .setThemeMode(ThemeMode.light);
                    },
                  ),
                  RadioListTile<ThemeMode>(
                    title: Text(l10n.darkTheme),
                    value: ThemeMode.dark,
                    groupValue: currentTheme,
                    onChanged: (value) {
                      ref
                          .read(themeModeProvider.notifier)
                          .setThemeMode(ThemeMode.dark);
                    },
                  ),
                  RadioListTile<ThemeMode>(
                    title: Text(l10n.systemTheme),
                    value: ThemeMode.system,
                    groupValue: currentTheme,
                    onChanged: (value) {
                      ref
                          .read(themeModeProvider.notifier)
                          .setThemeMode(ThemeMode.system);
                    },
                  ),
                  const Divider(),

                  // --- タスクのスケジュール (#3) ---
                  _buildSectionHeader(context, l10n.scheduleSection),
                  _WeekdayBusynessTile(),
                  _BlockedDatesTile(),
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

                  // --- アプリ情報（7回タップで開発者モード解放） ---
                  ListTile(
                    key: const Key('app_info_tile'),
                    leading: const Icon(Icons.info_outline),
                    title: Text(l10n.appInfo),
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
                  // --- 開発者モード（7回タップで解放） ---
                  if (devModeEnabled) ...[
                    const Divider(),
                    _buildSectionHeader(context, l10n.devModeSection),
                    const _DevModeToggles(),
                    ListTile(
                      key: const Key('debug_animations_entry'),
                      leading: const Icon(Icons.animation_outlined),
                      title: Text(l10n.devModeAnimationsPreview),
                      subtitle: Text(l10n.devModeAnimationsPreviewDesc),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push('/debug-animations'),
                    ),
                    const Divider(),
                    _buildSectionHeader(context, l10n.debugSection),
                    ListTile(
                      key: const Key('debug_simple_data'),
                      leading: const Icon(Icons.looks_one_outlined),
                      title: Text(l10n.debugSimpleData),
                      subtitle: Text(l10n.debugSimpleDataDesc),
                      onTap: () => _insertTestDataWithConfirm(
                        context, ref, l10n,
                        () => insertSimpleTestData(
                            ref.read(databaseServiceProvider)),
                      ),
                    ),
                    ListTile(
                      key: const Key('debug_detailed_data'),
                      leading: const Icon(Icons.looks_two_outlined),
                      title: Text(l10n.debugDetailedData),
                      subtitle: Text(l10n.debugDetailedDataDesc),
                      onTap: () => _insertTestDataWithConfirm(
                        context, ref, l10n,
                        () => insertDetailedTestData(
                            ref.read(databaseServiceProvider)),
                      ),
                    ),
                    ListTile(
                      key: const Key('debug_edge_case_data'),
                      leading: const Icon(Icons.looks_3_outlined),
                      title: Text(l10n.debugEdgeCaseData),
                      subtitle: Text(l10n.debugEdgeCaseDataDesc),
                      onTap: () => _insertTestDataWithConfirm(
                        context, ref, l10n,
                        () => insertEdgeCaseTestData(
                            ref.read(databaseServiceProvider)),
                      ),
                    ),
                    ListTile(
                      leading: const Icon(Icons.restart_alt),
                      title: Text(l10n.devModeResetAiUsage),
                      subtitle: Text(l10n.devModeResetAiUsageDesc),
                      onTap: () => _resetAiUsage(context, ref, l10n),
                    ),
                    const Divider(),
                    _buildSectionHeader(context, l10n.devModeReviewSection),
                    ListTile(
                      leading: const Icon(Icons.rate_review_outlined),
                      title: Text(l10n.devModeTestReview),
                      subtitle: Text(l10n.devModeTestReviewDesc),
                      onTap: () {
                        ref.read(reviewServiceProvider).requestReview();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(l10n.devModeTestReviewTriggered)),
                        );
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.restart_alt),
                      title: Text(l10n.devModeResetReview),
                      subtitle: Text(l10n.devModeResetReviewDesc),
                      onTap: () async {
                        await ref
                            .read(reviewServiceProvider)
                            .resetCounters();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content:
                                    Text(l10n.devModeResetReviewDone)),
                          );
                        }
                      },
                    ),
                  ],
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

  Future<void> _insertTestDataWithConfirm(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    Future<void> Function() insertFn,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.debugSection),
        content: Text(l10n.debugConfirmInsert),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.debugConfirmInsertAction),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await insertFn();
      ref.invalidate(tasksProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.debugTestDataInserted)),
        );
      }
    }
  }

  Future<void> _resetAiUsage(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.devModeResetAiUsage),
        content: Text(l10n.devModeConfirmResetAiUsage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('OK'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final db = ref.read(databaseServiceProvider);
      await db.resetCurrentMonthAiUsage();
      final secure = ref.read(secureStorageServiceProvider);
      await secure.resetAiUsage(
        SecureStorageService.currentMonthKey(DateTime.now()),
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.devModeResetAiUsageDone)),
        );
      }
    }
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

/// 開発者モードのトグルスイッチ群
class _DevModeToggles extends ConsumerWidget {
  const _DevModeToggles();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final aiUnlimited = ref.watch(devModeAiUnlimitedProvider);
    final premium = ref.watch(devModePremiumProvider);
    final useNewUi = ref.watch(useNewUiProvider);

    return Column(
      children: [
        SwitchListTile(
          secondary: const Icon(Icons.all_inclusive),
          title: Text(l10n.devModeAiUnlimited),
          subtitle: Text(l10n.devModeAiUnlimitedDesc),
          value: aiUnlimited,
          onChanged: (value) {
            ref.read(devModeAiUnlimitedProvider.notifier).toggle(value);
          },
        ),
        SwitchListTile(
          key: const Key('premium_mode_toggle'),
          secondary: const Icon(Icons.workspace_premium),
          title: Text(l10n.devModePremium),
          subtitle: Text(l10n.devModePremiumDesc),
          value: premium,
          onChanged: (value) {
            ref.read(devModePremiumProvider.notifier).toggle(value);
          },
        ),
        SwitchListTile(
          key: const Key('use_new_ui_toggle'),
          secondary: const Icon(Icons.auto_awesome),
          title: Text(l10n.devModeUseNewUi),
          subtitle: Text(l10n.devModeUseNewUiDesc),
          value: useNewUi,
          onChanged: (value) {
            ref.read(useNewUiProvider.notifier).toggle(value);
          },
        ),
      ],
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

/// #3-2: タスク実行不可日。
class _BlockedDatesTile extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final asyncDates = ref.watch(blockedDatesProvider);
    final dates = asyncDates.valueOrNull ?? const <DateTime>[];
    final fmt = DateFormat.yMd(
        Localizations.localeOf(context).toLanguageTag());
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
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
              TextButton.icon(
                onPressed: () => _addDate(context, ref),
                icon: const Icon(Icons.add, size: 18),
                label: Text(l10n.blockedDatesAdd),
              ),
            ],
          ),
          if (dates.isEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 8),
              child: Text(
                l10n.blockedDatesEmpty,
                style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).hintColor),
              ),
            ),
          for (final d in dates)
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.block, size: 18),
              title: Text(fmt.format(d)),
              trailing: IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: () =>
                    ref.read(blockedDatesProvider.notifier).remove(d),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _addDate(BuildContext context, WidgetRef ref) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year, now.month - 1, 1),
      lastDate: DateTime(now.year + 1, 12, 31),
    );
    if (picked == null) return;
    await ref.read(blockedDatesProvider.notifier).add(picked);
  }
}
