import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _useNewUiKey = 'dev_mode_use_new_ui';

/// 起動時の初期値 (main.dart で overrideWithValue する)
final initialUseNewUiProvider = Provider<bool>((ref) => true);

/// 起動時に SharedPreferences から読み込む
Future<({bool useNewUi})> loadUiModePrefs() async {
  final prefs = await SharedPreferences.getInstance();
  return (
    // v2 UI を新規 / 未設定ユーザーのデフォルトに
    useNewUi: prefs.getBool(_useNewUiKey) ?? true,
  );
}

/// 新 UI (v2 リデザイン版) を有効化するトグル。
/// app.dart / calendar_screen.dart で v1/v2 の分岐に使う。
final useNewUiProvider = NotifierProvider<UseNewUiNotifier, bool>(
  UseNewUiNotifier.new,
);

class UseNewUiNotifier extends Notifier<bool> {
  @override
  bool build() => ref.read(initialUseNewUiProvider);

  Future<void> toggle(bool value) async {
    state = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_useNewUiKey, value);
  }
}
