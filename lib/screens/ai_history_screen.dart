import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../l10n/generated/app_localizations.dart';
import '../providers/task_provider.dart';
import '../services/ai_service.dart';
import '../widgets/ai_sort_button.dart';
import '../widgets/responsive_wrapper.dart';

class AiHistoryScreen extends ConsumerWidget {
  const AiHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final db = ref.read(databaseServiceProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.aiHistory)),
      body: ResponsiveWrapper(
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: db.getAiHistory(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final history = snapshot.data!;
            if (history.isEmpty) {
              return Center(
                child: Text(
                  l10n.aiHistoryEmpty,
                  style: TextStyle(color: theme.colorScheme.outline),
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: history.length,
              itemBuilder: (context, index) {
                final entry = history[index];
                final createdAt =
                    DateTime.parse(entry['created_at'] as String);
                final dateStr =
                    DateFormat.yMMMd(locale).add_Hm().format(createdAt);
                final summary = locale == 'ja'
                    ? entry['summary_ja'] as String?
                    : entry['summary_en'] as String?;
                final taskCount = entry['task_count'] as int;

                return Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: Icon(Icons.auto_awesome,
                        color: theme.colorScheme.primary),
                    title: Text(
                      summary ?? dateStr,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      '$dateStr · ${l10n.aiHistoryCount(taskCount)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.outline,
                      ),
                    ),
                    onTap: () => _showHistoryDetail(
                        context, ref, entry, locale),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  void _showHistoryDetail(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> entry,
    String locale,
  ) {
    try {
      final resultJson =
          jsonDecode(entry['result_json'] as String) as Map<String, dynamic>;
      final response = AiSortResponse.fromJson(resultJson);
      // 結果をProviderにセットして結果画面へ遷移
      ref.read(aiSortResponseProvider.notifier).state = response;
      context.push('/ai-result');
    } catch (_) {
      // パース失敗時は何もしない
    }
  }
}
