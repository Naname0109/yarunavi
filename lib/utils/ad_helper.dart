import 'dart:io';

import 'package:flutter/foundation.dart';

class AdHelper {
  AdHelper._();

  static String get bannerAdUnitId {
    if (kDebugMode) {
      // Google公式テストID (実機/シミュレータで確実に表示される)
      return Platform.isIOS
          ? 'ca-app-pub-3940256099942544/2435281174'
          : 'ca-app-pub-3940256099942544/6300978111';
    }
    // TODO: AdMob登録完了後に本番IDに差し替え
    return Platform.isIOS
        ? 'ca-app-pub-XXXXX/XXXXX'
        : 'ca-app-pub-XXXXX/XXXXX';
  }

}
