import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../utils/ad_helper.dart';

/// リワードインタースティシャル広告の管理
class RewardedAdService {
  RewardedInterstitialAd? _ad;
  bool _isLoading = false;

  /// 広告をプリロード
  Future<void> preload() async {
    if (!AdHelper.isAdSupported) return;
    if (_ad != null || _isLoading) return;
    _isLoading = true;

    await RewardedInterstitialAd.load(
      adUnitId: AdHelper.rewardedInterstitialAdUnitId,
      request: const AdRequest(),
      rewardedInterstitialAdLoadCallback:
          RewardedInterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          debugPrint('[RewardedAd] loaded');
          _ad = ad;
          _isLoading = false;
        },
        onAdFailedToLoad: (error) {
          debugPrint('[RewardedAd] failed to load: ${error.message}');
          _ad = null;
          _isLoading = false;
        },
      ),
    );
  }

  /// 広告が表示可能か
  bool get isReady => _ad != null;

  /// 広告を表示してリワードを返す。成功時true、失敗時false。
  Future<bool> show() async {
    if (_ad == null) {
      debugPrint('[RewardedAd] not ready');
      return false;
    }

    var rewarded = false;

    _ad!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _ad = null;
        // 次の広告をプリロード
        preload();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('[RewardedAd] show failed: ${error.message}');
        ad.dispose();
        _ad = null;
        preload();
      },
    );

    await _ad!.show(
      onUserEarnedReward: (ad, reward) {
        debugPrint('[RewardedAd] rewarded: ${reward.amount} ${reward.type}');
        rewarded = true;
      },
    );

    // 広告の表示完了を少し待つ
    await Future.delayed(const Duration(milliseconds: 500));
    return rewarded;
  }

  void dispose() {
    _ad?.dispose();
    _ad = null;
  }
}
