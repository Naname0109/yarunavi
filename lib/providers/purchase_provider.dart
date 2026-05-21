import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/purchase_service.dart';
import '../services/vip_service.dart';
import 'dev_mode_provider.dart';
import 'secure_storage_provider.dart';

/// VipService の Provider (#1)。
final vipServiceProvider = Provider<VipService>((ref) {
  final secure = ref.watch(secureStorageServiceProvider);
  return VipService(secure);
});

/// VIP 有効状態 (起動時にチェック + redeem 後に refresh)。
final isVipProvider = StateProvider<bool>((ref) => false);

/// PurchaseServiceのProvider（main.dartでoverrideされる）
final purchaseServiceProvider = Provider<PurchaseService>((ref) {
  throw UnimplementedError('purchaseServiceProvider must be overridden');
});

/// プレミアム状態を管理するNotifier。
/// dev mode / 正規 IAP / VIP コード のいずれかが true ならプレミアム扱い。
class PremiumNotifier extends Notifier<bool> {
  @override
  bool build() {
    final purchaseService = ref.read(purchaseServiceProvider);
    purchaseService.onPremiumChanged = () {
      _updateState();
    };
    final devPremium = ref.watch(devModePremiumProvider);
    final vipActive = ref.watch(isVipProvider);
    if (devPremium || vipActive) return true;
    return purchaseService.isPremium;
  }

  void _updateState() {
    final purchaseService = ref.read(purchaseServiceProvider);
    final devPremium = ref.read(devModePremiumProvider);
    final vipActive = ref.read(isVipProvider);
    state = devPremium || vipActive || purchaseService.isPremium;
  }

  void refresh() {
    _updateState();
  }
}

final isPremiumProvider =
    NotifierProvider<PremiumNotifier, bool>(PremiumNotifier.new);
