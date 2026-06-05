import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../theme/yaru_theme.dart';

/// #3: AI 整理中に表示する Tips カード。
/// - 6 秒ごとに次の Tip にクロスフェード
/// - 完了演出開始 (progress >= 0.9) 時に opacity 0 へフェードアウト
class AiSortTipsCard extends StatefulWidget {
  const AiSortTipsCard({super.key, required this.progress});

  /// 現在のプログレス (0.0〜1.0)。 0.9 以上で自動的に非表示化。
  final double progress;

  @override
  State<AiSortTipsCard> createState() => _AiSortTipsCardState();
}

class _AiSortTipsCardState extends State<AiSortTipsCard> {
  Timer? _timer;
  int _index = 0;
  late final List<int> _shuffledIds;

  @override
  void initState() {
    super.initState();
    final ids = List.generate(21, (i) => i);
    ids.shuffle(Random());
    _shuffledIds = ids;
    _timer = Timer.periodic(const Duration(seconds: 6), (_) {
      if (!mounted) return;
      if (widget.progress >= 0.9) return; // 完了直前は切り替えない
      setState(() {
        _index = (_index + 1) % _shuffledIds.length;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _tipText(AppLocalizations l10n, int id) {
    return switch (id) {
      0 => l10n.tip0,
      1 => l10n.tip1,
      2 => l10n.tip2,
      3 => l10n.tip3,
      4 => l10n.tip4,
      5 => l10n.tip5,
      6 => l10n.tip6,
      7 => l10n.tip7,
      8 => l10n.tip8,
      9 => l10n.tip9,
      10 => l10n.tip10,
      11 => l10n.tip11,
      12 => l10n.tip12,
      13 => l10n.tip13,
      14 => l10n.tip14,
      15 => l10n.tip15,
      16 => l10n.tip16,
      17 => l10n.tip17,
      18 => l10n.tip18,
      19 => l10n.tip19,
      20 => l10n.tip20,
      _ => l10n.tip0,
    };
  }

  /// 各 Tip のタイトル (Tips: xxx)。 切替時に body と一緒にアニメーション。
  String _tipTitle(AppLocalizations l10n, int id) {
    return switch (id) {
      0 => l10n.tip0Title,
      1 => l10n.tip1Title,
      2 => l10n.tip2Title,
      3 => l10n.tip3Title,
      4 => l10n.tip4Title,
      5 => l10n.tip5Title,
      6 => l10n.tip6Title,
      7 => l10n.tip7Title,
      8 => l10n.tip8Title,
      9 => l10n.tip9Title,
      10 => l10n.tip10Title,
      11 => l10n.tip11Title,
      12 => l10n.tip12Title,
      13 => l10n.tip13Title,
      14 => l10n.tip14Title,
      15 => l10n.tip15Title,
      16 => l10n.tip16Title,
      17 => l10n.tip17Title,
      18 => l10n.tip18Title,
      19 => l10n.tip19Title,
      20 => l10n.tip20Title,
      _ => l10n.tip0Title,
    };
  }

  @override
  Widget build(BuildContext context) {
    final yaru = context.yaru;
    final l10n = AppLocalizations.of(context)!;
    final visible = widget.progress < 0.9;
    final currentId = _shuffledIds[_index];
    final title = _tipTitle(l10n, currentId);
    final body = _tipText(l10n, currentId);
    final primary = Theme.of(context).colorScheme.primary;

    return AnimatedOpacity(
      opacity: visible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 300),
      child: visible
          ? Container(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              decoration: BoxDecoration(
                color: yaru.paperEmph,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: yaru.line, width: 1),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.lightbulb_outline,
                      size: 16, color: Colors.amber.shade600),
                  const SizedBox(width: 8),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 500),
                      switchInCurve: Curves.easeOut,
                      switchOutCurve: Curves.easeIn,
                      transitionBuilder: (child, anim) {
                        final slide = Tween<Offset>(
                          begin: const Offset(0, 0.15),
                          end: Offset.zero,
                        ).animate(anim);
                        return FadeTransition(
                          opacity: anim,
                          child: SlideTransition(
                              position: slide, child: child),
                        );
                      },
                      child: Column(
                        key: ValueKey<int>(currentId),
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: primary,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            body,
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.5,
                              color: yaru.inkSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            )
          : const SizedBox.shrink(),
    );
  }
}
