import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/purchase_service.dart';

/// PurchaseServiceのProvider（main.dartでoverrideされる）
final purchaseServiceProvider = Provider<PurchaseService>((ref) {
  throw UnimplementedError('purchaseServiceProvider must be overridden');
});

/// プレミアム状態を管理するNotifier
class PremiumNotifier extends Notifier<bool> {
  @override
  bool build() {
    final purchaseService = ref.read(purchaseServiceProvider);
    // PurchaseServiceの状態変更を監視
    purchaseService.onPremiumChanged = () {
      state = purchaseService.isPremium;
    };
    return purchaseService.isPremium;
  }

  void refresh() {
    final purchaseService = ref.read(purchaseServiceProvider);
    state = purchaseService.isPremium;
  }
}

final isPremiumProvider =
    NotifierProvider<PremiumNotifier, bool>(PremiumNotifier.new);
