import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../models/category.dart' as model;
import '../../models/task.dart';
import '../../providers/category_provider.dart';
import '../../providers/gamification_provider.dart';
import '../../providers/task_provider.dart';
import '../../theme/yaru_theme.dart';
import '../../providers/event_provider.dart';
import '../../services/event_sync_service.dart';
import '../../widgets/event_form_sheet.dart';
import '../../widgets/responsive_wrapper.dart';
import '../../widgets/task_form_sheet.dart';
import '../../widgets/v2/badge_unlock_popup.dart';
import '../../widgets/v2/expandable_task_card.dart';
import '../../widgets/v2/glass_bottom_nav.dart';
import '../../widgets/v2/hero_ai_card.dart';
import '../../widgets/v2/level_up_overlay.dart';
import '../../widgets/v2/task_card.dart';
import '../../widgets/v2/xp_floating.dart';
import '../settings_screen.dart';
import 'calendar_screen.dart';
import 'stats_screen.dart';

/// v2のメインシェル: ボトムナビ + 4タブ (Home/Calendar/Stats/Settings) + 中央FAB
class V2HomeShell extends ConsumerStatefulWidget {
  const V2HomeShell({
    super.key,
    this.initialTab = 0,
    this.openTaskFormOnStart = false,
  });
  final int initialTab;

  /// オンボーディング完了直後など、表示後すぐにタスク追加シートを開きたい場合 true
  final bool openTaskFormOnStart;

  @override
  ConsumerState<V2HomeShell> createState() => _V2HomeShellState();
}

class _V2HomeShellState extends ConsumerState<V2HomeShell> {
  late int _index = widget.initialTab.clamp(0, 3);
  final _floatingHostKey = GlobalKey<XpFloatingHostState>();

