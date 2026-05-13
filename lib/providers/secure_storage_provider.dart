import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/secure_storage_service.dart';
import '../utils/constants.dart';
import 'dev_mode_provider.dart';
import 'purchase_provider.dart';
import 'task_provider.dart';

/// SecureStorageService の Provider (main.dart で override される)
final secureStorageServiceProvider = Provider<SecureStorageService>((ref) {
  throw UnimplementedError('secureStorageServiceProvider must be overridden');
});

/// AI整理の残り回数と上限を取得する。
/// - 無料ユーザー: 残り = freeAiSortLifetimeLimit (2) - 永続使用回数
/// - プレミアム: 残り = premiumAiSortMonthlyLimit (30) - 今月使用回数
/// - 開発者モード(無制限): premium=true, remaining = 999
///
/// tasksProvider への変更 (AI整理完了時に invalidateSelf) で連動再取得。
final aiSortQuotaProvider =
    FutureProvider<({int remaining, int total, bool isPremium})>((ref) async {
  // AI整理完了で使用回数が変わるため、tasksProvider を watch して連動
  ref.watch(tasksProvider);
  final secure = ref.read(secureStorageServiceProvider);
  final isPremium = ref.read(isPremiumProvider);
  final devUnlimited = ref.read(devModeAiUnlimitedProvider);

  if (devUnlimited) {
    return (remaining: 999, total: 999, isPremium: isPremium);
  }

  if (isPremium) {
    final monthKey = SecureStorageService.currentMonthKey(DateTime.now());
    final used = await secure.getMonthlyAiUsage(monthKey);
    final total = AppConstants.premiumAiSortMonthlyLimit;
    final remaining = (total - used).clamp(0, total);
    return (remaining: remaining, total: total, isPremium: true);
  }

  final used = await secure.getLifetimeFreeUsage();
  final total = AppConstants.freeAiSortLifetimeLimit;
  final remaining = (total - used).clamp(0, total);
  return (remaining: remaining, total: total, isPremium: false);
});
