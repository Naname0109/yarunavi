import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../theme/yaru_theme.dart';
import '../utils/constants.dart';

/// AI 整理ボタン押下時に「無料回数なし + チケットなし」 を検出した際に
/// 表示する購入案内シート。 ユーザーが選んだ手段を返す。
enum AiPurchaseChoice { premium, ticket, rewarded }

class AiPurchaseBottomSheet extends StatelessWidget {
  const AiPurchaseBottomSheet._({
    required this.rewardedAvailable,
    required this.ticketLifetime,
  });

  final bool rewardedAvailable;
  final int ticketLifetime;

  static Future<AiPurchaseChoice?> show(
    BuildContext context, {
    required bool rewardedAvailable,
    required int ticketLifetime,
  }) {
    return showModalBottomSheet<AiPurchaseChoice>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AiPurchaseBottomSheet._(
        rewardedAvailable: rewardedAvailable,
        ticketLifetime: ticketLifetime,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final yaru = context.yaru;
    final l10n = AppLocalizations.of(context)!;
    final remainingTickets =
        AppConstants.kAiTicketMaxLifetimePurchases - ticketLifetime;
    final ticketDisabled = remainingTickets <= 0;

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
            Text(
              l10n.aiPurchaseSheetTitle,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: yaru.inkPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              l10n.aiPurchaseSheetBody,
              style: TextStyle(fontSize: 12.5, color: yaru.inkSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 14),
            _OptionTile(
              icon: Icons.workspace_premium_rounded,
              iconColor: yaru.accent,
              title: l10n.aiPurchasePremiumTitle,
              subtitle: l10n.aiPurchasePremiumSubtitle,
              onTap: () =>
                  Navigator.of(context).pop(AiPurchaseChoice.premium),
            ),
            const SizedBox(height: 8),
            _OptionTile(
              icon: Icons.confirmation_number_outlined,
              iconColor: ticketDisabled ? yaru.inkQuaternary : yaru.accent,
              title: l10n.aiPurchaseTicketTitle,
              subtitle: ticketDisabled
                  ? l10n.aiPurchaseTicketDisabled
                  : l10n.aiPurchaseTicketSubtitle(
                      remainingTickets,
                      AppConstants.kAiTicketMaxLifetimePurchases,
                    ),
              enabled: !ticketDisabled,
              onTap: ticketDisabled
                  ? null
                  : () => Navigator.of(context).pop(AiPurchaseChoice.ticket),
            ),
            if (rewardedAvailable) ...[
              const SizedBox(height: 8),
              _OptionTile(
                icon: Icons.movie_filter_rounded,
                iconColor: yaru.accent,
                title: l10n.aiPurchaseRewardedTitle,
                subtitle: l10n.aiPurchaseRewardedSubtitle,
                onTap: () =>
                    Navigator.of(context).pop(AiPurchaseChoice.rewarded),
              ),
            ],
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
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool enabled;

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
              color: enabled
                  ? iconColor.withValues(alpha: 0.35)
                  : yaru.line,
              width: 1,
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