  @override
  void initState() {
    super.initState();
    if (widget.openTaskFormOnStart) {
      // ホーム遷移直後のアニメーションを少し待ってからシート表示
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) TaskFormSheet.show(context);
        });
      });
    }
  }

  void _onAdd() {
    HapticFeedback.mediumImpact();
    // #2: カレンダータブ (index=1) の場合は「タスク / 予定」 選択シート、
    // それ以外は従来通り直接タスク追加。
    if (_index == 1) {
      _showAddChoiceSheet();
    } else {
      TaskFormSheet.show(context);
    }
  }

  void _showAddChoiceSheet() {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.check_circle_outline),
              title: Text(l10n.fabAddTask),
              onTap: () {
                Navigator.of(ctx).pop();
                TaskFormSheet.show(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.event_outlined),
              title: Text(l10n.fabAddEvent),
              onTap: () {
                Navigator.of(ctx).pop();
                EventFormSheet.show(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.sync_outlined),
              title: Text(l10n.fabSyncCalendar),
              onTap: () async {
                Navigator.of(ctx).pop();
                await _syncCalendarEvents();
              },
            ),
          ],
        ),
      ),
    );
  }

  /// FAB メニューからのカレンダー同期。
  /// 事前確認ダイアログは挟まず、権限取得は OS 標準ダイアログに委ねる
  /// (Apple Guideline 5.1.1(iv) 準拠)。拒否時のみ設定導線を提示。
  Future<void> _syncCalendarEvents() async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final db = ref.read(databaseServiceProvider);
    final svc = EventSyncService(db);
    final count = await svc.syncNext60Days();
    ref.invalidate(eventsProvider);
    if (!mounted) return;
    if (count < 0) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.calendarPermissionDenied),
          action: SnackBarAction(
            label: l10n.calendarOpenSettings,
            onPressed: () {
              launchUrl(
                Uri.parse('app-settings:'),
                mode: LaunchMode.externalApplication,
              ).ignore();
            },
          ),
        ),
      );
    } else {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.calendarSyncDone(count))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // XP/レベルアップ/バッジ獲得イベントをリスニング
    ref.listen<XpFloatingState?>(xpFloatingProvider, (prev, next) {
      if (next != null && next != prev) {
        _floatingHostKey.currentState?.show(next.amount);
      }
    });
    ref.listen<LevelUpEvent?>(levelUpProvider, (prev, next) {
      if (next != null && next != prev && context.mounted) {
        LevelUpOverlay.show(context, next.newLevel);
        // 一度表示したらクリア（再表示防止）
        Future.microtask(
            () => ref.read(levelUpProvider.notifier).state = null);
      }
    });
    ref.listen(newBadgesProvider, (prev, next) {
      if (next.isNotEmpty && context.mounted) {
        // キューを順次表示 (前のpopupが消えてから次)
        BadgeUnlockPopup.show(context, next.first);

        // ストリーク達成バッジならローカル通知でも祝福 (バックグラウンド復帰時にも気付ける)
        const streakBadgeDays = {
          'streak_3': 3,
          'streak_7': 7,
          'streak_14': 14,
          'streak_30': 30,
        };
        final l10n = AppLocalizations.of(context)!;
        final notify = ref.read(notificationServiceProvider);
        for (final b in next) {
          final days = streakBadgeDays[b.id];
          if (days != null) {
            notify.showStreakMilestoneNotification(
              streakDays: days,
              title: l10n.streakMilestoneTitle(days),
              body: l10n.streakMilestoneBody,
            );
          }
        }

        // 表示済みを除去
        Future.delayed(const Duration(milliseconds: 2400), () {
          if (!context.mounted) return;
          final current = ref.read(newBadgesProvider);
          if (current.isNotEmpty) {
            ref.read(newBadgesProvider.notifier).state = current.sublist(1);
          }
        });
      }
    });

    return Scaffold(
      extendBody: true,
      body: XpFloatingHost(
        key: _floatingHostKey,
        child: IndexedStack(
          index: _index,
          children: [
            const _V2HomeTab(),
            V2CalendarScreen(isActive: _index == 1),
            // IndexedStack は全タブを mount するため、 統計タブの
            // 初回チュートリアルがホームタブ上で表示されてしまわないよう
            // isActive を渡す。
            V2StatsScreen(isActive: _index == 2),
            const SettingsScreen(),
          ],
        ),
      ),
      bottomNavigationBar: GlassBottomNav(
        items: [
          GlassNavItem(icon: Icons.home_rounded, label: l10n.navHome),
          GlassNavItem(icon: Icons.calendar_month_rounded, label: l10n.navCalendar),
          GlassNavItem(icon: Icons.emoji_events_rounded, label: l10n.navStats),
          GlassNavItem(icon: Icons.settings_rounded, label: l10n.navSettings),
        ],
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        onAddPressed: _onAdd,
      ),
    );
  }
}

class _V2HomeTab extends ConsumerStatefulWidget {
  const _V2HomeTab();

  @override
  ConsumerState<_V2HomeTab> createState() => _V2HomeTabState();
}

class _V2HomeTabState extends ConsumerState<_V2HomeTab> {
  final _scrollController = ScrollController();
  final _keyToday = GlobalKey();
  final _keyThisWeek = GlobalKey();
  final _keyLater = GlobalKey();

