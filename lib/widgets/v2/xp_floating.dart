import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../theme/yaru_colors.dart';
import '../../theme/yaru_theme.dart';

/// "+10 XP" のフローティング上昇テキスト。
///
/// [XpFloatingHost] を画面ツリーに置き、`xpFloatingProvider` の発火を
/// `XpFloatingHost.of(context).show(amount)` で表示する。0.8秒で消える。
class XpFloatingHost extends StatefulWidget {
  const XpFloatingHost({super.key, required this.child});
  final Widget child;

  @override
  State<XpFloatingHost> createState() => XpFloatingHostState();

  static XpFloatingHostState? of(BuildContext context) {
    return context.findAncestorStateOfType<XpFloatingHostState>();
  }
}

class XpFloatingHostState extends State<XpFloatingHost> {
  final _items = <_FloatItem>[];

  void show(int amount) {
    final id = DateTime.now().microsecondsSinceEpoch;
    setState(() => _items.add(_FloatItem(id: id, amount: amount)));
    Future.delayed(const Duration(milliseconds: 850), () {
      if (!mounted) return;
      setState(() => _items.removeWhere((e) => e.id == id));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        IgnorePointer(
          child: Stack(
            alignment: Alignment.topCenter,
            children: [
              for (final item in _items)
                Positioned(
                  top: MediaQuery.of(context).size.height * 0.42,
                  child: _FloatingChip(
                    key: ValueKey(item.id),
                    amount: item.amount,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FloatItem {
  _FloatItem({required this.id, required this.amount});
  final int id;
  final int amount;
}

class _FloatingChip extends StatefulWidget {
  const _FloatingChip({super.key, required this.amount});
  final int amount;

  @override
  State<_FloatingChip> createState() => _FloatingChipState();
}

class _FloatingChipState extends State<_FloatingChip>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _opacity;
  late Animation<Offset> _offset;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _opacity = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 15),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 35),
    ]).animate(_ctrl);
    _offset = Tween(begin: const Offset(0, 0.5), end: const Offset(0, -1.5))
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _scale = TweenSequence([
      TweenSequenceItem(
        tween: Tween(begin: 0.6, end: 1.15)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.15, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 70,
      ),
    ]).animate(_ctrl);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final yaru = context.yaru;
    final l10n = AppLocalizations.of(context)!;
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) {
        return Opacity(
          opacity: _opacity.value,
          child: FractionalTranslation(
            translation: _offset.value,
            child: Transform.scale(
              scale: _scale.value,
              child: child,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          gradient: yaru.primaryGradient,
          borderRadius: BorderRadius.circular(999),
          boxShadow: [
            BoxShadow(
              color: yaru.accent.withValues(alpha: 0.5),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Text(
          l10n.xpEarned(widget.amount),
          style: TextStyle(
            color: yaru.useGlassBlur ? YaruColors.bgDark0 : Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w800,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ),
    );
  }
}
