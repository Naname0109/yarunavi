import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/purchase_service.dart';
import 'dev_mode_provider.dart';

/// PurchaseServiceのProvider（main.dartでoverrideされる）
final purchaseServiceProvider = Provider<PurchaseService>((ref) {
  throw UnimplementedError('purchaseServiceProvider must be overridden');
});

/// プレミアム状態を管理するNotifier
class PremiumNotifier extends Notifier<bool> {
  @override
  bool build() {
    final purchaseService = ref.read(purchaseServiceProvider);
    purchaseService.onPremiumChanged = () {
      _updateState();
    };
    // 開発者モードのプレミアムトグルを監視
    final devPremium = ref.watch(devModePremiumProvider);
    if (devPremium) return true;
    return purchaseService.isPremium;
  }

  void _updateState() {
    final purchaseService = ref.read(purchaseServiceProvider);
    final devPremium = ref.read(devModePremiumProvider);
    if (devPremium) {
      state = true;
    } else {
      state = purchaseService.isPremium;
    }
  }

  void refresh() {
    _updateState();
  }
}

final isPremiumProvider =
    NotifierProvider<PremiumNotifier, bool>(PremiumNotifier.new);