  /// 同時に展開できるカードを 1 つに制限 (#101 Gmail 風)。
  /// null = どれも展開していない。 同じ ID を再タップで折りたたむ。
  int? _expandedTaskId;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _scrollTo(GlobalKey key) async {
    final ctx = key.currentContext;
    if (ctx == null) return;
    HapticFeedback.selectionClick();
    await Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      alignment: 0.05,
    );
  }

  @override
  Widget build(BuildContext context) {
    final yaru = context.yaru;
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    // 完了済みも含む全タスクをデータソースとして使い、4セクション + 完了済み
    // 折りたたみを一つの ListView で組み立てる
    final tasksAsync = ref.watch(allTasksProvider);
    final categoriesAsync = ref.watch(categoriesProvider);

    final categoryMap = <int, model.Category>{};
    categoriesAsync.whenData((categories) {
      for (final c in categories) {
        if (c.id != null) categoryMap[c.id!] = c;
      }
    });

    return Scaffold(
      backgroundColor: yaru.scaffoldBg,
      body: SafeArea(
        bottom: false,
        child: ResponsiveWrapper(
          child: tasksAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => Center(child: Text(l10n.taskLoadError)),
            data: (tasks) {
              final split = _splitTasks(tasks);
              final (done, total) = _todayDoneTotal(tasks);
              // App Store 審査リジェクト (2026-05-28) 対応:
              // HeroAiCard の AI整理 CTA を「今日のタスク0でも未完了タスクが
              // あれば表示」させるため、未完了タスク総数を別途渡す。
              final totalIncomplete =
                  tasks.where((t) => !t.isCompleted).length;
              final completedTasks =
                  tasks.where((t) => t.isCompleted).toList()
                    ..sort((a, b) => (b.completedAt ?? b.updatedAt)
                        .compareTo(a.completedAt ?? a.updatedAt));
              final laterTasks = [...split.nextWeek, ...split.later];
              // サマリーチップでは "今日(本日締切)" と "期限超過" を別カウントで表示するため
              // split.today から overdue 分を差し引く (split.today は期限切れも含むため二重計上を防ぐ)
              final todayDueOnlyCount =
                  split.today.length - split.overdue.length;
              final totalOpen = todayDueOnlyCount +
                  split.thisWeek.length +
                  laterTasks.length +
                  split.overdue.length;
              return RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(tasksProvider);
                  ref.invalidate(allTasksProvider);
                  await ref.read(allTasksProvider.future);
                  if (context.mounted) HapticFeedback.mediumImpact();
                },
                child: ListView(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(top: 8, bottom: 140),
                  children: [
                    _greetingHeader(context, locale, yaru),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: HeroAiCard(
                        todayDone: done,
                        todayTotal: total,
                        totalIncomplete: totalIncomplete,
                        onAddTask: () {
                          HapticFeedback.mediumImpact();
                          TaskFormSheet.show(context);
                        },
                      ),
                    ),
                    const _NaviHintMiniCard(),
                    const SizedBox(height: 14),
                    _summaryStrip(
                      context: context,
                      yaru: yaru,
                      l10n: l10n,
                      todayCount: todayDueOnlyCount,
                      weekCount: split.thisWeek.length,
                      laterCount: laterTasks.length,
                      overdueCount: split.overdue.length,
                      totalOpen: totalOpen,
                    ),
                    const SizedBox(height: 16),
                    // 4セクションを常時表示 (空でも空状態を出す)
                    _section(
                      context: context,
                      yaru: yaru,
                      label: l10n.sectionNow,
                      tasks: split.today,
                      color: yaru.urgent,
                      categoryMap: categoryMap,
                      ref: ref,
                      emptyHint: l10n.sectionEmptyNow,
                      anchorKey: _keyToday,
                    ),
                    _section(
                      context: context,
                      yaru: yaru,
                      label: l10n.sectionThisWeek,
                      tasks: split.thisWeek,
                      color: yaru.soon,
                      categoryMap: categoryMap,
                      ref: ref,
                      emptyHint: l10n.sectionEmptyThisWeek,
                      anchorKey: _keyThisWeek,
                    ),
                    _section(
                      context: context,
                      yaru: yaru,
                      label: l10n.sectionLater,
                      tasks: laterTasks,
                      color: yaru.later,
                      categoryMap: categoryMap,
                      ref: ref,
                      emptyHint: l10n.sectionEmptyLater,
                      anchorKey: _keyLater,
                    ),
                    _CompletedSection(
                      tasks: completedTasks,
                      categoryMap: categoryMap,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  /// ヒーローAIカード直下の "件数サマリー" 帯。
  /// 今日/今週/来週以降/期限超過 を一目で把握でき、タップで該当セクションへスクロール。
  Widget _summaryStrip({
    required BuildContext context,
    required YaruTheme yaru,
    required AppLocalizations l10n,
    required int todayCount,
    required int weekCount,
    required int laterCount,
    required int overdueCount,
    required int totalOpen,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: [
            if (overdueCount > 0) ...[
              _summaryChip(
                yaru: yaru,
                icon: Icons.priority_high_rounded,
                label: l10n.homeOverdueChip(overdueCount),
                color: yaru.urgent,
                onTap: () => _scrollTo(_keyToday),
                emphasized: true,
              ),
              const SizedBox(width: 8),
            ],
            _summaryChip(
              yaru: yaru,
              label: l10n.sectionNow,
              count: todayCount,
              color: yaru.urgent,
              onTap: () => _scrollTo(_keyToday),
            ),
            const SizedBox(width: 8),
            _summaryChip(
              yaru: yaru,
              label: l10n.sectionThisWeek,
              count: weekCount,
              color: yaru.soon,
              onTap: () => _scrollTo(_keyThisWeek),
            ),
            const SizedBox(width: 8),
            _summaryChip(
              yaru: yaru,
              label: l10n.sectionLater,
              count: laterCount,
              color: yaru.later,
              onTap: () => _scrollTo(_keyLater),
            ),
            const SizedBox(width: 8),
            _summaryChip(
              yaru: yaru,
              label: l10n.homeQuickTotalLabel,
              count: totalOpen,
              color: yaru.inkSecondary,
              onTap: () => _scrollTo(_keyToday),
              outlined: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryChip({
    required YaruTheme yaru,
    IconData? icon,
    required String label,
    int? count,
    required Color color,
    required VoidCallback onTap,
    bool outlined = false,
    bool emphasized = false,
  }) {
    final bg = emphasized
        ? color.withValues(alpha: 0.18)
        : outlined
            ? Colors.transparent
            : color.withValues(alpha: 0.10);
    final borderColor = outlined ? yaru.line : color.withValues(alpha: 0.32);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: borderColor),
            boxShadow: emphasized && yaru.useGlassBlur
                ? [BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 10)]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 12, color: color),
                const SizedBox(width: 4),
              ] else ...[
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: outlined ? yaru.inkSecondary : color,
                  letterSpacing: 0.2,
                ),
              ),
              if (count != null) ...[
                const SizedBox(width: 6),
                // 件数 (情報の核) はラベルより重く表示。
                // ライト時は色を 1.15倍 程度濃くして WCAG AA を確保 (B-7)。
                Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w900,
                    color: outlined
                        ? yaru.inkPrimary
                        : Color.lerp(color, yaru.inkPrimary, 0.25)!,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _section({
    required BuildContext context,
    required YaruTheme yaru,
    required String label,
    required List<Task> tasks,
    required Color color,
    required Map<int, model.Category> categoryMap,
    required WidgetRef ref,
    required String emptyHint,
    Key? anchorKey,
  }) {
    return Column(
      key: anchorKey,
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionHeader(
          context: context,
          label: label,
          count: tasks.length,
          color: color,
        ),
        const SizedBox(height: 8),
        if (tasks.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: yaru.paper,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: yaru.line),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle_outline_rounded,
                      size: 16, color: yaru.inkTertiary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      emptyHint,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: yaru.inkTertiary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          _taskList(tasks, categoryMap, ref),
        const SizedBox(height: 18),
      ],
    );
  }

  Widget _greetingHeader(BuildContext context, String locale, YaruTheme yaru) {
    final now = DateTime.now();
    final dateStr = DateFormat.MMMMd(locale).format(now);
    final dow = DateFormat.E(locale).format(now);
    final h = now.hour;
    final greetingKey = h < 10
        ? 'goodMorning'
        : h < 18
            ? 'goodAfternoon'
            : 'goodEvening';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _greeting(context, greetingKey),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: yaru.inkTertiary,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 2),
          RichText(
            text: TextSpan(
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w800,
                height: 1.05,
                color: yaru.inkPrimary,
                letterSpacing: -0.5,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
              children: [
                TextSpan(text: dateStr),
                TextSpan(
                  text: ' $dow',
                  style: TextStyle(
                    fontSize: 16,
                    // 曜日が読めるように 1段濃く (B-13)
                    color: yaru.inkTertiary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _greeting(BuildContext context, String key) {
    final l10n = AppLocalizations.of(context)!;
    // i18nに無いキーは "Today" で代用
    return switch (key) {
      'goodMorning' => l10n.greetingMorning,
      'goodAfternoon' => l10n.greetingAfternoon,
      'goodEvening' => l10n.greetingEvening,
      _ => l10n.today,
    };
  }

  Widget _sectionHeader({
    required BuildContext context,
    required String label,
    required int count,
    required Color color,
  }) {
    final yaru = context.yaru;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: yaru.useGlassBlur
                  ? [BoxShadow(color: color.withValues(alpha: 0.6), blurRadius: 6)]
                  : null,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: yaru.inkSecondary,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: yaru.inkTertiary,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 12),
              height: 1,
              color: yaru.line,
            ),
          ),
        ],
      ),
    );
  }

  Widget _taskList(
    List<Task> tasks,
    Map<int, model.Category> categoryMap,
    WidgetRef ref,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          for (final t in tasks)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: ExpandableV2TaskCard(
                task: t,
                category:
                    t.categoryId != null ? categoryMap[t.categoryId] : null,
                isExpanded: _expandedTaskId == t.id,
                onToggleExpand: () {
                  setState(() {
                    _expandedTaskId =
                        _expandedTaskId == t.id ? null : t.id;
                  });
                },
                onComplete: () {
                  ref.read(tasksProvider.notifier).completeTask(t);
                },
              ),
            ),
        ],
      ),
    );
  }
}

