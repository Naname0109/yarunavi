import 'dart:io';

import 'package:flutter/foundation.dart';

class AdHelper {
  AdHelper._();

  static String get bannerAdUnitId {
    if (kDebugMode) {
      // テスト用ID
      return Platform.isIOS
          ? 'ca-app-pub-3940256099942544/2934735716'
          : 'ca-app-pub-3940256099942544/6300978111';
    }
    // TODO: AdMobで作成した本番IDに差し替え
    return Platform.isIOS
        ? 'ca-app-pub-XXXXXXXX/XXXXXXXXXX'
        : 'ca-app-pub-XXXXXXXX/XXXXXXXXXX';
  }

  static String get rewardedAdUnitId {
    if (kDebugMode) {
      return Platform.isIOS
          ? 'ca-app-pub-3940256099942544/1712485313'
          : 'ca-app-pub-3940256099942544/5224354917';
    }
    // TODO: AdMobで作成した本番IDに差し替え
    return Platform.isIOS
        ? 'ca-app-pub-XXXXXXXX/XXXXXXXXXX'
        : 'ca-app-pub-XXXXXXXX/XXXXXXXXXX';
  }
}
