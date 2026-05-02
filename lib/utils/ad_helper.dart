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
    return isIOS
        ? 'ca-app-pub-2099665494657429/4943695327'
        : 'ca-app-pub-XXXXX/XXXXX';
  }

  /// リワードインタースティシャル広告ID
  static String get rewardedInterstitialAdUnitId {
    if (!isAdSupported) return '';
    final isIOS = defaultTargetPlatform == TargetPlatform.iOS;
    if (kDebugMode) {
      return isIOS
          ? 'ca-app-pub-3940256099942544/6978759866'
          : 'ca-app-pub-3940256099942544/5354046379';
    }
    return isIOS
        ? 'ca-app-pub-2099665494657429/6243411116'
        : 'ca-app-pub-XXXXX/XXXXX';
  }
}