/// 完了済みタスクの折りたたみセクション。
class _CompletedSection extends ConsumerStatefulWidget {
  const _CompletedSection({
    required this.tasks,
    required this.categoryMap,
  });
  final List<Task> tasks;
  final Map<int, model.Category> categoryMap;

  @override
  ConsumerState<_CompletedSection> createState() => _CompletedSectionState();
}

class _CompletedSectionState extends ConsumerState<_CompletedSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final yaru = context.yaru;
    final l10n = AppLocalizations.of(context)!;
    if (widget.tasks.isEmpty) return const SizedBox.shrink();

    // 過去7日以内に完了したタスクのみホームに表示し、それ以前はアーカイブ画面へ。
    // 長期利用でホームの完了履歴が肥大化するのを防ぐ。
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    final recent = widget.tasks.where((t) {
      final ts = t.completedAt ?? t.updatedAt;
      return !ts.isBefore(cutoff);
    }).toList();
    final olderCount = widget.tasks.length - recent.length;
    if (recent.isEmpty && olderCount == 0) {
      return const SizedBox.shrink();
    }
    final preview =
        recent.take(_expanded ? recent.length : 3).toList();

    return Column(
      children: [
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: yaru.calm,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  l10n.completed,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: yaru.inkSecondary,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${recent.length}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: yaru.inkTertiary,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '· ${l10n.archiveRecentLabel}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: yaru.inkQuaternary,
                  ),
                ),
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    height: 1,
                    color: yaru.line,
                  ),
                ),
                // 履歴一括削除 (オーバーフロー回避のため省スペース)
                InkWell(
                  onTap: () => _confirmDeleteAllHistory(context, l10n),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 4),
                    child: Icon(
                      Icons.delete_sweep_rounded,
                      size: 16,
                      color: yaru.inkTertiary,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  _expanded
                      ? Icons.expand_less_rounded
                      : Icons.expand_more_rounded,
                  size: 18,
                  color: yaru.inkTertiary,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              for (final t in preview)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _completedRow(context, l10n, t),
                ),
              if (olderCount > 0) ...[
                const SizedBox(height: 4),
                Center(
                  child: TextButton.icon(
                    onPressed: () => context.push('/archive'),
                    icon: Icon(Icons.archive_outlined,
                        size: 16, color: yaru.inkSecondary),
                    label: Text(
                      l10n.archiveOpenButton(olderCount),
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: yaru.inkSecondary,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 18),
      ],
    );
  }

  /// 完了済みカード 1行: Dismissible (左スワイプで個別削除) +
  /// V2TaskCard (archived モード, onUncomplete)。
  Widget _completedRow(
    BuildContext context,
    AppLocalizations l10n,
    Task t,
  ) {
    final yaru = context.yaru;
    return Dismissible(
      key: ValueKey('completed-${t.id ?? t.title}-${t.completedAt}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: yaru.urgent.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: yaru.urgent.withValues(alpha: 0.45)),
        ),
        child: Icon(Icons.delete_outline_rounded,
            color: yaru.urgent, size: 22),
      ),
      confirmDismiss: (_) async {
        return _confirmDeleteOne(context, l10n);
      },
      onDismissed: (_) async {
        if (t.id != null) {
          await ref.read(tasksProvider.notifier).deleteTask(t.id!);
        }
      },
      child: V2TaskCard(
        task: t,
        category:
            t.categoryId != null ? widget.categoryMap[t.categoryId] : null,
        mode: V2TaskCardMode.archived,
        onTap: () {
          if (t.id != null) context.push('/task/${t.id}');
        },
        onToggleComplete: () {},
        onUncomplete: () => _uncompleteWithSnack(context, l10n, t),
      ),
    );
  }

  Future<void> _uncompleteWithSnack(
    BuildContext context,
    AppLocalizations l10n,
    Task t,
  ) async {
    await ref.read(tasksProvider.notifier).uncompleteTask(t);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.taskUncompletedSnack),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: l10n.undo,
          onPressed: () {
            ref.read(tasksProvider.notifier).completeTask(t);
          },
        ),
      ),
    );
  }

  Future<bool> _confirmDeleteOne(
      BuildContext context, AppLocalizations l10n) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteHistoryConfirmTitle),
        content: Text(l10n.deleteHistoryConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              foregroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _confirmDeleteAllHistory(
      BuildContext context, AppLocalizations l10n) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteAllHistoryConfirmTitle),
        content: Text(l10n.deleteAllHistoryConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              foregroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: Text(l10n.deleteAllAction),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final count =
        await ref.read(tasksProvider.notifier).deleteAllCompletedHistory();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.historyDeletedSnack(count))),
    );
  }
}

