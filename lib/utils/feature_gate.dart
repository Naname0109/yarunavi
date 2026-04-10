import '../services/secure_storage_service.dart';
import 'constants.dart';

class FeatureGate {
  FeatureGate._();

  /// AI整理が利用可能かチェック
  /// [devAiUnlimited] は開発者モードトグル
  static Future<bool> canUseAiSort(
    SecureStorageService secure,
    bool isPremium, {
    bool devAiUnlimited = false,
  }) async {
    if (devAiUnlimited) return true;

    final monthKey = SecureStorageService.currentMonthKey(DateTime.now());
    final monthlyCount = await secure.getMonthlyAiUsage(monthKey);
    final limit = isPremium
        ? AppConstants.premiumAiSortMonthlyLimit
        : AppConstants.freeAiSortMonthlyLimit;
    return monthlyCount < limit;
  }

  /// AI整理の残り回数を取得
  static Future<int> getRemainingAiSortCount(
    SecureStorageService secure,
    bool isPremium, {
    bool devAiUnlimited = false,
  }) async {
    if (devAiUnlimited) return 999;

    final monthKey = SecureStorageService.currentMonthKey(DateTime.now());
    final monthlyCount = await secure.getMonthlyAiUsage(monthKey);
    final limit = isPremium
        ? AppConstants.premiumAiSortMonthlyLimit
        : AppConstants.freeAiSortMonthlyLimit;
    final remaining = limit - monthlyCount;
    return remaining < 0 ? 0 : remaining;
  }
}
