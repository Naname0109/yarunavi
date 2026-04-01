import 'package:flutter/foundation.dart';

import '../services/ad_service.dart';
import '../services/database_service.dart';
import '../utils/date_utils.dart' as app_date;
import 'constants.dart';

class FeatureGate {
  FeatureGate._();

  /// AI整理が利用可能かチェック
  static Future<bool> canUseAiSort(
      DatabaseService db, bool isPremium) async {
    if (kDebugMode) return true;

    if (isPremium) {
      final todayStr = app_date.formatDateForDb(DateTime.now());
      final dailyCount = await db.getDailyAiUsageCount(todayStr);
      return dailyCount < AppConstants.premiumAiSortDailyLimit;
    }

    // リワード解除中なら制限無視
    if (await AdService.isRewardUnlocked()) return true;

    final remaining = await getRemainingAiSortCount(db, isPremium);
    return remaining > 0;
  }

  /// AI整理の残り回数を取得
  static Future<int> getRemainingAiSortCount(
      DatabaseService db, bool isPremium) async {
    if (kDebugMode) return 999;

    if (isPremium) {
      final todayStr = app_date.formatDateForDb(DateTime.now());
      final dailyCount = await db.getDailyAiUsageCount(todayStr);
      final remaining =
          AppConstants.premiumAiSortDailyLimit - dailyCount;
      return remaining < 0 ? 0 : remaining;
    } else {
      final now = DateTime.now();
      final monthKey =
          '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}';
      final monthlyCount = await db.getMonthlyAiUsageCount(monthKey);
      final remaining =
          AppConstants.freeAiSortMonthlyLimit - monthlyCount;
      return remaining < 0 ? 0 : remaining;
    }
  }

  /// リワード広告表示が可能か（2日目以降 + 非プレミアム）
  static Future<bool> canShowRewardAd(bool isPremium) async {
    if (isPremium) return false;
    return AdService.isAfterFirstDay();
  }
}
