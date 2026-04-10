import 'dart:io';

import 'package:flutter/foundation.dart';

class AdHelper {
  AdHelper._();

  static String get bannerAdUnitId {
    if (kDebugMode) {
      return Platform.isIOS
          ? 'ca-app-pub-3940256099942544/2435281174'
          : 'ca-app-pub-3940256099942544/6300978111';
    }
    // TODO: AdMob登録完了後に本番IDに差し替え
    return Platform.isIOS
        ? 'ca-app-pub-XXXXX/XXXXX'
        : 'ca-app-pub-XXXXX/XXXXX';
  }

  /// リワードインタースティシャル広告ID
  static String get rewardedInterstitialAdUnitId {
    if (kDebugMode) {
      // Google公式テストID
      return Platform.isIOS
          ? 'ca-app-pub-3940256099942544/6978759866'
          : 'ca-app-pub-3940256099942544/5354046379';
    }
    // TODO: AdMob登録完了後に本番IDに差し替え
    return Platform.isIOS
        ? 'ca-app-pub-XXXXX/XXXXX'
        : 'ca-app-pub-XXXXX/XXXXX';
  }
}
