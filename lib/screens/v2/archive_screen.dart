import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../models/category.dart' as model;
import '../../providers/category_provider.dart';
import '../../providers/task_provider.dart';
import '../../theme/yaru_theme.dart';
import '../../widgets/responsive_wrapper.dart';
import '../../widgets/v2/task_card.dart';

/// 完了済みタスクのアーカイブ画面 (過去7日より前の完了タスク全件)。
///
/// ホーム画面では過去7日分の完了タスクのみ表示し、それ以前はこの画面で確認。
/// 長期利用でホーム画面が肥大化するのを防ぎつつ、必要なら全履歴を辿れる。
class V2ArchiveScreen extends ConsumerWidget {
  const V2ArchiveScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final yaru = context.yaru;
    final l10n = AppLocalizations.of(context)!;
    final tasksAsync = ref.watch(allTasksProvider);
    final categoriesAsync = ref.watch(categoriesProvider);

    final categoryMap = <int, model.Category>{};
    categoriesAsync.whenData((cats) {
      for (final c in cats) {
        if (c.id != null) categoryMap[c.id!] = c;
      }
    });

    final cutoff = DateTime.now().subtract(const Duration(days: 7));

    return Scaffold(
      backgroundColor: yaru.scaffoldBg,
      appBar: AppBar(
        backgroundColor: yaru.scaffoldBg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text(
          l10n.archiveTitle,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: yaru.inkPrimary,
          ),
        ),
      ),
      body: SafeArea(
        child: ResponsiveWrapper(
          child: tasksAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('$e')),
            data: (tasks) {
              final older = tasks
                  .where((t) => t.isCompleted)
                  .where((t) {
                    final ts = t.completedAt ?? t.updatedAt;
                    return ts.isBefore(cutoff);
                  })
                  .toList()
                ..sort((a, b) => (b.completedAt ?? b.updatedAt)
                    .compareTo(a.completedAt ?? a.updatedAt));

              if (older.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.archive_outlined,
                            size: 40, color: yaru.inkTertiary),
                        const SizedBox(height: 12),
                        Text(
                          l10n.archiveEmpty,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: yaru.inkSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                itemCount: older.length,
                itemBuilder: (context, i) {
                  final t = older[i];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: V2TaskCard(
                      task: t,
                      category: t.categoryId != null
                          ? categoryMap[t.categoryId]
                          : null,
                      onTap: () {
                        if (t.id != null) context.push('/task/${t.id}');
                      },
                      onToggleComplete: () {
                        ref.read(tasksProvider.notifier).completeTask(t);
                      },
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
