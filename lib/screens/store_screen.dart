import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/generated/app_localizations.dart';
import '../providers/purchase_provider.dart';
import '../services/purchase_service.dart';
import '../utils/constants.dart';
import '../widgets/responsive_wrapper.dart';

class StoreScreen extends ConsumerStatefulWidget {
  const StoreScreen({super.key});

  @override
  ConsumerState<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends ConsumerState<StoreScreen> {
  late final PurchaseService _purchaseService;

  @override
  void initState() {
    super.initState();
    _purchaseService = ref.read(purchaseServiceProvider);
    _purchaseService.onPurchaseEvent = _onPurchaseEvent;
  }

  @override
  void dispose() {
    _purchaseService.onPurchaseEvent = null;
    super.dispose();
  }

  void _onPurchaseEvent(PurchaseEvent event) {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    switch (event) {
      case PurchaseEvent.purchased:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.storePurchaseSuccess)),
        );
      case PurchaseEvent.restored:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.storeRestoreSuccess)),
        );
      case PurchaseEvent.error:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.storePurchaseFailed)),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isPremium = ref.watch(isPremiumProvider);
    final purchaseService = ref.read(purchaseServiceProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.storePremiumTitle),
      ),
      body: ResponsiveWrapper(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ヘッダー (アイコン + タイトル)
              Column(
                children: [
                  Icon(Icons.workspace_premium,
                      size: 48, color: theme.colorScheme.primary),
                  const SizedBox(height: 8),
                  Text(
                    l10n.storePremiumTitle,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // プレミアム登録済みバッジ
              if (isPremium) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle,
                          color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        l10n.storeAlreadyPremium,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // プレミアム機能一覧
              _buildFeatureCard(context, l10n),

              const SizedBox(height: 20),

              // プランカード（非プレミアム時のみ）
              if (!isPremium) ...[
                if (!purchaseService.isStoreAvailable) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      l10n.storeStoreUnavailable,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ] else ...[
                  _buildMonthlyCard(context, l10n, purchaseService),
                  const SizedBox(height: 12),
                  _buildYearlyCard(context, l10n, purchaseService),
                  const SizedBox(height: 16),

                  // 注意書き: 控えめなグレーで小さく
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      children: [
                        Text(
                          l10n.storeAutoRenewWarning1,
                          style: TextStyle(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontSize: 12,
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          l10n.storeAutoRenewWarning2,
                          style: TextStyle(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontSize: 12,
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],
              ],

              const SizedBox(height: 24),

              // フッター: 復元 + 規約リンク
              if (!isPremium && purchaseService.isStoreAvailable)
                Center(
                  child: TextButton(
                    onPressed: () =>
                        _restorePurchases(l10n, purchaseService),
                    child: Text(l10n.storeRestore),
                  ),
                ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildLegalLink(
                      context, l10n.termsOfUse, AppConstants.termsOfUseUrl),
                  Text(
                    '  |  ',
                    style: TextStyle(color: theme.colorScheme.outline),
                  ),
                  _buildLegalLink(context, l10n.privacyPolicy,
                      AppConstants.privacyPolicyUrl),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard(BuildContext context, AppLocalizations l10n) {
    final theme = Theme.of(context);
    final features = [
      (Icons.auto_awesome, l10n.storeFeatureAiUnlimited),
      (Icons.task_alt, l10n.storeFeatureTaskUnlimited),
      (Icons.repeat, l10n.storeFeatureRecurringUnlimited),
      (Icons.category_outlined, l10n.storeFeatureCategoryUnlimited),
      (Icons.calendar_month_outlined, l10n.storeFeatureCalendar),
      (Icons.notifications_active_outlined, l10n.storeFeatureNotification),
      (Icons.block, l10n.storeFeatureNoAds),
    ];

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Column(
          children: features.map((feature) {
            final (icon, text) = feature;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Icon(icon, size: 22, color: theme.colorScheme.primary),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      text,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  /// 月額プランカード
  Widget _buildMonthlyCard(
    BuildContext context,
    AppLocalizations l10n,
    PurchaseService purchaseService,
  ) {
    final theme = Theme.of(context);
    // StoreKitから取得した価格を優先、なければフォールバック
    final monthlyPrice =
        purchaseService.monthlyProduct?.price ?? l10n.storeMonthlyPrice;

    return _PlanCard(
      onTap: () => _purchaseMonthly(l10n, purchaseService),
      borderColor: theme.colorScheme.outlineVariant,
      borderWidth: 1.0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.storeMonthlyPlanTitle,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              monthlyPrice,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.storeMonthlyTrial,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 年額プランカード（おすすめバッジ付き）
  Widget _buildYearlyCard(
    BuildContext context,
    AppLocalizations l10n,
    PurchaseService purchaseService,
  ) {
    final theme = Theme.of(context);
    final yearlyPrice =
        purchaseService.yearlyProduct?.price ?? l10n.storeYearlyPrice;

    return _PlanCard(
      onTap: () => _purchaseYearly(l10n, purchaseService),
      borderColor: theme.colorScheme.primary,
      borderWidth: 2.0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 「おすすめ」バッジ (カード内上部)
            // primary は ライト=#2453FF(濃青) / ダーク=#4DF5FF(明シアン)。
            // ダーク時に white テキストでは contrast 不足のため、onPrimary を使用。
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.star, size: 12, color: theme.colorScheme.onPrimary),
                  const SizedBox(width: 4),
                  Text(
                    l10n.storeRecommended,
                    style: TextStyle(
                      color: theme.colorScheme.onPrimary,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              l10n.storeYearlyPlanTitle,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  yearlyPrice,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              l10n.storeYearlySub,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.storeYearlyTrial,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegalLink(BuildContext context, String text, String url) {
    final linkColor = Theme.of(context).colorScheme.primary;
    return InkWell(
      onTap: () => launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text(
          text,
          style: TextStyle(
            color: linkColor,
            fontSize: 13,
            decoration: TextDecoration.underline,
            decorationColor: linkColor,
          ),
        ),
      ),
    );
  }

  Future<void> _purchaseMonthly(
    AppLocalizations l10n,
    PurchaseService purchaseService,
  ) async {
    final started = await purchaseService.purchaseMonthly();
    if (!started && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.storePurchaseFailed)),
      );
    }
  }

  Future<void> _purchaseYearly(
    AppLocalizations l10n,
    PurchaseService purchaseService,
  ) async {
    final started = await purchaseService.purchaseYearly();
    if (!started && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.storePurchaseFailed)),
      );
    }
  }

  Future<void> _restorePurchases(
    AppLocalizations l10n,
    PurchaseService purchaseService,
  ) async {
    // 復元結果はpurchaseStreamのイベントで_onPurchaseEventに通知される
    await purchaseService.restorePurchases();
  }
}

/// プランカード共通ベース (ボーダー + InkWell)
class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.onTap,
    required this.borderColor,
    required this.borderWidth,
    required this.child,
  });

  final VoidCallback onTap;
  final Color borderColor;
  final double borderWidth;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      elevation: 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: borderWidth),
          ),
          child: child,
        ),
      ),
    );
  }
}
