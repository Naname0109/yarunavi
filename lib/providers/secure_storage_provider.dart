import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/secure_storage_service.dart';
import '../utils/constants.dart';
import 'dev_mode_provider.dart';
import 'purchase_provider.dart' show isPremiumProvider, isVipProvider;
import 'task_provider.dart';

/// SecureStorageService の Provider (main.dart で override される)
final secureStorageServiceProvider = Provider<SecureStorageService>((ref) {
  throw UnimplementedError('secureStorageServiceProvider must be overridden');
});

/// AI整理の残り回数と上限を取得する。
/// - 無料: free 残り (= freeAiSortLifetimeLimit + rewarded_used - lifetimeUsage)
///   + ai_ticket_count を加算した合算残数
/// - プレミアム: 残り = premiumAiSortMonthlyLimit (30) - 今月使用回数
/// - VIP: 残り = -1 (無制限フラグ)、 total = 0
/// - 開発者モード(無制限): premium=true, remaining = 999
///
/// tasksProvider への変更 (AI整理完了時に invalidateSelf) で連動再取得。
final aiSortQuotaProvider =
    FutureProvider<({int remaining, int total, bool isPremium})>((ref) async {
  ref.watch(tasksProvider);
  final secure = ref.read(secureStorageServiceProvider);
  final isPremium = ref.read(isPremiumProvider);
  final devUnlimited = ref.read(devModeAiUnlimitedProvider);
  final isVip = ref.read(isVipProvider);

  if (devUnlimited) {
    return (remaining: 999, total: 999, isPremium: true);
  }
  if (isVip) {
    // VIP は無制限のため remaining=-1 を「VIP 無制限」 マーカーとして扱う。
    // VIP がチケット (ai_ticket_count) を保有している場合でも UI には
    // 表示しない (= 「VIP 無制限」 のみ)。 在庫は内部保持され、
    // VIP 解除時に再び有効化される設計。
    return (remaining: -1, total: 0, isPremium: true);
  }

  if (isPremium) {
    final monthKey = SecureStorageService.currentMonthKey(DateTime.now());
    final used = await secure.getMonthlyAiUsage(monthKey);
    final total = AppConstants.premiumAiSortMonthlyLimit;
    final remaining = (total - used).clamp(0, total);
    return (remaining: remaining, total: total, isPremium: true);
  }

  // #4 無料: free 残 + チケット在庫
  final freeUsed = await secure.getLifetimeFreeUsage();
  final rewardedUsed = await secure.getRewardedTotalUsed();
  final freeCap = AppConstants.freeAiSortLifetimeLimit + rewardedUsed;
  final freeRemaining = (freeCap - freeUsed).clamp(0, freeCap);
  final tickets = await secure.getAiTicketsAvailable();
  final remaining = freeRemaining + tickets;
  return (remaining: remaining, total: freeCap + tickets, isPremium: false);
});