({
  List<Task> today,
  List<Task> overdue,
  List<Task> thisWeek,
  List<Task> nextWeek,
  List<Task> later,
}) _splitTasks(List<Task> tasks) {
  // #5: 分類ロジックを厳格化。
  // - 今日: recommended_date が今日 (なければ due_date が今日) または期限切れ
  // - 今週: 明日〜今週日曜まで (today を除外)
  // - 来週: 翌週月曜〜翌週日曜
  // - 来週以降 (laterList): 再来週以降
  // priority だけで「今日」 扱いする旧ロジックは廃止 (5/23 のタスクが今日に
  // 混ざる問題の元凶)。
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final daysUntilSunday =
      now.weekday == DateTime.sunday ? 0 : DateTime.sunday - now.weekday;
  final endOfWeek = today.add(Duration(days: daysUntilSunday));
  final endOfNextWeek = endOfWeek.add(const Duration(days: 7));

  final todayList = <Task>[];
  final overdueList = <Task>[];
  final thisWeekList = <Task>[];
  final nextWeekList = <Task>[];
  final laterList = <Task>[];

  for (final t in tasks) {
    if (t.isCompleted) continue;
    final dueDay = DateTime(t.dueDate.year, t.dueDate.month, t.dueDate.day);
    final recDay = t.recommendedDate != null
        ? DateTime(t.recommendedDate!.year, t.recommendedDate!.month,
            t.recommendedDate!.day)
        : null;
    final targetDay = recDay ?? dueDay;
    final isOverdue = dueDay.isBefore(today);

    if (isOverdue) {
      // 期限切れは常に「今日」 + overdue リストにも入れる (バッジ集計用)
      overdueList.add(t);
      todayList.add(t);
    } else if (targetDay == today) {
      todayList.add(t);
    } else if (targetDay.isAfter(today) && !targetDay.isAfter(endOfWeek)) {
      thisWeekList.add(t);
    } else if (targetDay.isAfter(endOfWeek) &&
        !targetDay.isAfter(endOfNextWeek)) {
      nextWeekList.add(t);
    } else {
      laterList.add(t);
    }

    if (kDebugMode) {
      String section;
      if (isOverdue) {
        section = '今日(overdue)';
      } else if (targetDay == today) {
        section = '今日';
      } else if (!targetDay.isAfter(endOfWeek)) {
        section = '今週';
      } else if (!targetDay.isAfter(endOfNextWeek)) {
        section = '来週';
      } else {
        section = '来週以降';
      }
      debugPrint(
          '[SECTION] ${t.title}: rec=${t.recommendedDate} due=${t.dueDate} → $section');
    }
  }
  todayList.sort((a, b) => a.priority.compareTo(b.priority));
  return (
    today: todayList,
    overdue: overdueList,
    thisWeek: thisWeekList,
    nextWeek: nextWeekList,
    later: laterList,
  );
}

