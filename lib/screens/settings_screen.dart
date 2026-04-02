import 'dart:io';

import 'package:flutter/foundation.dart';
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
import '../utils/test_data.dart';
import '../widgets/banner_ad_widget.dart';
import '../widgets/responsive_wrapper.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                      leading: const Icon(Icons.workspace_premium),
                      title: Text(l10n.settingsUpgradeToPremium),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push('/store'),
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

                  // --- データ管理 ---
                  _buildSectionHeader(context, l10n.dataManagement),
                  ListTile(
                    leading: const Icon(Icons.file_download_outlined),
                    title: Text(l10n.settingsExportCsv),
                    onTap: () => _exportCsv(context, ref, l10n),
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

                  // --- アプリ情報 ---
                  ListTile(
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
                  // --- デバッグ（kDebugModeのみ）---
                  if (kDebugMode) ...[
                    const Divider(),
                    _buildSectionHeader(context, l10n.debugSection),
                    ListTile(
                      leading: const Icon(Icons.science_outlined),
                      title: Text(l10n.debugInsertTestData),
                      onTap: () => _insertTestData(context, ref, l10n, false),
                    ),
                    ListTile(
                      leading: Icon(
                        Icons.delete_sweep,
                        color: theme.colorScheme.error,
                      ),
                      title: Text(l10n.debugDeleteAndInsertTestData),
                      onTap: () => _insertTestData(context, ref, l10n, true),
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
      // UTF-8 BOM（Excel互換のため）
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

  Future<void> _insertTestData(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    bool deleteFirst,
  ) async {
    final message = deleteFirst
        ? l10n.debugConfirmDeleteAndInsert
        : l10n.debugConfirmInsert;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.debugSection),
        content: Text(message),
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
      if (deleteFirst) {
        await db.deleteAllData();
      }
      await insertTestData(db);
      ref.invalidate(tasksProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.debugTestDataInserted)),
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
