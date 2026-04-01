import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/ad_helper.dart';

class AdService {
  RewardedAd? _rewardedAd;
  bool _isRewardedAdLoading = false;

  static const _rewardUnlockKey = 'reward_unlock_until';
  static const _installDateKey = 'install_date';

  /// 初期化: インストール日を記録しリワード広告をプリロード
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();

    // インストール日記録（初回のみ）
    if (!prefs.containsKey(_installDateKey)) {
      await prefs.setString(_installDateKey, DateTime.now().toIso8601String());
    }

    // リワード広告プリロード
    loadRewardedAd();
  }

  /// リワード広告をロード
  void loadRewardedAd() {
    if (_isRewardedAdLoading || _rewardedAd != null) return;
    _isRewardedAdLoading = true;

    RewardedAd.load(
      adUnitId: AdHelper.rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isRewardedAdLoading = false;
        },
        onAdFailedToLoad: (error) {
          debugPrint('RewardedAd failed to load: $error');
          _rewardedAd = null;
          _isRewardedAdLoading = false;
          // 30秒後にリトライ
          Future.delayed(const Duration(seconds: 30), loadRewardedAd);
        },
      ),
    );
  }

  /// リワード広告が表示可能か
  bool get isRewardedAdReady => _rewardedAd != null;

  /// リワード広告を表示し、報酬獲得で true を返す
  Future<bool> showRewardedAd() async {
    if (_rewardedAd == null) return false;

    final completer = Completer<bool>();
    final ad = _rewardedAd!;
    _rewardedAd = null;

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        loadRewardedAd();
        if (!completer.isCompleted) completer.complete(false);
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        loadRewardedAd();
        if (!completer.isCompleted) completer.complete(false);
      },
    );

    await ad.show(onUserEarnedReward: (_, reward) {
      if (!completer.isCompleted) completer.complete(true);
    });

    final rewarded = await completer.future;
    if (rewarded) {
      await _saveRewardUnlock();
    }
    return rewarded;
  }

  /// リワード解除を保存（24時間有効）
  Future<void> _saveRewardUnlock() async {
    final prefs = await SharedPreferences.getInstance();
    final unlockUntil = DateTime.now().add(const Duration(hours: 24));
    await prefs.setString(_rewardUnlockKey, unlockUntil.toIso8601String());
  }

  /// リワード解除中かチェック
  static Future<bool> isRewardUnlocked() async {
    final prefs = await SharedPreferences.getInstance();
    final unlockStr = prefs.getString(_rewardUnlockKey);
    if (unlockStr == null) return false;

    final unlockUntil = DateTime.tryParse(unlockStr);
    if (unlockUntil == null) return false;

    return DateTime.now().isBefore(unlockUntil);
  }

  /// 2日目以降かチェック（リワード広告表示条件）
  static Future<bool> isAfterFirstDay() async {
    final prefs = await SharedPreferences.getInstance();
    final installStr = prefs.getString(_installDateKey);
    if (installStr == null) return false;

    final installDate = DateTime.tryParse(installStr);
    if (installDate == null) return false;

    return DateTime.now().difference(installDate).inDays >= 1;
  }
}