(int, int) _todayDoneTotal(List<Task> tasks) {
  // #5: _splitTasks と同じ判定で「今日」 セクションに入るタスクの完了率を計算。
  // 旧: priority==1 で水増しされる問題があったため統一。
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  int total = 0;
  int done = 0;
  for (final t in tasks) {
    final dueDay = DateTime(t.dueDate.year, t.dueDate.month, t.dueDate.day);
    final recDay = t.recommendedDate != null
        ? DateTime(t.recommendedDate!.year, t.recommendedDate!.month,
            t.recommendedDate!.day)
        : null;
    final targetDay = recDay ?? dueDay;
    final isOverdue = dueDay.isBefore(today);
    final isToday = targetDay == today;
    if (isOverdue || isToday) {
      total++;
      if (t.isCompleted) done++;
    }
  }
  return (done, total);
}

/// #9: 最新 AI 履歴サマリーを返す FutureProvider。
/// ai_sort_button から `ref.invalidate(latestAiHistoryProvider)` で再取得できる。
final latestAiHistoryProvider =
    FutureProvider<Map<String, dynamic>?>((ref) async {
  // tasksProvider への変更で AI 整理直後にも自動再評価される
  ref.watch(tasksProvider);
  final db = ref.read(databaseServiceProvider);
  return db.getLatestAiHistory();
});

