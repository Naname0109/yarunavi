import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/generated/app_localizations.dart';

/// 1ステップ分のコーチマーク設定
class CoachStep {
  final GlobalKey targetKey;
  final String message;
  const CoachStep({required this.targetKey, required this.message});
}

/// SharedPreferences の表示済みフラグキー
const _coachMarksShownKey = 'coachmarks_shown';

/// ホーム画面初回などで呼び出してコーチマークを順次表示する。
Future<void> maybeShowCoachMarks(
  BuildContext context, {
  required List<CoachStep> steps,
}) async {
  final prefs = await SharedPreferences.getInstance();
  if (prefs.getBool(_coachMarksShownKey) == true) return;
  if (!context.mounted) return;

  for (final step in steps) {
    if (!context.mounted) return;
    final isLast = step == steps.last;
    await _showSingleCoach(context, step, isLast);
  }
  await prefs.setBool(_coachMarksShownKey, true);
}

Future<void> _showSingleCoach(
  BuildContext context,
  CoachStep step,
  bool isLast,
) async {
  // ターゲット位置を計算
  final renderObject = step.targetKey.currentContext?.findRenderObject();
  if (renderObject is! RenderBox || !renderObject.hasSize) return;
  final targetSize = renderObject.size;
  final targetTopLeft = renderObject.localToGlobal(Offset.zero);
  final targetRect = targetTopLeft & targetSize;

  await showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'coach',
    barrierColor: Colors.black.withValues(alpha: 0.6),
    transitionDuration: const Duration(milliseconds: 200),
    pageBuilder: (ctx, a1, a2) {
      final l10n = AppLocalizations.of(ctx)!;
      final mq = MediaQuery.of(ctx);
      // 吹き出しは対象の上 or 下に配置(画面中央より上なら下に出す)
      final showBelow = targetRect.center.dy < mq.size.height / 2;
      final bubbleTop = showBelow
          ? targetRect.bottom + 16
          : targetRect.top - 110;

      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => Navigator.of(ctx).pop(),
        child: Stack(
          children: [
            // ターゲットをハイライト(白枠)
            Positioned(
              left: targetRect.left - 6,
              top: targetRect.top - 6,
              width: targetRect.width + 12,
              height: targetRect.height + 12,
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white, width: 2.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            // 吹き出し
            Positioned(
              left: 24,
              right: 24,
              top: bubbleTop.clamp(24.0, mq.size.height - 140),
              child: Material(
                color: Colors.transparent,
                child: Card(
                  color: Colors.white,
                  elevation: 6,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          step.message,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            child: Text(isLast ? l10n.coachDone : l10n.coachNext),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

/// 設定の「操作ガイドを再表示」用: フラグをリセット
Future<void> resetCoachMarksFlag() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_coachMarksShownKey, false);
}
