import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/generated/app_localizations.dart';
import '../providers/purchase_provider.dart';
import '../theme/yaru_theme.dart';
import '../utils/constants.dart';

/// AI 整理ボタン押下時に「無料回数なし + チケットなし」 を検出した際に
/// 表示する購入案内シート。 ユーザーが選んだ手段を返す。
enum AiPurchaseChoice { premium, ticket, rewarded }

class AiPurchaseBottomSheet extends ConsumerWidget {
  const AiPurchaseBottomSheet._({
    required this.rewardedAvailable,
    required this.ticketLifetime,
    required this.rewardedTotalUsed,
  });

  final bool rewardedAvailable;
  final int ticketLifetime;
  final int rewardedTotalUsed; // #4: 生涯使用済み回数 (0-2)

  static Future<AiPurchaseChoice?> show(
    BuildContext context, {
    required bool rewardedAvailable,
    required int ticketLifetime,
    required int rewardedTotalUsed,
  }) {
    return showModalBottomSheet<AiPurchaseChoice>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AiPurchaseBottomSheet._(
        rewardedAvailable: rewardedAvailable,
        ticketLifetime: ticketLifetime,
        rewardedTotalUsed: rewardedTotalUsed,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final yaru = context.yaru;
    final l10n = AppLocalizations.of(context)!;
    final remainingTickets =
        AppConstants.kAiTicketMaxLifetimePurchases - ticketLifetime;
    final ticketDisabled = remainingTickets <= 0;
    // #2: StoreKit のローカライズ済価格を優先、 fallback は arb
    final purchaseService = ref.read(purchaseServiceProvider);
    final monthlyPrice =
        purchaseService.monthlyProduct?.price ?? l10n.storeMonthlyPrice;
    final ticketPrice =
        purchaseService.aiTicketProduct?.price ?? '¥120';

    return SafeArea(
      child: Container(
        decoration: BoxDecoration(
          color: yaru.scaffoldBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(
            top: BorderSide(color: yaru.line, width: 1),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: yaru.line,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // #5: タイトル + 説明を構造化 (左寄せ、 行が長くて折り返す現象を回避)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.aiPurchaseSheetTitle,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: yaru.inkPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.aiPurchaseSheetBody,
                    style: TextStyle(
                      fontSize: 14,
                      color: yaru.inkSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // #4: 全枯渇時はプレミアム推し
            Builder(builder: (ctx) {
              final rewardedDisabled = rewardedTotalUsed >=
                  AppConstants.kRewardedAdMaxLifetime;
              final allExhausted = rewardedDisabled && ticketDisabled;
              final remainingRewarded = AppConstants.kRewardedAdMaxLifetime -
                  rewardedTotalUsed;
              return Column(
                children: [
                  _OptionTile(
                    icon: Icons.workspace_premium_rounded,
                    iconColor: yaru.accent,
                    title:
                        '${l10n.aiPurchasePremiumLabel} $monthlyPrice',
                    subtitle: l10n.aiPurchasePremiumSubtitle,
                    highlight: allExhausted,
                    onTap: () => Navigator.of(context)
                        .pop(AiPurchaseChoice.premium),
                  ),
                  const SizedBox(height: 8),
                  _OptionTile(
                    icon: Icons.confirmation_number_outlined,
                    iconColor:
                        ticketDisabled ? yaru.inkQuaternary : yaru.accent,
                    title:
                        '${l10n.aiPurchaseTicketLabel} $ticketPrice',
                    subtitle: ticketDisabled
                        ? l10n.aiPurchaseTicketDisabled
                        : l10n.aiPurchaseTicketSubtitle(
                            remainingTickets,
                            AppConstants
                                .kAiTicketMaxLifetimePurchases,
                          ),
                    enabled: !ticketDisabled,
                    onTap: ticketDisabled
                        ? null
                        : () => Navigator.of(context)
                            .pop(AiPurchaseChoice.ticket),
                  ),
                  if (rewardedAvailable || rewardedDisabled) ...[
                    const SizedBox(height: 8),
                    _OptionTile(
                      icon: Icons.movie_filter_rounded,
                      iconColor: rewardedDisabled
                          ? yaru.inkQuaternary
                          : yaru.accent,
                      title: l10n.aiPurchaseRewardedTitle,
                      subtitle: rewardedDisabled
                          ? l10n.aiRewardedExhausted
                          : l10n.aiRewardedRemaining(remainingRewarded,
                              AppConstants.kRewardedAdMaxLifetime),
                      enabled: !rewardedDisabled,
                      onTap: rewardedDisabled
                          ? null
                          : () => Navigator.of(context)
                              .pop(AiPurchaseChoice.rewarded),
                    ),
                  ],
                  if (allExhausted) ...[
                    const SizedBox(height: 12),
                    Text(
                      l10n.aiPremiumRequiredNote,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: yaru.accent,
                      ),
                    ),
                  ],
                ],
              );
            }),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.cancel),
            ),
          ],
        ),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.enabled = true,
    this.highlight = false,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool enabled;
  final bool highlight; // #4: 「おすすめ」 強調 (枯渇時に premium カード)

  @override
  Widget build(BuildContext context) {
    final yaru = context.yaru;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: yaru.paperEmph,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: highlight
                  ? iconColor
                  : (enabled ? iconColor.withValues(alpha: 0.35) : yaru.line),
              width: highlight ? 2 : 1,
            ),
          ),
          child: Opacity(
            opacity: enabled ? 1.0 : 0.5,
            child: Row(
              children: [
                Icon(icon, color: iconColor, size: 26),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          color: yaru.inkPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: yaru.inkSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: yaru.inkTertiary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