/// #9: Hero AI カード下に表示する「ナビからのひとこと」 ミニカード。
/// 最新の AI 整理履歴の summary を表示。 未実行ならカード自体非表示。
class _NaviHintMiniCard extends ConsumerWidget {
  const _NaviHintMiniCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final yaru = context.yaru;
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final asyncHistory = ref.watch(latestAiHistoryProvider);
    return asyncHistory.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (row) {
        if (row == null) return const SizedBox.shrink();
        final summary = locale == 'ja'
            ? (row['summary_ja'] as String?)
            : (row['summary_en'] as String?);
        if (summary == null || summary.isEmpty) {
          return const SizedBox.shrink();
        }
        final createdAtStr = row['created_at'] as String?;
        DateTime? createdAt;
        if (createdAtStr != null) createdAt = DateTime.tryParse(createdAtStr);
        final timestamp = createdAt != null
            ? DateFormat.MMMd(locale).add_Hm().format(createdAt)
            : '';
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
          child: Container(
            decoration: BoxDecoration(
              color: yaru.paperEmph,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: yaru.line, width: 1),
            ),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 4,
                    decoration: BoxDecoration(
                      color: yaru.accent,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(14),
                        bottomLeft: Radius.circular(14),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding:
                          const EdgeInsets.fromLTRB(12, 12, 12, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.auto_awesome,
                                  size: 14, color: yaru.accent),
                              const SizedBox(width: 6),
                              Text(
                                l10n.naviHintTitle,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: yaru.accent,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            summary,
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.5,
                              color: yaru.inkPrimary,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Text(
                                l10n.naviHintLastSort(timestamp),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: yaru.inkTertiary,
                                ),
                              ),
                              const Spacer(),
                              InkWell(
                                onTap: () => context.push('/ai-history'),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  child: Row(
                                    children: [
                                      Text(
                                        l10n.naviHintDetail,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: yaru.accent,
                                        ),
                                      ),
                                      Icon(Icons.chevron_right,
                                          size: 14, color: yaru.accent),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
