import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'gamification_provider.dart';
import 'task_provider.dart' show databaseServiceProvider;

const _localeKey = 'app_locale';
const _themeModeKey = 'app_theme_mode';
const _executionTimingKey = 'execution_timing_factor';
const _soundEnabledKey = 'sound_enabled';
const _weekdayBusynessKey = 'weekday_busyness'; // #3-1: 1=暇〜5=忙しい × 7曜日
const _aiReminderEnabledKey = 'ai_sort_reminder_enabled'; // #6-2
const _avoidEventDaysKey = 'avoid_event_days'; // #2 続: 予定日に AI 整理を割り振らない

/// 曜日ごとの「忙しさ」。 月=0 〜 日=6 のリスト、 値は 1〜5。
/// AI 整理時に「忙しい曜日にはタスクを集中させない」 ヒントとして渡す。
typedef WeekdayBusyness = List<int>;

const WeekdayBusyness defaultWeekdayBusyness = [3, 3, 3, 3, 3, 3, 3];

bool _listEquals(List<int> a, List<int> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// 起動時の初期設定値（main.dartでoverrideされる）
final initialLocaleProvider = Provider<Locale>((ref) => const Locale('ja'));
final initialThemeModeProvider = Provider<ThemeMode>((ref) => ThemeMode.system);
final initialExecutionTimingProvider = Provider<double>((ref) => 0.5);
final initialSoundEnabledProvider = Provider<bool>((ref) => true);

/// 起動時にSharedPreferencesから初期値を読み込む
Future<
    ({
      Locale locale,
      ThemeMode themeMode,
      double executionTiming,
      bool soundEnabled,
    })> loadSettingsFromPrefs() async {
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
  final soundEnabled = prefs.getBool(_soundEnabledKey) ?? true;

  return (
    locale: locale,
    themeMode: themeMode,
    executionTiming: executionTiming,
    soundEnabled: soundEnabled,
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

/// サウンドON/OFF設定
class SoundEnabledNotifier extends Notifier<bool> {
  @override
  bool build() {
    return ref.read(initialSoundEnabledProvider);
  }

  Future<void> setEnabled(bool value) async {
    state = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_soundEnabledKey, value);
  }
}

final soundEnabledProvider =
    NotifierProvider<SoundEnabledNotifier, bool>(SoundEnabledNotifier.new);

/// 曜日ごとの忙しさ設定 (#3-1)。 SharedPreferences に「3,3,3,3,3,3,3」形式で保存。
class WeekdayBusynessNotifier extends AsyncNotifier<WeekdayBusyness> {
  @override
  Future<WeekdayBusyness> build() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_weekdayBusynessKey);
    if (raw == null) return defaultWeekdayBusyness;
    final parts = raw.split(',');
    if (parts.length != 7) return defaultWeekdayBusyness;
    return [
      for (final p in parts) (int.tryParse(p) ?? 3).clamp(1, 5),
    ];
  }

  Future<void> setBusyness(int weekdayIndex, int value) async {
    final current = state.valueOrNull ?? defaultWeekdayBusyness;
    final next = [...current];
    next[weekdayIndex] = value.clamp(1, 5);
    state = AsyncValue.data(next);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_weekdayBusynessKey, next.join(','));

    // #5 隠しバッジ schedule_master: デフォルト値 (3,3,3,3,3,3,3) から
    // 変更されている場合に獲得 (初回のみ markBadgeEarned が true を返す)
    final isDefault = _listEquals(next, defaultWeekdayBusyness);
    if (!isDefault) {
      unawaited(ref.read(gamificationServiceProvider).checkScheduleMaster());
    }
  }
}

final weekdayBusynessProvider =
    AsyncNotifierProvider<WeekdayBusynessNotifier, WeekdayBusyness>(
  WeekdayBusynessNotifier.new,
);

/// タスク実行不可日 (#3-2)。 blocked_dates テーブルから読み込み。
class BlockedDatesNotifier extends AsyncNotifier<List<DateTime>> {
  @override
  Future<List<DateTime>> build() async {
    final db = ref.read(databaseServiceProvider);
    return db.getBlockedDates();
  }

  Future<void> add(DateTime date) async {
    final db = ref.read(databaseServiceProvider);
    await db.addBlockedDate(date);
    ref.invalidateSelf();
  }

  Future<void> remove(DateTime date) async {
    final db = ref.read(databaseServiceProvider);
    await db.removeBlockedDate(date);
    ref.invalidateSelf();
  }

