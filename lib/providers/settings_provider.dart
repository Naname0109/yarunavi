import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _localeKey = 'app_locale';
const _themeModeKey = 'app_theme_mode';

/// 起動時の初期設定値（main.dartでoverrideされる）
final initialLocaleProvider = Provider<Locale>((ref) => const Locale('ja'));
final initialThemeModeProvider = Provider<ThemeMode>((ref) => ThemeMode.system);

/// 起動時にSharedPreferencesから初期値を読み込む
Future<({Locale locale, ThemeMode themeMode})> loadSettingsFromPrefs() async {
  final prefs = await SharedPreferences.getInstance();

  final localeCode = prefs.getString(_localeKey);
  final locale = localeCode != null ? Locale(localeCode) : const Locale('ja');

  final themeName = prefs.getString(_themeModeKey);
  final themeMode = themeName != null
      ? ThemeMode.values.firstWhere(
          (m) => m.name == themeName,
          orElse: () => ThemeMode.system,
        )
      : ThemeMode.system;

  return (locale: locale, themeMode: themeMode);
}

/// ロケール設定
class LocaleNotifier extends Notifier<Locale> {
  @override
  Locale build() {
    return ref.read(initialLocaleProvider);
  }

  Future<void> setLocale(Locale locale) async {
    state = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, locale.languageCode);
  }
}

final localeProvider = NotifierProvider<LocaleNotifier, Locale>(
  LocaleNotifier.new,
);

/// テーマモード設定
class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    return ref.read(initialThemeModeProvider);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeModeKey, mode.name);
  }
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);
