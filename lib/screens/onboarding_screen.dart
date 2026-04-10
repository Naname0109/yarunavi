import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/generated/app_localizations.dart';
import '../theme/colors.dart';
import '../widgets/responsive_wrapper.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  final _page2Key = GlobalKey<_Page2BeforeAfterState>();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_onboarding_completed', true);
    if (prefs.getBool('coachmarks_shown') == null) {
      await prefs.setBool('coachmarks_shown', false);
    }
    if (mounted) {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final pages = <Widget>[
      _Page1AddTasks(l10n: l10n, isDark: isDark),
      _Page2BeforeAfter(key: _page2Key, l10n: l10n, isDark: isDark),
      _Page3Calendar(l10n: l10n, isDark: isDark),
      _Page4Notification(l10n: l10n, isDark: isDark),
      _Page5Premium(
        l10n: l10n,
        isDark: isDark,
        onFreeTap: _completeOnboarding,
        onPremiumTap: () {
          _completeOnboarding();
          if (mounted) context.push('/store');
        },
      ),
      _Page6Start(l10n: l10n, isDark: isDark),
    ];

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [const Color(0xFF1A1A2E), const Color(0xFF121212)]
                : [const Color(0xFFF0F4FF), Colors.white],
          ),
        ),
        child: SafeArea(
          child: ResponsiveWrapper(
            child: Column(
              children: [
                // スキップボタン
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: _currentPage < pages.length - 1
                        ? TextButton(
                            onPressed: _completeOnboarding,
                            child: Text(l10n.onboardingSkip),
                          )
                        : const SizedBox(height: 40),
                  ),
                ),
                // ページビュー
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (i) {
                      setState(() => _currentPage = i);
                      if (i == 1) _page2Key.currentState?.replay();
                    },
                    children: pages,
                  ),
                ),
                // ドットインジケーター
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(pages.length, (i) {
                      final isActive = i == _currentPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: isActive ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isActive
                              ? theme.colorScheme.primary
                              : theme.colorScheme.outline
                                  .withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                ),
                // ボタン
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                  child: SizedBox(
                    width: double.infinity,
                    child: _currentPage == pages.length - 1
                        ? FilledButton(
                            onPressed: _completeOnboarding,
                            style: FilledButton.styleFrom(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: Text(l10n.onboardingStart,
                                style: const TextStyle(fontSize: 16)),
                          )
                        : FilledButton.tonal(
                            onPressed: () {
                              _pageController.nextPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            },
                            style: FilledButton.styleFrom(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: Text(l10n.onboardingNext,
                                style: const TextStyle(fontSize: 16)),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// 画面1: やることを入れるだけ
// ─────────────────────────────────────────────
class _Page1AddTasks extends StatelessWidget {
  const _Page1AddTasks({required this.l10n, required this.isDark});
  final AppLocalizations l10n;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tasks = [
      l10n.ob1Task1,
      l10n.ob1Task2,
      l10n.ob1Task3,
      l10n.ob1Task4,
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // タスクリストのモック
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.colorScheme.outlineVariant,
              ),
            ),
            child: Column(
              children: tasks.map((task) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Icon(Icons.check_box_outline_blank,
                          size: 20, color: theme.colorScheme.outline),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(task,
                            style: const TextStyle(fontSize: 15)),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            l10n.ob1Title,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            l10n.ob1Desc,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.ob1Sub,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.outline,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// 画面2: AIが整理してくれる（ビフォーアフター）
// ─────────────────────────────────────────────
class _Page2BeforeAfter extends StatefulWidget {
  const _Page2BeforeAfter({super.key, required this.l10n, required this.isDark});
  final AppLocalizations l10n;
  final bool isDark;

  @override
  State<_Page2BeforeAfter> createState() => _Page2BeforeAfterState();
}

class _Page2BeforeAfterState extends State<_Page2BeforeAfter>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _beforeOpacity;
  late Animation<double> _afterOpacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3500),
    );

    // 0-2s: Before visible, 2-2.5s: fade out, 2.5-3s: After fade in, 3-3.5s: hold
    _beforeOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 57), // 0-2s
      TweenSequenceItem(
          tween: Tween(begin: 1.0, end: 0.0), weight: 14), // 2-2.5s
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 29), // rest
    ]).animate(_controller);

    _afterOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 64), // 0-2.25s
      TweenSequenceItem(
          tween: Tween(begin: 0.0, end: 1.0), weight: 14), // 2.25-2.75s
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 22), // rest
    ]).animate(_controller);

    // 初回表示でアニメーション開始
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// PageViewで再度このページに戻った際にアニメーションを再生
  void replay() {
    _controller.reset();
    _controller.forward();
  }

  @override
  Widget build(BuildContext context) {

    final theme = Theme.of(context);
    final l10n = widget.l10n;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // ビフォーアフターコンテナ
          SizedBox(
            height: 320,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                return Stack(
                  children: [
                    // Before
                    Opacity(
                      opacity: _beforeOpacity.value,
                      child: _buildBefore(theme, l10n),
                    ),
                    // After
                    Opacity(
                      opacity: _afterOpacity.value,
                      child: _buildAfter(theme, l10n),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          Text(
            l10n.ob2Title,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.ob2Desc,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBefore(ThemeData theme, AppLocalizations l10n) {
    final items = [
      (l10n.ob2BeforeTask1, l10n.ob2BeforeDate1),
      (l10n.ob2BeforeTask2, l10n.ob2BeforeDate2),
      (l10n.ob2BeforeTask3, l10n.ob2BeforeDate3),
      (l10n.ob2BeforeTask4, l10n.ob2BeforeDate4),
      (l10n.ob2BeforeTask5, l10n.ob2BeforeDate5),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.list, size: 18, color: theme.colorScheme.outline),
              const SizedBox(width: 6),
              Text(l10n.ob2BeforeLabel,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.outline)),
            ],
          ),
          const SizedBox(height: 12),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  children: [
                    Icon(Icons.circle, size: 6, color: theme.colorScheme.outline),
                    const SizedBox(width: 10),
                    Expanded(
                        child: Text(item.$1,
                            style: const TextStyle(fontSize: 14))),
                    Text(item.$2,
                        style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.outline)),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildAfter(ThemeData theme, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.3)),
      ),
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // 緊急
            _afterSection(
              theme,
              l10n.ob2AfterUrgent,
              AppColors.priorityUrgent,
              [
                (l10n.ob2AfterTask1, l10n.ob2AfterComment1),
                (l10n.ob2AfterTask2, l10n.ob2AfterComment2),
              ],
            ),
            const SizedBox(height: 8),
            // 今週中
            _afterSection(
              theme,
              l10n.ob2AfterWarning,
              AppColors.priorityWarning,
              [
                (l10n.ob2AfterTask3, l10n.ob2AfterComment3),
              ],
            ),
            const SizedBox(height: 8),
            // 来週以降
            _afterSection(
              theme,
              l10n.ob2AfterNormal,
              AppColors.priorityNormal,
              [
                (l10n.ob2AfterTask4, l10n.ob2AfterComment4),
              ],
            ),
            const SizedBox(height: 8),
            // 急がない
            _afterSection(
              theme,
              l10n.ob2AfterRelaxed,
              AppColors.priorityRelaxed,
              [
                (l10n.ob2AfterTask5, l10n.ob2AfterComment5),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _afterSection(ThemeData theme, String label, Color color,
      List<(String, String)> tasks) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color)),
        ...tasks.map((t) => Padding(
              padding: const EdgeInsets.only(left: 4, top: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 3,
                    height: 28,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(t.$1,
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w600)),
                        Text(t.$2,
                            style: TextStyle(
                                fontSize: 11,
                                color: theme.colorScheme.onSurfaceVariant)),
                      ],
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// 画面3: カレンダーで実行日が見える
// ─────────────────────────────────────────────
class _Page3Calendar extends StatelessWidget {
  const _Page3Calendar({required this.l10n, required this.isDark});
  final AppLocalizations l10n;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // カレンダーモック
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.colorScheme.outlineVariant),
            ),
            child: Column(
              children: [
                // 曜日ヘッダ
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: ['M', 'T', 'W', 'T', 'F', 'S', 'S']
                      .map((d) => SizedBox(
                            width: 32,
                            child: Text(d,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontSize: 11,
                                    color: theme.colorScheme.outline)),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 8),
                // 3行のモック日付 + 色バー
                _calendarRow(theme, [14, 15, 16, 17, 18, 19, 20], {
                  14: AppColors.priorityUrgent,
                  15: AppColors.priorityUrgent,
                }, 14),
                const SizedBox(height: 4),
                _calendarRow(theme, [21, 22, 23, 24, 25, 26, 27], {
                  21: AppColors.priorityWarning,
                  22: AppColors.priorityWarning,
                }, null),
                const SizedBox(height: 4),
                _calendarRow(theme, [28, 29, 30, 1, 2, 3, 4], {
                  29: AppColors.priorityNormal,
                  30: AppColors.priorityNormal,
                  1: AppColors.priorityNormal,
                }, null),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // 凡例
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _legend(AppColors.priorityUrgent, l10n.ob3LegendUrgent),
              const SizedBox(width: 12),
              _legend(AppColors.priorityWarning, l10n.ob3LegendWeek),
              const SizedBox(width: 12),
              _legend(AppColors.priorityNormal, l10n.ob3LegendLater),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            l10n.ob3Title,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            l10n.ob3Desc,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _calendarRow(ThemeData theme, List<int> days,
      Map<int, Color> bars, int? today) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: days.map((d) {
        final isToday = d == today;
        final barColor = bars[d];
        return SizedBox(
          width: 32,
          height: 36,
          child: Column(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: isToday
                      ? theme.colorScheme.primary.withValues(alpha: 0.15)
                      : null,
                  border: isToday
                      ? Border.all(color: theme.colorScheme.primary, width: 1.5)
                      : null,
                  borderRadius: BorderRadius.circular(11),
                ),
                alignment: Alignment.center,
                child: Text('$d',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight:
                          isToday ? FontWeight.bold : FontWeight.normal,
                      color: isToday ? theme.colorScheme.primary : null,
                    )),
              ),
              if (barColor != null)
                Container(
                  height: 4,
                  margin: const EdgeInsets.only(top: 2),
                  decoration: BoxDecoration(
                    color: barColor.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _legend(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 4,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(fontSize: 11)),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// 画面4: 通知で忘れない
// ─────────────────────────────────────────────
class _Page4Notification extends StatelessWidget {
  const _Page4Notification({required this.l10n, required this.isDark});
  final AppLocalizations l10n;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 通知モック
          _notificationMock(
            theme,
            'YaruNavi 9:00 AM',
            l10n.ob4Notify1,
          ),
          const SizedBox(height: 10),
          _notificationMock(
            theme,
            l10n.ob4NotifyPrevDay,
            l10n.ob4Notify2,
          ),
          const SizedBox(height: 32),
          Text(
            l10n.ob4Title,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            l10n.ob4Desc,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.ob4Sub,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.outline,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _notificationMock(ThemeData theme, String header, String body) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(header,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.outline)),
          const SizedBox(height: 4),
          Text(body, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// 画面5: プレミアムでもっと便利に
// ─────────────────────────────────────────────
class _Page5Premium extends StatelessWidget {
  const _Page5Premium({
    required this.l10n,
    required this.isDark,
    required this.onFreeTap,
    required this.onPremiumTap,
  });
  final AppLocalizations l10n;
  final bool isDark;
  final VoidCallback onFreeTap;
  final VoidCallback onPremiumTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              l10n.ob5Title,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            // 比較テーブル
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 無料
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text(l10n.ob5Free,
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.outline)),
                        const SizedBox(height: 12),
                        _featureRow(l10n.ob5AiSort, l10n.ob5FreeAi, false),
                        _featureRow(l10n.ob5Tasks, l10n.ob5FreeTasks, false),
                        _featureRow(l10n.ob5Notify, '—', false),
                        _featureRow(l10n.ob5Calendar, '—', false),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // プレミアム
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          theme.colorScheme.primary.withValues(alpha: 0.08),
                          theme.colorScheme.primary.withValues(alpha: 0.02),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.colorScheme.primary.withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(l10n.premium,
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary)),
                        const SizedBox(height: 12),
                        _featureRow(l10n.ob5AiSort, l10n.ob5PremiumAi, true),
                        _featureRow(l10n.ob5Tasks, l10n.ob5PremiumTasks, true),
                        _featureRow(l10n.ob5Notify, l10n.ob5PremiumNotify, true),
                        _featureRow(l10n.ob5Calendar, l10n.ob5PremiumCalendar, true),
                        _featureRow(l10n.ob5AiComment, l10n.ob5PremiumComment, true),
                        _featureRow(l10n.ob5Ads, l10n.ob5PremiumAds, true),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(l10n.ob5Price,
                style: TextStyle(
                    fontSize: 13, color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onPremiumTap,
                child: Text(l10n.ob5TrialButton),
              ),
            ),
            TextButton(
              onPressed: onFreeTap,
              child: Text(l10n.ob5FreeButton,
                  style: TextStyle(color: theme.colorScheme.outline)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _featureRow(String label, String value, bool isPremium) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500)),
          Text(value,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: isPremium ? FontWeight.w600 : FontWeight.normal)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// 画面6: さあ、始めましょう
// ─────────────────────────────────────────────
class _Page6Start extends StatelessWidget {
  const _Page6Start({required this.l10n, required this.isDark});
  final AppLocalizations l10n;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.rocket_launch,
              size: 80, color: theme.colorScheme.primary),
          const SizedBox(height: 32),
          Text(
            l10n.ob6Title,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            l10n.ob6Desc,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
