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
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // プレミアム登録済みバッジ
              if (isPremium) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: theme.colorScheme.primary,
                      ),
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
                const SizedBox(height: 24),
              ],

              // プレミアム機能一覧
              _buildFeatureCard(context, l10n),

              const SizedBox(height: 24),

              // 価格ボタン（非プレミアム時のみ）
              if (!isPremium) ...[
                if (!purchaseService.isStoreAvailable) ...[
                  // ストア未接続時
                  Text(
                    l10n.storeStoreUnavailable,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ] else ...[
                  _buildPriceButtons(context, l10n, purchaseService),
                  const SizedBox(height: 16),

                  // 自動更新警告（オレンジ太字14sp、WCAG AA対応）
                  Text(
                    l10n.storeAutoRenewWarning1,
                    style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFFFF9E5C)
                          : const Color(0xFFC75000),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.storeAutoRenewWarning2,
                    style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFFFF9E5C)
                          : const Color(0xFFC75000),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 24),

                  // 購入を復元ボタン
                  OutlinedButton(
                    onPressed: () => _restorePurchases(l10n, purchaseService),
                    child: Text(l10n.storeRestore),
                  ),
                ],
              ],

              const SizedBox(height: 24),

              // 利用規約リンク
              _buildLegalLink(
                context,
                l10n.termsOfUse,
                AppConstants.termsOfUseUrl,
              ),
              const SizedBox(height: 8),
              // プライバシーポリシーリンク
              _buildLegalLink(
                context,
                l10n.privacyPolicy,
                AppConstants.privacyPolicyUrl,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard(BuildContext context, AppLocalizations l10n) {
    final features = [
      (Icons.auto_awesome, l10n.storeFeatureAiUnlimited),
      (Icons.task_alt, l10n.storeFeatureTaskUnlimited),
      (Icons.repeat, l10n.storeFeatureRecurringUnlimited),
      (Icons.category, l10n.storeFeatureCategoryUnlimited),
      (Icons.calendar_month, l10n.storeFeatureCalendar),
      (Icons.notifications_active, l10n.storeFeatureNotification),
      (Icons.block, l10n.storeFeatureNoAds),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: features.map((feature) {
            final (icon, text) = feature;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Icon(icon,
                      size: 20,
                      color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 12),
                  Expanded(child: Text(text)),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildPriceButtons(
    BuildContext context,
    AppLocalizations l10n,
    PurchaseService purchaseService,
  ) {
    // 商品情報があればストアの価格を使用、なければハードコードでフォールバック
    final monthlyPrice =
        purchaseService.monthlyProduct?.price ?? l10n.storeMonthlyPrice;
    final yearlyPrice =
        purchaseService.yearlyProduct?.price ?? l10n.storeYearlyPrice;

    return Column(
      children: [
        // 月額ボタン
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () => _purchaseMonthly(l10n, purchaseService),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: Text(
              monthlyPrice,
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          l10n.storeMonthlyTrial,
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 16),

        // 年額ボタン
        SizedBox(
          width: double.infinity,
          child: FilledButton.tonal(
            onPressed: () => _purchaseYearly(l10n, purchaseService),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: Text(
              yearlyPrice,
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          l10n.storeYearlyTrial,
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildLegalLink(BuildContext context, String text, String url) {
    final linkColor = Theme.of(context).colorScheme.primary;
    return InkWell(
      onTap: () => launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      ),
      child: Text(
        text,
        style: TextStyle(
          color: linkColor,
          decoration: TextDecoration.underline,
          decorationColor: linkColor,
        ),
        textAlign: TextAlign.center,
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
