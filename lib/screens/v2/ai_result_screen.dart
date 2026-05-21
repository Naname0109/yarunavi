import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../models/task.dart';
import '../../providers/purchase_provider.dart';
import '../../providers/task_provider.dart';
import '../../services/ai_service.dart';
import '../../theme/yaru_colors.dart';
import '../../theme/yaru_theme.dart';
import '../../utils/date_utils.dart' as app_date;
import '../../widgets/ai_sort_button.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/neon_button.dart';
import '../../widgets/responsive_wrapper.dart';
import '../../widgets/sparkle_badge.dart';

/// v2 AI整理結果画面: Conicオーブ + 番号付きバケット + AIアドバイス。
///
/// プレミアム自動セットアップ等の高度な機能は既存 [AiResultScreen] に残し、
/// 今回は redesigned UI でのプレビュー表示にフォーカス。
class V2AiResultScreen extends ConsumerWidget {
  const V2AiResultScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final yaru = context.yaru;
    final l10n = AppLocalizations.of(context)!;
    final response = ref.watch(aiSortResponseProvider);

    if (response == null) {
      return Scaffold(
        backgroundColor: yaru.scaffoldBg,
        body: Center(
          child: Text(l10n.aiSortNoTasks),
        ),
      );
    }

    return Scaffold(
      backgroundColor: yaru.scaffoldBg,
      body: SafeArea(
        child: ResponsiveWrapper(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _topBar(context, yaru),
              ),
              SliverToBoxAdapter(
                child: _hero(context, yaru, l10n, response),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                  child: _statStrip(context, yaru, l10n, response),
                ),
              ),
              if (response.summaryJa != null || response.summaryEn != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: _aiNote(context, yaru, l10n, response),
                  ),
                ),
              SliverToBoxAdapter(
                child: _buckets(context, yaru, l10n, response),
              ),
              // #3: AI からの確認事項 (questions が空でなければ表示)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: _AiQuestionsSection(response: response),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
                  child: _ctaRow(context, ref, l10n),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _topBar(BuildContext context, YaruTheme yaru) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              context.pop();
            },
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: yaru.paper,
                border: Border.all(color: yaru.line),
              ),
              child: Icon(Icons.chevron_left_rounded,
                  size: 18, color: yaru.inkSecondary),
            ),
          ),
          const Spacer(),
          Text(
            _now(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: yaru.inkTertiary,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _hero(
    BuildContext context,
    YaruTheme yaru,
    AppLocalizations l10n,
    AiSortResponse response,
  ) {
    final taskCount = response.tasks.length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        children: [
          _OrbBadge(),
          const SizedBox(height: 16),
          Text(
            l10n.aiResultOptimizedBadge,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: yaru.sparkle,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: yaru.inkPrimary,
                height: 1.2,
                letterSpacing: -0.5,
              ),
              children: [
                TextSpan(text: '$taskCount件を\n'),
                _gradSpan(
                    text: l10n.aiResultOptimized,
                    gradient: yaru.neonGradient),
              ],
            ),
          ),
        ],
      ),
    );
  }

  TextSpan _gradSpan({required String text, required Gradient gradient}) {
    return TextSpan(
      text: text,
      style: TextStyle(
        foreground: Paint()
          ..shader = gradient.createShader(const Rect.fromLTWH(0, 0, 300, 50)),
      ),
    );
  }

  Widget _statStrip(
    BuildContext context,
    YaruTheme yaru,
    AppLocalizations l10n,
    AiSortResponse response,
  ) {
    int now = 0, week = 0, later = 0;
    for (final t in response.tasks) {
      if (t.priority == 1) {
        now++;
      } else if (t.priority == 2) {
        week++;
      } else {
        later++;
      }
    }
    return Row(
      children: [
        Expanded(child: _statTile(yaru, l10n.aiResultNowLabel, now, yaru.urgent)),
        const SizedBox(width: 8),
        Expanded(child: _statTile(yaru, l10n.aiResultWeekLabel, week, yaru.soon)),
        const SizedBox(width: 8),
        Expanded(child: _statTile(yaru, l10n.aiResultLaterLabel, later, yaru.later)),
      ],
    );
  }

  Widget _statTile(YaruTheme yaru, String label, int value, Color color) {
    return GlassCard(
      padding: const EdgeInsets.all(12),
      borderRadius: 14,
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$value',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: color,
                  height: 1,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: color.withValues(alpha: 0.85),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          Positioned(
            right: 0,
            top: 0,
            child: Container(
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
          ),
        ],
      ),
    );
  }

  Widget _aiNote(
    BuildContext context,
    YaruTheme yaru,
    AppLocalizations l10n,
    AiSortResponse response,
  ) {
    final locale = Localizations.localeOf(context).languageCode;
    final summary = locale == 'ja'
        ? response.summaryJa ?? response.summaryEn
        : response.summaryEn ?? response.summaryJa;
    if (summary == null || summary.isEmpty) return const SizedBox.shrink();
    return GlassCard(
      padding: const EdgeInsets.all(14),
      borderRadius: 16,
      borderColor: yaru.sparkle.withValues(alpha: 0.25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SparkleBadge(size: 22, glow: false),
              const SizedBox(width: 8),
              Text(
                l10n.aiNaviNoteLabel,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: yaru.sparkle,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            summary,
            style: TextStyle(
              fontSize: 13.5,
              color: yaru.inkPrimary,
              height: 1.7,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buckets(
    BuildContext context,
    YaruTheme yaru,
    AppLocalizations l10n,
    AiSortResponse response,
  ) {
    return Consumer(builder: (ctx, ref, _) {
      final tasksAsync = ref.watch(tasksProvider);
      final titleMap = tasksAsync.maybeWhen(
        data: (list) => {for (final t in list) if (t.id != null) t.id!: t.title},
        orElse: () => const <int, String>{},
      );
      final groups = <(String, Color, List<AiSortResult>)>[
        (l10n.aiResultNowLabel, yaru.urgent,
            response.tasks.where((t) => t.priority == 1).toList()),
        (l10n.aiResultWeekLabel, yaru.soon,
            response.tasks.where((t) => t.priority == 2).toList()),
        (l10n.aiResultLaterLabel, yaru.later,
            response.tasks.where((t) => t.priority >= 3).toList()),
      ];
      return Column(
        children: [
          for (final g in groups)
            if (g.$3.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                child: _bucket(context, yaru, g.$1, g.$2, g.$3, titleMap),
              ),
        ],
      );
    });
  }

  Widget _bucket(
    BuildContext context,
    YaruTheme yaru,
    String label,
    Color color,
    List<AiSortResult> items,
    Map<int, String> titleMap,
  ) {
    final locale = Localizations.localeOf(context).languageCode;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
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
                color: color,
                letterSpacing: 0.6,
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
        const SizedBox(height: 10),
        for (var i = 0; i < items.length; i++) ...[
          GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            borderRadius: 14,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: color.withValues(alpha: 0.35)),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${i + 1}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: color,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titleMap[items[i].taskId] ??
                            'Task #${items[i].taskId}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: yaru.inkPrimary,
                        ),
                      ),
                      Builder(builder: (_) {
                        final c = locale == 'ja'
                            ? items[i].commentJa ?? items[i].commentEn
                            : items[i].commentEn ?? items[i].commentJa;
                        if (c == null || c.isEmpty) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            c,
                            style: TextStyle(
                              fontSize: 11.5,
                              color: yaru.inkTertiary,
                              height: 1.5,
                            ),
                          ),
                        );
                      }),
                      // #1-2: 推奨実行日 + 「変更」 リンク
                      Consumer(builder: (ctx, ref, _) {
                        final tasksAsync = ref.watch(tasksProvider);
                        final task = tasksAsync.maybeWhen(
                          data: (list) => list
                              .where((t) => t.id == items[i].taskId)
                              .cast<Task?>()
                              .firstWhere((t) => t != null,
                                  orElse: () => null),
                          orElse: () => null,
                        );
                        if (task == null) return const SizedBox.shrink();
                        final rec = task.recommendedDate;
                        if (rec == null) return const SizedBox.shrink();
                        final l10n = AppLocalizations.of(ctx)!;
                        final fmt = app_date.formatDateWithWeekday(rec, locale);
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Row(
                            children: [
                              Icon(Icons.flag_outlined,
                                  size: 12, color: yaru.inkTertiary),
                              const SizedBox(width: 4),
                              Text(
                                '${l10n.labelExecutionDay} $fmt',
                                style: TextStyle(
                                    fontSize: 11.5,
                                    color: yaru.inkSecondary,
                                    fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(width: 4),
                              // タップターゲットを 44pt 確保 (アクセシビリティ)
                              InkWell(
                                onTap: () =>
                                    _editRecommendedDate(ctx, ref, task),
                                borderRadius: BorderRadius.circular(8),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 12),
                                  child: Text(
                                    l10n.aiResultChangeDate,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: yaru.accent,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (i < items.length - 1) const SizedBox(height: 8),
        ],
      ],
    );
  }

  Widget _ctaRow(BuildContext context, WidgetRef ref, AppLocalizations l10n) {
    return NeonButton(
      label: l10n.aiResultStartCta,
      icon: Icons.bolt_rounded,
      height: 50,
      onPressed: () => _startWithTopTask(context, ref),
    );
  }

  /// #1-2: AI 結果画面で 推奨実行日を変更する DatePicker。
  Future<void> _editRecommendedDate(
      BuildContext context, WidgetRef ref, Task task) async {
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastDate = task.dueDate.isBefore(today)
        ? today.add(const Duration(days: 30))
        : task.dueDate;
    final initial = task.recommendedDate ?? today;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(today) ? today : initial,
      firstDate: today,
      lastDate: lastDate,
      helpText: l10n.pickExecutionDayTooltip,
    );
    if (picked == null || task.id == null) return;
    if (!context.mounted) return;
    await ref
        .read(tasksProvider.notifier)
        .updateRecommendedDate(task.id!, picked);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.executionDayUpdated)),
    );
  }

  /// 「この順番で進める」: ホーム画面に戻る (#2)。
  /// 旧仕様では最優先タスクの詳細画面まで自動 push していたが、
  /// ユーザーが整理結果を眺める前に詳細画面に飛ばされて困惑するため、
  /// ホーム画面の「今日」 セクションを見せるだけに変更。
  void _startWithTopTask(BuildContext context, WidgetRef ref) {
    context.go('/home');
  }

  String _now() {
    final n = DateTime.now();
    return '${n.year}.${n.month.toString().padLeft(2, '0')}.${n.day.toString().padLeft(2, '0')} · '
        '${n.hour.toString().padLeft(2, '0')}:${n.minute.toString().padLeft(2, '0')}';
  }
}

