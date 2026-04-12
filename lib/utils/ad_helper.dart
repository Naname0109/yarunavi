import 'package:flutter/foundation.dart';

class AdHelper {
  AdHelper._();

  /// モバイルプラットフォームでのみ広告を表示するか
  static bool get isAdSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  static String get bannerAdUnitId {
    if (!isAdSupported) return '';
    final isIOS = defaultTargetPlatform == TargetPlatform.iOS;
    if (kDebugMode) {
      return isIOS
          ? 'ca-app-pub-3940256099942544/2435281174'
          : 'ca-app-pub-3940256099942544/6300978111';
    }
    // TODO: AdMob登録完了後に本番IDに差し替え
    return isIOS
        ? 'ca-app-pub-XXXXX/XXXXX'
        : 'ca-app-pub-XXXXX/XXXXX';
  }

  /// リワードインタースティシャル広告ID
  static String get rewardedInterstitialAdUnitId {
    if (!isAdSupported) return '';
    final isIOS = defaultTargetPlatform == TargetPlatform.iOS;
    if (kDebugMode) {
      // Google公式テストID
      return isIOS
          ? 'ca-app-pub-3940256099942544/6978759866'
          : 'ca-app-pub-3940256099942544/5354046379';
    }
    // TODO: AdMob登録完了後に本番IDに差し替え
    return isIOS
        ? 'ca-app-pub-XXXXX/XXXXX'
        : 'ca-app-pub-XXXXX/XXXXX';
  }
}
