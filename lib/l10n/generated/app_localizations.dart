import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ja.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ja'),
  ];

  /// アプリ名
  ///
  /// In ja, this message translates to:
  /// **'YaruNavi'**
  String get appTitle;

  /// No description provided for @home.
  ///
  /// In ja, this message translates to:
  /// **'ホーム'**
  String get home;

  /// No description provided for @settings.
  ///
  /// In ja, this message translates to:
  /// **'設定'**
  String get settings;

  /// No description provided for @addTask.
  ///
  /// In ja, this message translates to:
  /// **'タスクを追加'**
  String get addTask;

  /// No description provided for @editTask.
  ///
  /// In ja, this message translates to:
  /// **'タスクを編集'**
  String get editTask;

  /// No description provided for @taskName.
  ///
  /// In ja, this message translates to:
  /// **'タスク名'**
  String get taskName;

  /// No description provided for @dueDate.
  ///
  /// In ja, this message translates to:
  /// **'期限日'**
  String get dueDate;

  /// No description provided for @memo.
  ///
  /// In ja, this message translates to:
  /// **'メモ'**
  String get memo;

  /// No description provided for @category.
  ///
  /// In ja, this message translates to:
  /// **'カテゴリ'**
  String get category;

  /// No description provided for @save.
  ///
  /// In ja, this message translates to:
  /// **'保存'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In ja, this message translates to:
  /// **'キャンセル'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In ja, this message translates to:
  /// **'削除'**
  String get delete;

  /// No description provided for @all.
  ///
  /// In ja, this message translates to:
  /// **'すべて'**
  String get all;

  /// No description provided for @today.
  ///
  /// In ja, this message translates to:
  /// **'今日'**
  String get today;

  /// No description provided for @thisWeek.
  ///
  /// In ja, this message translates to:
  /// **'今週'**
  String get thisWeek;

  /// No description provided for @overdue.
  ///
  /// In ja, this message translates to:
  /// **'期限切れ'**
  String get overdue;

  /// No description provided for @completed.
  ///
  /// In ja, this message translates to:
  /// **'完了済み'**
  String get completed;

  /// No description provided for @aiSort.
  ///
  /// In ja, this message translates to:
  /// **'AIで整理'**
  String get aiSort;

  /// No description provided for @premium.
  ///
  /// In ja, this message translates to:
  /// **'プレミアム'**
  String get premium;

  /// No description provided for @store.
  ///
  /// In ja, this message translates to:
  /// **'ストア'**
  String get store;

  /// No description provided for @language.
  ///
  /// In ja, this message translates to:
  /// **'言語'**
  String get language;

  /// No description provided for @theme.
  ///
  /// In ja, this message translates to:
  /// **'テーマ'**
  String get theme;

  /// No description provided for @lightTheme.
  ///
  /// In ja, this message translates to:
  /// **'ライト'**
  String get lightTheme;

  /// No description provided for @darkTheme.
  ///
  /// In ja, this message translates to:
  /// **'ダーク'**
  String get darkTheme;

  /// No description provided for @systemTheme.
  ///
  /// In ja, this message translates to:
  /// **'端末設定に従う'**
  String get systemTheme;

  /// No description provided for @notification.
  ///
  /// In ja, this message translates to:
  /// **'通知'**
  String get notification;

  /// No description provided for @dataManagement.
  ///
  /// In ja, this message translates to:
  /// **'データ管理'**
  String get dataManagement;

  /// No description provided for @termsOfUse.
  ///
  /// In ja, this message translates to:
  /// **'利用規約'**
  String get termsOfUse;

  /// No description provided for @privacyPolicy.
  ///
  /// In ja, this message translates to:
  /// **'プライバシーポリシー'**
  String get privacyPolicy;

  /// No description provided for @appInfo.
  ///
  /// In ja, this message translates to:
  /// **'アプリ情報'**
  String get appInfo;

  /// No description provided for @deleteConfirmTitle.
  ///
  /// In ja, this message translates to:
  /// **'削除の確認'**
  String get deleteConfirmTitle;

  /// No description provided for @deleteConfirmMessage.
  ///
  /// In ja, this message translates to:
  /// **'このタスクを削除しますか？'**
  String get deleteConfirmMessage;

  /// No description provided for @categoryPayment.
  ///
  /// In ja, this message translates to:
  /// **'お金・支払い'**
  String get categoryPayment;

  /// No description provided for @categoryPaperwork.
  ///
  /// In ja, this message translates to:
  /// **'手続き・届出'**
  String get categoryPaperwork;

  /// No description provided for @categoryShopping.
  ///
  /// In ja, this message translates to:
  /// **'買い物'**
  String get categoryShopping;

  /// No description provided for @categoryHousehold.
  ///
  /// In ja, this message translates to:
  /// **'家事・生活'**
  String get categoryHousehold;

  /// No description provided for @categoryWork.
  ///
  /// In ja, this message translates to:
  /// **'仕事'**
  String get categoryWork;

  /// No description provided for @categoryOther.
  ///
  /// In ja, this message translates to:
  /// **'その他'**
  String get categoryOther;

  /// No description provided for @emptyTaskMessage.
  ///
  /// In ja, this message translates to:
  /// **'タスクを追加しましょう'**
  String get emptyTaskMessage;

  /// No description provided for @emptyTodayMessage.
  ///
  /// In ja, this message translates to:
  /// **'今日のタスクはありません'**
  String get emptyTodayMessage;

  /// No description provided for @emptyWeekMessage.
  ///
  /// In ja, this message translates to:
  /// **'今週のタスクはありません'**
  String get emptyWeekMessage;

  /// No description provided for @emptyOverdueMessage.
  ///
  /// In ja, this message translates to:
  /// **'期限切れのタスクはありません'**
  String get emptyOverdueMessage;

  /// No description provided for @emptyCompletedMessage.
  ///
  /// In ja, this message translates to:
  /// **'完了済みのタスクはありません'**
  String get emptyCompletedMessage;

  /// No description provided for @tomorrow.
  ///
  /// In ja, this message translates to:
  /// **'明日'**
  String get tomorrow;

  /// No description provided for @yesterday.
  ///
  /// In ja, this message translates to:
  /// **'昨日'**
  String get yesterday;

  /// No description provided for @daysLater.
  ///
  /// In ja, this message translates to:
  /// **'{count}日後'**
  String daysLater(int count);

  /// No description provided for @daysAgo.
  ///
  /// In ja, this message translates to:
  /// **'{count}日前'**
  String daysAgo(int count);

  /// No description provided for @markComplete.
  ///
  /// In ja, this message translates to:
  /// **'完了'**
  String get markComplete;

  /// No description provided for @markIncomplete.
  ///
  /// In ja, this message translates to:
  /// **'未完了に戻す'**
  String get markIncomplete;

  /// No description provided for @taskNameRequired.
  ///
  /// In ja, this message translates to:
  /// **'タスク名を入力してください'**
  String get taskNameRequired;

  /// No description provided for @selectDate.
  ///
  /// In ja, this message translates to:
  /// **'日付を選択'**
  String get selectDate;

  /// No description provided for @noCategory.
  ///
  /// In ja, this message translates to:
  /// **'なし'**
  String get noCategory;

  /// No description provided for @recurrence.
  ///
  /// In ja, this message translates to:
  /// **'定期設定'**
  String get recurrence;

  /// No description provided for @recurrenceNone.
  ///
  /// In ja, this message translates to:
  /// **'なし'**
  String get recurrenceNone;

  /// No description provided for @recurrenceWeekly.
  ///
  /// In ja, this message translates to:
  /// **'毎週'**
  String get recurrenceWeekly;

  /// No description provided for @recurrenceMonthly.
  ///
  /// In ja, this message translates to:
  /// **'毎月'**
  String get recurrenceMonthly;

  /// No description provided for @recurrenceYearly.
  ///
  /// In ja, this message translates to:
  /// **'毎年'**
  String get recurrenceYearly;

  /// No description provided for @recurrenceCustom.
  ///
  /// In ja, this message translates to:
  /// **'カスタム'**
  String get recurrenceCustom;

  /// No description provided for @recurrenceEveryNDays.
  ///
  /// In ja, this message translates to:
  /// **'{count}日ごと'**
  String recurrenceEveryNDays(int count);

  /// No description provided for @recurrenceInterval.
  ///
  /// In ja, this message translates to:
  /// **'間隔（日数）'**
  String get recurrenceInterval;

  /// No description provided for @notifySettings.
  ///
  /// In ja, this message translates to:
  /// **'通知設定'**
  String get notifySettings;

  /// No description provided for @notifyOnDue.
  ///
  /// In ja, this message translates to:
  /// **'期限日'**
  String get notifyOnDue;

  /// No description provided for @notifyOneDayBefore.
  ///
  /// In ja, this message translates to:
  /// **'1日前'**
  String get notifyOneDayBefore;

  /// No description provided for @notifyThreeDaysBefore.
  ///
  /// In ja, this message translates to:
  /// **'3日前'**
  String get notifyThreeDaysBefore;

  /// No description provided for @notifyOneWeekBefore.
  ///
  /// In ja, this message translates to:
  /// **'1週間前'**
  String get notifyOneWeekBefore;

  /// No description provided for @premiumOnly.
  ///
  /// In ja, this message translates to:
  /// **'プレミアム限定'**
  String get premiumOnly;

  /// No description provided for @recurringTaskCreated.
  ///
  /// In ja, this message translates to:
  /// **'次回タスクを作成しました: {date}'**
  String recurringTaskCreated(String date);

  /// No description provided for @aiResultTitle.
  ///
  /// In ja, this message translates to:
  /// **'AIが整理しました'**
  String get aiResultTitle;

  /// No description provided for @aiResultSortedAt.
  ///
  /// In ja, this message translates to:
  /// **'整理日時: {dateTime}'**
  String aiResultSortedAt(String dateTime);

  /// No description provided for @aiPriorityUrgent.
  ///
  /// In ja, this message translates to:
  /// **'🔴 今すぐやるべき'**
  String get aiPriorityUrgent;

  /// No description provided for @aiPriorityWarning.
  ///
  /// In ja, this message translates to:
  /// **'🟠 今週中に'**
  String get aiPriorityWarning;

  /// No description provided for @aiPriorityNormal.
  ///
  /// In ja, this message translates to:
  /// **'🔵 来週以降'**
  String get aiPriorityNormal;

  /// No description provided for @aiPriorityRelaxed.
  ///
  /// In ja, this message translates to:
  /// **'⚪ 急がないが忘れずに'**
  String get aiPriorityRelaxed;

  /// No description provided for @backToHome.
  ///
  /// In ja, this message translates to:
  /// **'ホームに戻る'**
  String get backToHome;

  /// No description provided for @aiSortRemaining.
  ///
  /// In ja, this message translates to:
  /// **'残り{count}回'**
  String aiSortRemaining(int count);

  /// No description provided for @aiSortLimitReached.
  ///
  /// In ja, this message translates to:
  /// **'今月の無料回数を使い切りました'**
  String get aiSortLimitReached;

  /// No description provided for @aiSortDailyLimitReached.
  ///
  /// In ja, this message translates to:
  /// **'本日の利用回数の上限に達しました'**
  String get aiSortDailyLimitReached;

  /// No description provided for @aiSortUpgradeToPremium.
  ///
  /// In ja, this message translates to:
  /// **'プレミアムに登録'**
  String get aiSortUpgradeToPremium;

  /// No description provided for @aiSortWatchAd.
  ///
  /// In ja, this message translates to:
  /// **'動画を見て使う'**
  String get aiSortWatchAd;

  /// No description provided for @aiSortNoTasks.
  ///
  /// In ja, this message translates to:
  /// **'整理するタスクがありません'**
  String get aiSortNoTasks;

  /// No description provided for @aiErrorNetwork.
  ///
  /// In ja, this message translates to:
  /// **'接続に失敗しました。ネットワークを確認してください'**
  String get aiErrorNetwork;

  /// No description provided for @aiErrorParse.
  ///
  /// In ja, this message translates to:
  /// **'AIの応答を処理できませんでした。期限日ベースで整理しました'**
  String get aiErrorParse;

  /// No description provided for @aiErrorRateLimit.
  ///
  /// In ja, this message translates to:
  /// **'しばらく時間をおいてお試しください'**
  String get aiErrorRateLimit;

  /// No description provided for @aiSorting.
  ///
  /// In ja, this message translates to:
  /// **'AIが整理中...'**
  String get aiSorting;

  /// No description provided for @notificationTitle.
  ///
  /// In ja, this message translates to:
  /// **'YaruNavi'**
  String get notificationTitle;

  /// No description provided for @notifyDueToday.
  ///
  /// In ja, this message translates to:
  /// **'{taskName} の期限は今日です'**
  String notifyDueToday(String taskName);

  /// No description provided for @notifyDueInDays.
  ///
  /// In ja, this message translates to:
  /// **'{taskName} の期限まであと{count}日です'**
  String notifyDueInDays(String taskName, int count);

  /// No description provided for @notifyRecurring.
  ///
  /// In ja, this message translates to:
  /// **'{taskName} の時期です'**
  String notifyRecurring(String taskName);

  /// No description provided for @addToCalendar.
  ///
  /// In ja, this message translates to:
  /// **'カレンダーに追加'**
  String get addToCalendar;

  /// No description provided for @calendarPermissionDenied.
  ///
  /// In ja, this message translates to:
  /// **'カレンダーへのアクセスを許可してください'**
  String get calendarPermissionDenied;

  /// No description provided for @calendarAddFailed.
  ///
  /// In ja, this message translates to:
  /// **'カレンダーへの追加に失敗しました'**
  String get calendarAddFailed;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ja'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ja':
      return AppLocalizationsJa();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