class _OrbBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final yaru = context.yaru;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      width: 110,
      height: 110,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (isDark)
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: yaru.magentaGlow,
                ),
              ),
            ),
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: yaru.aiOrbGradient,
              boxShadow: isDark
                  ? const [
                      BoxShadow(
                        color: Color(0xB35B7BFF),
                        blurRadius: 50,
                        offset: Offset(0, 20),
                        spreadRadius: -10,
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark ? YaruColors.bgDark1 : Colors.white,
                ),
                child: Icon(
                  Icons.auto_awesome,
                  size: 36,
                  color: isDark ? Colors.white : yaru.sparkle,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// #3: AI からの確認事項セクション。
/// - response.questions が空なら表示しない
/// - 質問リスト + 自由入力 + 「回答してさらに詳しく整理」 (プレミアム限定)
/// - 注記「※ 追加の AI 整理回数は消費しません」 を直下に表示
/// - 回答送信後、 refineWithAnswers を呼び結果を更新 (questions 空に上書き)
class _AiQuestionsSection extends ConsumerStatefulWidget {
  const _AiQuestionsSection({required this.response});
  final AiSortResponse response;

  @override
  ConsumerState<_AiQuestionsSection> createState() =>
      _AiQuestionsSectionState();
}

class _AiQuestionsSectionState
    extends ConsumerState<_AiQuestionsSection> with WidgetsBindingObserver {
  final _controller = TextEditingController();
  bool _submitting = false;
  /// #1: ユーザーが「この質問を閉じる」 を押したら true。
  /// 質問セクション全体を AnimatedCrossFade で非表示にし、 AI 結果は維持する。
  bool _dismissed = false;

  @override
  void initState() {
    super.initState();
    // #2: バックグラウンド遷移を観測 (API call は継続するが、 ログだけ残す)
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_submitting) {
      debugPrint('[AI-REFINE] lifecycle: $state (refine in flight)');
    }
  }

  void _close() {
    FocusScope.of(context).unfocus();
    setState(() => _dismissed = true);
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    final isPremium = ref.read(isPremiumProvider);
    final isVip = ref.read(isVipProvider);
    if (!isPremium && !isVip) {
      await _showPremiumDialog(l10n);
      return;
    }
    final answer = _controller.text.trim();
    if (answer.isEmpty) return;
    final locale = Localizations.localeOf(context).languageCode;
    FocusScope.of(context).unfocus();
    setState(() => _submitting = true);

    // #2: 初回 AI 整理と同じ進捗モーダルを表示。 Tips も自動表示される。
    final db = ref.read(databaseServiceProvider);
    final allTasks = await db.getAllTasks();
    final incompleteTasks =
        allTasks.where((t) => !t.isCompleted).toList();
    final progress = AiSortProgressController(
      incompleteTasks.length,
      isRefine: true,
    );
    bool dialogOpen = true;
    if (mounted) {
      // ignore: unawaited_futures
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AiLoadingDialog(
          l10n: l10n,
          controller: progress,
          onBackground: () {
            if (dialogOpen) {
              dialogOpen = false;
              Navigator.of(ctx).pop();
            }
          },
        ),
      );
    }
    progress.setPhase(AiSortPhase.sending);
    Future.delayed(const Duration(milliseconds: 300), () {
      if (progress.phase == AiSortPhase.sending) {
        progress.setPhase(AiSortPhase.awaiting);
      }
    });

    try {
      final categories = await db.getAllCategories();
      final categoryNames = <int, String>{};
      for (final c in categories) {
        if (c.id != null) categoryNames[c.id!] = c.name;
      }
      final refined = await AiService.refineWithAnswers(
        incompleteTasks,
        previous: widget.response,
        userAnswer: answer,
        categoryNames: categoryNames,
      );
      progress.setPhase(AiSortPhase.receiving);
      if (!mounted) {
        if (dialogOpen) {
          dialogOpen = false;
        }
        return;
      }
      ref.read(aiSortResponseProvider.notifier).state = refined;
      // DB 反映 (追加カウントは消費しない)
      final updates = <int,
          ({int priority, String? aiComment, DateTime? recommendedDate})>{};
      for (final r in refined.tasks) {
        DateTime? rec;
        if (r.recommendedDate != null) {
          rec = DateTime.tryParse(r.recommendedDate!);
        }
        final comment =
            locale == 'ja' ? r.commentJa : (r.commentEn ?? r.commentJa);
        updates[r.taskId] = (
          priority: r.priority,
          aiComment: comment,
          recommendedDate: rec,
        );
      }
      if (updates.isNotEmpty) {
        await db.updateTaskPriorities(updates);
        ref.invalidate(tasksProvider);
      }
      progress.setPhase(AiSortPhase.finalizing);
      await Future.delayed(const Duration(milliseconds: 400));
      progress.setPhase(AiSortPhase.complete);
      await Future.delayed(const Duration(milliseconds: 800));
      if (dialogOpen && mounted) {
        dialogOpen = false;
        Navigator.of(context, rootNavigator: true).pop();
      }
      if (!mounted) return;
      // 質問セクションを閉じる (再質問は出ない仕様)
      setState(() => _dismissed = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.aiRefineDone)),
      );
    } on AiServiceException catch (e) {
      progress.setPhase(AiSortPhase.error);
      await Future.delayed(const Duration(milliseconds: 600));
      if (dialogOpen && mounted) {
        dialogOpen = false;
        Navigator.of(context, rootNavigator: true).pop();
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${l10n.aiRefineFailed}: ${e.message}')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
      progress.dispose();
    }
  }

  Future<void> _showPremiumDialog(AppLocalizations l10n) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(Icons.workspace_premium_rounded,
            size: 36, color: Theme.of(ctx).colorScheme.primary),
        title: Text(l10n.aiRefinePremiumOnlyTitle),
        content: Text(l10n.aiRefinePremiumOnlyBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.push('/store');
            },
            child: Text(l10n.aiSortUpgradeToPremium),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final questions = locale == 'ja'
        ? widget.response.questionsJa
        : (widget.response.questionsEn.isNotEmpty
            ? widget.response.questionsEn
            : widget.response.questionsJa);
    if (questions.isEmpty) return const SizedBox.shrink();
    final yaru = context.yaru;
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return AnimatedCrossFade(
      duration: const Duration(milliseconds: 300),
      sizeCurve: Curves.easeOut,
      firstCurve: Curves.easeOut,
      secondCurve: Curves.easeIn,
      crossFadeState:
          _dismissed ? CrossFadeState.showSecond : CrossFadeState.showFirst,
      firstChild: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: yaru.paperEmph,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: yaru.line, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.help_outline_rounded,
                    size: 18, color: theme.colorScheme.primary),
                const SizedBox(width: 6),
                Text(
                  l10n.aiQuestionsHeader,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.primary,
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              l10n.aiQuestionsLeadIn,
              style: TextStyle(
                fontSize: 12,
                color: yaru.inkSecondary,
              ),
            ),
            const SizedBox(height: 10),
            for (var i = 0; i < questions.length; i++) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '${i + 1}. ${questions[i]}',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    color: yaru.inkPrimary,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 10),
            TextField(
              controller: _controller,
              maxLines: 3,
              enabled: !_submitting,
              decoration: InputDecoration(
                hintText: l10n.aiQuestionsAnswerHint,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 10),
            FilledButton.icon(
              onPressed: _submitting ? null : _submit,
              icon: _submitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.auto_awesome_rounded, size: 18),
              label: Text(
                _submitting ? l10n.aiRefining : l10n.aiQuestionsRefineCta,
              ),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(46),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.aiQuestionsNoExtraCount,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: yaru.inkTertiary,
              ),
            ),
            const SizedBox(height: 8),
            // #1: 質問セクションを閉じるテキストボタン
            Center(
              child: TextButton(
                onPressed: _submitting ? null : _close,
                child: Text(
                  l10n.aiQuestionsCloseCta,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: yaru.inkSecondary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      secondChild: const SizedBox.shrink(),
    );
  }
}
