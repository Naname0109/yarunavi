import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _localeKey = 'app_locale';
const _themeModeKey = 'app_theme_mode';
const _executionTimingKey = 'execution_timing_factor';

/// 起動時の初期設定値（main.dartでoverrideされる）
final initialLocaleProvider = Provider<Locale>((ref) => const Locale('ja'));
final initialThemeModeProvider = Provider<ThemeMode>((ref) => ThemeMode.system);
final initialExecutionTimingProvider = Provider<double>((ref) => 0.5);

/// 起動時にSharedPreferencesから初期値を読み込む
Future<({Locale locale, ThemeMode themeMode, double executionTiming})>
    loadSettingsFromPrefs() async {
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

  final executionTiming = prefs.getDouble(_executionTimingKey) ?? 0.5;

  return (
    locale: locale,
    themeMode: themeMode,
    executionTiming: executionTiming,
  );
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

/// 実行日タイミング設定（0.0=ギリギリ、1.0=早め）
class ExecutionTimingNotifier extends Notifier<double> {
  @override
  double build() {
    return ref.read(initialExecutionTimingProvider);
  }

  Future<void> setFactor(double factor) async {
    state = factor;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_executionTimingKey, factor);
  }
}

final executionTimingProvider =
    NotifierProvider<ExecutionTimingNotifier, double>(
  ExecutionTimingNotifier.new,
);
