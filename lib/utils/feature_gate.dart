import '../services/secure_storage_service.dart';
import 'constants.dart';

/// AI整理の利用可否を判定する
enum AiSortAccess {
  /// そのまま利用可能（無料枠 or プレミアム）
  allowed,
  /// リワード広告を視聴すれば利用可能
  rewardedAdRequired,
  /// 今日は既にリワード広告を使用済み
  rewardedAdUsedToday,
  /// プレミアムの月間上限到達
  premiumMonthlyLimitReached,
}

class FeatureGate {
  FeatureGate._();

  /// AI整理の利用可否を判定
  static Future<AiSortAccess> checkAiSortAccess(
    SecureStorageService secure,
    bool isPremium, {
    bool devAiUnlimited = false,
  }) async {
    if (devAiUnlimited) return AiSortAccess.allowed;

    if (isPremium) {
      final monthKey = SecureStorageService.currentMonthKey(DateTime.now());
      final monthlyCount = await secure.getMonthlyAiUsage(monthKey);
      if (monthlyCount >= AppConstants.premiumAiSortMonthlyLimit) {
        return AiSortAccess.premiumMonthlyLimitReached;
      }
      return AiSortAccess.allowed;
    }

    // 無料ユーザー: 永続2回の無料枠を確認
    final lifetimeUsage = await secure.getLifetimeFreeUsage();
    if (lifetimeUsage < AppConstants.freeAiSortLifetimeLimit) {
      return AiSortAccess.allowed;
    }

    // 無料枠を使い切った → リワード広告で1日1回
    final usedToday = await secure.hasUsedRewardedToday();
    if (usedToday) {
      return AiSortAccess.rewardedAdUsedToday;
    }

    return AiSortAccess.rewardedAdRequired;
  }

  /// AI整理の残り無料回数を取得
  static Future<int> getRemainingFreeCount(
    SecureStorageService secure, {
    bool devAiUnlimited = false,
  }) async {
    if (devAiUnlimited) return 999;
    final used = await secure.getLifetimeFreeUsage();
    final remaining = AppConstants.freeAiSortLifetimeLimit - used;
    return remaining < 0 ? 0 : remaining;
  }
}
