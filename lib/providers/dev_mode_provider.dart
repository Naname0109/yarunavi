import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _aiUnlimitedKey = 'dev_mode_ai_unlimited';
const _premiumKey = 'dev_mode_premium';

/// 起動時の初期値（main.dartでoverrideされる）
final initialDevAiUnlimitedProvider = Provider<bool>((ref) => false);
final initialDevPremiumProvider = Provider<bool>((ref) => false);

/// 起動時にSharedPreferencesから読み込む
Future<({bool aiUnlimited, bool premium})> loadDevModePrefs() async {
  final prefs = await SharedPreferences.getInstance();
  return (
    aiUnlimited: prefs.getBool(_aiUnlimitedKey) ?? false,
    premium: prefs.getBool(_premiumKey) ?? false,
  );
}

/// 開発者モード: AI回数制限を無視
final devModeAiUnlimitedProvider =
    NotifierProvider<DevModeAiUnlimitedNotifier, bool>(
  DevModeAiUnlimitedNotifier.new,
);

class DevModeAiUnlimitedNotifier extends Notifier<bool> {
  @override
  bool build() => ref.read(initialDevAiUnlimitedProvider);

  Future<void> toggle(bool value) async {
    state = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_aiUnlimitedKey, value);
  }
}

/// 開発者モード: プレミアム機能を解放
final devModePremiumProvider =
    NotifierProvider<DevModePremiumNotifier, bool>(
  DevModePremiumNotifier.new,
);

class DevModePremiumNotifier extends Notifier<bool> {
  @override
  bool build() => ref.read(initialDevPremiumProvider);

  Future<void> toggle(bool value) async {
    state = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_premiumKey, value);
  }
}
