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
    if (mounted) context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final pages = <Widget>[
      _Page1Input(l10n: l10n),
      _Page2AiSort(l10n: l10n),
      _Page3Calendar(l10n: l10n),
      _Page4Premium(
        l10n: l10n,
        onFreeTap: _completeOnboarding,
        onPremiumTap: () {
          _completeOnboarding();
          if (mounted) context.push('/store');
        },
      ),
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
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: _currentPage < pages.length - 1
                        ? TextButton(
                            key: const Key('onboarding_skip'),
                            onPressed: _completeOnboarding,
                            child: Text(l10n.onboardingSkip),
                          )
                        : const SizedBox(height: 40),
                  ),
                ),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (i) => setState(() => _currentPage = i),
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
                              : theme.colorScheme.outline.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                  child: SizedBox(
                    width: double.infinity,
                    child: _currentPage == pages.length - 1
                        ? FilledButton(
                            onPressed: _completeOnboarding,
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: Text(l10n.onboardingStart,
                                style: const TextStyle(fontSize: 16)),
                          )
                        : FilledButton.tonal(
                            key: const Key('onboarding_next'),
                            onPressed: () => _pageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            ),
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
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

// ─── 画面1: タスク名と期限を入れるだけ ───
class _Page1Input extends StatelessWidget {
  const _Page1Input({required this.l10n});
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // タスク追加画面のシンプルなモック（タスク名+期限だけ）
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.colorScheme.outlineVariant),
            ),
            child: Column(
              children: [
                // タスク名入力モック
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.edit_outlined, size: 18, color: theme.colorScheme.outline),
                      const SizedBox(width: 8),
                      Text(l10n.ob1Task1,
                          style: TextStyle(fontSize: 15, color: theme.colorScheme.onSurface)),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                // 期限日モック
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today, size: 18, color: theme.colorScheme.outline),
                      const SizedBox(width: 8),
                      Text(l10n.ob2BeforeDate2,
                          style: TextStyle(fontSize: 15, color: theme.colorScheme.onSurface)),
                      const Spacer(),
                      Icon(Icons.chevron_right, size: 20, color: theme.colorScheme.outline),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // 保存ボタンモック
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: null,
                    child: Text(l10n.save),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Text(l10n.ob1TitleNew,
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center),
          const SizedBox(height: 12),
          Text(l10n.ob1SubNew,
              style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

// ─── 画面2: AIが全部やってくれる（before/after + 通知統合） ───
class _Page2AiSort extends StatelessWidget {
  const _Page2AiSort({required this.l10n});
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        children: [
          Text(l10n.ob2TitleNew,
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center),
          const SizedBox(height: 4),
          Text(l10n.ob2SubNew,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center),
          const SizedBox(height: 12),
          // Before（3件に削減）
          _buildBefore(theme),
          // 矢印
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.arrow_downward, size: 18, color: theme.colorScheme.primary),
                const SizedBox(width: 4),
                Text(l10n.ob2ArrowLabel,
                    style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary)),
              ],
            ),
          ),
          // After（3件のみ）
          _buildAfter(theme),
        ],
      ),
    );
  }

  Widget _buildBefore(ThemeData theme) {
    final items = [
      (l10n.ob2BeforeTask4, l10n.ob2BeforeDate4), // 週報提出 - 今日
      (l10n.ob2BeforeTask2, l10n.ob2BeforeDate2), // 家賃振込 - 明日
      (l10n.ob2BeforeTask5, l10n.ob2BeforeDate5), // 日用品 - 4/18
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.list, size: 16, color: theme.colorScheme.outline),
              const SizedBox(width: 4),
              Text(l10n.ob2BeforeLabel,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                      color: theme.colorScheme.outline)),
            ],
          ),
          const SizedBox(height: 6),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              children: [
                Icon(Icons.circle, size: 5, color: theme.colorScheme.outline),
                const SizedBox(width: 8),
                Expanded(child: Text(item.$1, style: const TextStyle(fontSize: 13))),
                Text(item.$2, style: TextStyle(fontSize: 12, color: theme.colorScheme.outline)),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildAfter(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    final sections = [
      (
        l10n.ob2AfterUrgent,
        isDark ? AppColors.priorityUrgentDark : AppColors.priorityUrgent,
        [(l10n.ob2AfterTask1, l10n.ob2AfterComment1)],
      ),
      (
        l10n.ob2AfterWarning,
        isDark ? AppColors.priorityWarningDark : AppColors.priorityWarning,
        [(l10n.ob2AfterTask2, l10n.ob2AfterComment2)],
      ),
      (
        l10n.ob2AfterNormal,
        isDark ? AppColors.priorityNormalDark : AppColors.priorityNormal,
        [(l10n.ob2AfterTask3, l10n.ob2AfterComment3)],
      ),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < sections.length; i++) ...[
            if (i > 0) const SizedBox(height: 4),
            _afterSection(theme, sections[i].$1, sections[i].$2, sections[i].$3),
          ],
        ],
      ),
    );
  }

  Widget _afterSection(ThemeData theme, String label, Color color,
      List<(String, String)> tasks) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
        ...tasks.map((t) => Padding(
          padding: const EdgeInsets.only(left: 4, top: 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 3, height: 24,
                margin: const EdgeInsets.only(right: 6),
                decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t.$1, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    Text(t.$2, style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
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

// ─── 画面3: いつやるかが一目でわかる ───
class _Page3Calendar extends StatelessWidget {
  const _Page3Calendar({required this.l10n});
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.colorScheme.outlineVariant),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: ['M', 'T', 'W', 'T', 'F', 'S', 'S']
                      .map((d) => SizedBox(
                            width: 32,
                            child: Text(d, textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 11, color: theme.colorScheme.outline)),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 8),
                _calendarRow(theme, [14, 15, 16, 17, 18, 19, 20],
                    {14: isDark ? AppColors.priorityUrgentDark : AppColors.priorityUrgent,
                     15: isDark ? AppColors.priorityUrgentDark : AppColors.priorityUrgent}, 14),
                const SizedBox(height: 4),
                _calendarRow(theme, [21, 22, 23, 24, 25, 26, 27],
                    {21: isDark ? AppColors.priorityWarningDark : AppColors.priorityWarning,
                     22: isDark ? AppColors.priorityWarningDark : AppColors.priorityWarning}, null),
                const SizedBox(height: 4),
                _calendarRow(theme, [28, 29, 30, 1, 2, 3, 4],
                    {29: isDark ? AppColors.priorityNormalDark : AppColors.priorityNormal,
                     30: isDark ? AppColors.priorityNormalDark : AppColors.priorityNormal,
                     1: isDark ? AppColors.priorityNormalDark : AppColors.priorityNormal}, null),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _legend(isDark ? AppColors.priorityUrgentDark : AppColors.priorityUrgent, l10n.ob3LegendUrgent),
              const SizedBox(width: 12),
              _legend(isDark ? AppColors.priorityWarningDark : AppColors.priorityWarning, l10n.ob3LegendWeek),
              const SizedBox(width: 12),
              _legend(isDark ? AppColors.priorityNormalDark : AppColors.priorityNormal, l10n.ob3LegendLater),
            ],
          ),
          const SizedBox(height: 24),
          Text(l10n.ob3TitleNew,
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _calendarRow(ThemeData theme, List<int> days, Map<int, Color> bars, int? today) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: days.map((d) {
        final isToday = d == today;
        final barColor = bars[d];
        return SizedBox(
          width: 32, height: 36,
          child: Column(
            children: [
              Container(
                width: 22, height: 22,
                decoration: BoxDecoration(
                  color: isToday ? theme.colorScheme.primary.withValues(alpha: 0.15) : null,
                  border: isToday ? Border.all(color: theme.colorScheme.primary, width: 1.5) : null,
                  borderRadius: BorderRadius.circular(11),
                ),
                alignment: Alignment.center,
                child: Text('$d', style: TextStyle(
                  fontSize: 11,
                  fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                  color: isToday ? theme.colorScheme.primary : null,
                )),
              ),
              if (barColor != null)
                Container(
                  height: 4, margin: const EdgeInsets.only(top: 2),
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
          width: 12, height: 4,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

// ─── 画面4: さあ始めよう + サブスク訴求 ───
class _Page4Premium extends StatelessWidget {
  const _Page4Premium({
    required this.l10n,
    required this.onFreeTap,
    required this.onPremiumTap,
  });
  final AppLocalizations l10n;
  final VoidCallback onFreeTap;
  final VoidCallback onPremiumTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // コンパクト比較表（4行に削減）
    final rows = [
      (l10n.ob5AiSort, l10n.ob5FreeAi, l10n.ob5PremiumAi),
      (l10n.ob5Notify, '—', l10n.ob5PremiumNotify),
      (l10n.ob5Calendar, '—', l10n.ob5PremiumCalendar),
      (l10n.ob5Ads, l10n.ob5FreeAds, l10n.ob5PremiumAds),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: SingleChildScrollView(
        child: Column(
          children: [
            Text(l10n.ob4TitleNew,
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center),
            const SizedBox(height: 16),
            // コンパクト比較テーブル
            Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: theme.colorScheme.outlineVariant),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
                      color: theme.colorScheme.surfaceContainerHighest,
                    ),
                    child: Row(
                      children: [
                        const Expanded(flex: 3, child: SizedBox()),
                        Expanded(
                          flex: 2,
                          child: Text(l10n.ob5Free, textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.outline)),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(l10n.premium, textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary)),
                        ),
                      ],
                    ),
                  ),
                  for (var i = 0; i < rows.length; i++) ...[
                    if (i > 0)
                      Divider(height: 1, indent: 12, endIndent: 12,
                          color: theme.colorScheme.outlineVariant),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      child: Row(
                        children: [
                          Expanded(flex: 3,
                              child: Text(rows[i].$1, style: TextStyle(fontSize: 13,
                                  color: theme.colorScheme.onSurfaceVariant))),
                          Expanded(flex: 2,
                              child: Text(rows[i].$2, textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 13, color: theme.colorScheme.outline))),
                          Expanded(flex: 2,
                              child: Text(rows[i].$3, textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                                      color: theme.colorScheme.primary))),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),
            Text(l10n.ob5Price,
                style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onPremiumTap,
                child: Text(l10n.ob5TrialButton),
              ),
            ),
            TextButton(
              onPressed: onFreeTap,
              child: Text(l10n.ob4FreeStart,
                  style: TextStyle(color: theme.colorScheme.outline)),
            ),
          ],
        ),
      ),
    );
  }
}