  /// #1 一括保存: 設定画面のカレンダーグリッドからまとめて反映する。
  Future<void> setAll(List<DateTime> dates) async {
    final db = ref.read(databaseServiceProvider);
    await db.replaceAllBlockedDates(dates);
    ref.invalidateSelf();
  }
}

final blockedDatesProvider =
    AsyncNotifierProvider<BlockedDatesNotifier, List<DateTime>>(
  BlockedDatesNotifier.new,
);

/// #6-2: タスク整理リマインド ON/OFF (デフォルト ON)。
class AiReminderEnabledNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_aiReminderEnabledKey) ?? true;
  }

  Future<void> setEnabled(bool value) async {
    state = AsyncValue.data(value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_aiReminderEnabledKey, value);
  }
}

final aiReminderEnabledProvider =
    AsyncNotifierProvider<AiReminderEnabledNotifier, bool>(
  AiReminderEnabledNotifier.new,
);

/// #2: 予定がある日にはタスクを入れない (AI 整理プロンプトに反映)。 デフォルト OFF。
class AvoidEventDaysNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_avoidEventDaysKey) ?? false;
  }

  Future<void> setEnabled(bool value) async {
    state = AsyncValue.data(value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_avoidEventDaysKey, value);
  }
}

final avoidEventDaysProvider =
    AsyncNotifierProvider<AvoidEventDaysNotifier, bool>(
  AvoidEventDaysNotifier.new,
);

/// #4: 通知タイミング設定。
/// 3 トグル (実行日/期限日/期限超過) + 時刻 (hour/minute)。
class NotifyTimingPrefs {
  const NotifyTimingPrefs({
    required this.onRecommended,
    required this.onDue,
    required this.onOverdue,
    required this.hour,
    required this.minute,
  });
  final bool onRecommended;
  final bool onDue;
  final bool onOverdue;
  final int hour;
  final int minute;

  NotifyTimingPrefs copyWith({
    bool? onRecommended,
    bool? onDue,
    bool? onOverdue,
    int? hour,
    int? minute,
  }) =>
      NotifyTimingPrefs(
        onRecommended: onRecommended ?? this.onRecommended,
        onDue: onDue ?? this.onDue,
        onOverdue: onOverdue ?? this.onOverdue,
        hour: hour ?? this.hour,
        minute: minute ?? this.minute,
      );
}

class NotifyTimingNotifier extends AsyncNotifier<NotifyTimingPrefs> {
  static const _kOnRec = 'notify_on_recommended_date';
  static const _kOnDue = 'notify_on_due_date';
  static const _kOnOverdue = 'notify_on_overdue';
  static const _kHour = 'notify_time_hour';
  static const _kMinute = 'notify_time_minute';

  @override
  Future<NotifyTimingPrefs> build() async {
    final prefs = await SharedPreferences.getInstance();
    return NotifyTimingPrefs(
      onRecommended: prefs.getBool(_kOnRec) ?? true,
      onDue: prefs.getBool(_kOnDue) ?? true,
      onOverdue: prefs.getBool(_kOnOverdue) ?? true,
      hour: prefs.getInt(_kHour) ?? 9,
      minute: prefs.getInt(_kMinute) ?? 0,
    );
  }

  Future<void> setOnRecommended(bool v) async {
    final cur = state.valueOrNull;
    if (cur == null) return;
    state = AsyncValue.data(cur.copyWith(onRecommended: v));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kOnRec, v);
  }

  Future<void> setOnDue(bool v) async {
    final cur = state.valueOrNull;
    if (cur == null) return;
    state = AsyncValue.data(cur.copyWith(onDue: v));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kOnDue, v);
  }

  Future<void> setOnOverdue(bool v) async {
    final cur = state.valueOrNull;
    if (cur == null) return;
    state = AsyncValue.data(cur.copyWith(onOverdue: v));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kOnOverdue, v);
  }

  Future<void> setTime(int hour, int minute) async {
    final cur = state.valueOrNull;
    if (cur == null) return;
    state = AsyncValue.data(cur.copyWith(hour: hour, minute: minute));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kHour, hour);
    await prefs.setInt(_kMinute, minute);
  }
}

final notifyTimingProvider =
    AsyncNotifierProvider<NotifyTimingNotifier, NotifyTimingPrefs>(
  NotifyTimingNotifier.new,
);
