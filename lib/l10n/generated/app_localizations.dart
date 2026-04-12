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
  /// **'🔴 今日これだけやろう'**
  String get aiPriorityUrgent;

  /// No description provided for @aiPriorityWarning.
  ///
  /// In ja, this message translates to:
  /// **'🟠 今週のうちに片付けよう'**
  String get aiPriorityWarning;

  /// No description provided for @aiPriorityNormal.
  ///
  /// In ja, this message translates to:
  /// **'🔵 来週以降でOK'**
  String get aiPriorityNormal;

  /// No description provided for @aiPriorityRelaxed.
  ///
  /// In ja, this message translates to:
  /// **'⚪ 忘れずにキープ'**
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

  /// No description provided for @storePremiumTitle.
  ///
  /// In ja, this message translates to:
  /// **'プレミアムプラン'**
  String get storePremiumTitle;

  /// No description provided for @storeFeatureAiUnlimited.
  ///
  /// In ja, this message translates to:
  /// **'AI整理 月30回（無料は動画視聴で1日1回）'**
  String get storeFeatureAiUnlimited;

  /// No description provided for @storeFeatureTaskUnlimited.
  ///
  /// In ja, this message translates to:
  /// **'タスク登録 無制限（無料は10件）'**
  String get storeFeatureTaskUnlimited;

  /// No description provided for @storeFeatureRecurringUnlimited.
  ///
  /// In ja, this message translates to:
  /// **'定期タスク 無制限（無料は1件）'**
  String get storeFeatureRecurringUnlimited;

  /// No description provided for @storeFeatureCategoryUnlimited.
  ///
  /// In ja, this message translates to:
  /// **'カテゴリ 無制限（無料は2つ）'**
  String get storeFeatureCategoryUnlimited;

  /// No description provided for @storeFeatureCalendar.
  ///
  /// In ja, this message translates to:
  /// **'カレンダー書き出し'**
  String get storeFeatureCalendar;

  /// No description provided for @storeFeatureNotification.
  ///
  /// In ja, this message translates to:
  /// **'期限日の通知（無料はアプリ内のみ）'**
  String get storeFeatureNotification;

  /// No description provided for @storeFeatureNoAds.
  ///
  /// In ja, this message translates to:
  /// **'広告非表示'**
  String get storeFeatureNoAds;

  /// No description provided for @storeMonthlyPrice.
  ///
  /// In ja, this message translates to:
  /// **'¥580/月'**
  String get storeMonthlyPrice;

  /// No description provided for @storeYearlyPrice.
  ///
  /// In ja, this message translates to:
  /// **'¥4,200/年（¥350/月相当・40%おトク）'**
  String get storeYearlyPrice;

  /// No description provided for @storeMonthlyTrial.
  ///
  /// In ja, this message translates to:
  /// **'7日間無料 → その後 月額¥580'**
  String get storeMonthlyTrial;

  /// No description provided for @storeYearlyTrial.
  ///
  /// In ja, this message translates to:
  /// **'7日間無料 → その後 年額¥4,200'**
  String get storeYearlyTrial;

  /// No description provided for @storeAutoRenewWarning1.
  ///
  /// In ja, this message translates to:
  /// **'無料体験終了後、自動的に課金されます'**
  String get storeAutoRenewWarning1;

  /// No description provided for @storeAutoRenewWarning2.
  ///
  /// In ja, this message translates to:
  /// **'いつでもキャンセル可能。無料体験中のキャンセルで課金されません'**
  String get storeAutoRenewWarning2;

  /// No description provided for @storeRestore.
  ///
  /// In ja, this message translates to:
  /// **'購入を復元'**
  String get storeRestore;

  /// No description provided for @storePurchaseSuccess.
  ///
  /// In ja, this message translates to:
  /// **'プレミアムプランに登録しました'**
  String get storePurchaseSuccess;

  /// No description provided for @storePurchaseFailed.
  ///
  /// In ja, this message translates to:
  /// **'購入に失敗しました。もう一度お試しください'**
  String get storePurchaseFailed;

  /// No description provided for @storeRestoreSuccess.
  ///
  /// In ja, this message translates to:
  /// **'購入を復元しました'**
  String get storeRestoreSuccess;

  /// No description provided for @storeRestoreNone.
  ///
  /// In ja, this message translates to:
  /// **'復元可能な購入が見つかりません'**
  String get storeRestoreNone;

  /// No description provided for @storeAlreadyPremium.
  ///
  /// In ja, this message translates to:
  /// **'プレミアム登録済み'**
  String get storeAlreadyPremium;

  /// No description provided for @storeStoreUnavailable.
  ///
  /// In ja, this message translates to:
  /// **'ストアに接続できません'**
  String get storeStoreUnavailable;

  /// No description provided for @onboardingSkip.
  ///
  /// In ja, this message translates to:
  /// **'スキップ'**
  String get onboardingSkip;

  /// No description provided for @onboardingNext.
  ///
  /// In ja, this message translates to:
  /// **'次へ'**
  String get onboardingNext;

  /// No description provided for @onboardingStart.
  ///
  /// In ja, this message translates to:
  /// **'はじめる'**
  String get onboardingStart;

  /// No description provided for @ob1Title.
  ///
  /// In ja, this message translates to:
  /// **'やることを入れるだけ'**
  String get ob1Title;

  /// No description provided for @ob1Desc.
  ///
  /// In ja, this message translates to:
  /// **'タスク名と期限を入れるだけ。\nメモも追加できます。'**
  String get ob1Desc;

  /// No description provided for @ob1Sub.
  ///
  /// In ja, this message translates to:
  /// **'頭の中のやることを全部ここに'**
  String get ob1Sub;

  /// No description provided for @ob1Task1.
  ///
  /// In ja, this message translates to:
  /// **'家賃振込'**
  String get ob1Task1;

  /// No description provided for @ob1Task2.
  ///
  /// In ja, this message translates to:
  /// **'免許更新'**
  String get ob1Task2;

  /// No description provided for @ob1Task3.
  ///
  /// In ja, this message translates to:
  /// **'日用品買い出し'**
  String get ob1Task3;

  /// No description provided for @ob1Task4.
  ///
  /// In ja, this message translates to:
  /// **'確定申告の書類準備...'**
  String get ob1Task4;

  /// No description provided for @ob2Title.
  ///
  /// In ja, this message translates to:
  /// **'AIが整理してくれる'**
  String get ob2Title;

  /// No description provided for @ob2Desc.
  ///
  /// In ja, this message translates to:
  /// **'AIが優先順位を判断し、具体的なアドバイス付きで整理'**
  String get ob2Desc;

  /// No description provided for @ob2ArrowLabel.
  ///
  /// In ja, this message translates to:
  /// **'AIで整理'**
  String get ob2ArrowLabel;

  /// No description provided for @ob2BeforeLabel.
  ///
  /// In ja, this message translates to:
  /// **'整理前'**
  String get ob2BeforeLabel;

  /// No description provided for @ob2BeforeTask1.
  ///
  /// In ja, this message translates to:
  /// **'本を読む'**
  String get ob2BeforeTask1;

  /// No description provided for @ob2BeforeDate1.
  ///
  /// In ja, this message translates to:
  /// **'5/1'**
  String get ob2BeforeDate1;

  /// No description provided for @ob2BeforeTask2.
  ///
  /// In ja, this message translates to:
  /// **'家賃振込'**
  String get ob2BeforeTask2;

  /// No description provided for @ob2BeforeDate2.
  ///
  /// In ja, this message translates to:
  /// **'明日'**
  String get ob2BeforeDate2;

  /// No description provided for @ob2BeforeTask3.
  ///
  /// In ja, this message translates to:
  /// **'パスポート更新'**
  String get ob2BeforeTask3;

  /// No description provided for @ob2BeforeDate3.
  ///
  /// In ja, this message translates to:
  /// **'5/20'**
  String get ob2BeforeDate3;

  /// No description provided for @ob2BeforeTask4.
  ///
  /// In ja, this message translates to:
  /// **'週報提出'**
  String get ob2BeforeTask4;

  /// No description provided for @ob2BeforeDate4.
  ///
  /// In ja, this message translates to:
  /// **'今日'**
  String get ob2BeforeDate4;

  /// No description provided for @ob2BeforeTask5.
  ///
  /// In ja, this message translates to:
  /// **'日用品買い出し'**
  String get ob2BeforeTask5;

  /// No description provided for @ob2BeforeDate5.
  ///
  /// In ja, this message translates to:
  /// **'4/18'**
  String get ob2BeforeDate5;

  /// No description provided for @ob2AfterUrgent.
  ///
  /// In ja, this message translates to:
  /// **'今すぐやるべき'**
  String get ob2AfterUrgent;

  /// No description provided for @ob2AfterWarning.
  ///
  /// In ja, this message translates to:
  /// **'今週中に'**
  String get ob2AfterWarning;

  /// No description provided for @ob2AfterNormal.
  ///
  /// In ja, this message translates to:
  /// **'来週以降'**
  String get ob2AfterNormal;

  /// No description provided for @ob2AfterRelaxed.
  ///
  /// In ja, this message translates to:
  /// **'急がない'**
  String get ob2AfterRelaxed;

  /// No description provided for @ob2AfterTask1.
  ///
  /// In ja, this message translates to:
  /// **'週報提出'**
  String get ob2AfterTask1;

  /// No description provided for @ob2AfterComment1.
  ///
  /// In ja, this message translates to:
  /// **'今日中に提出。午前中がおすすめ'**
  String get ob2AfterComment1;

  /// No description provided for @ob2AfterTask2.
  ///
  /// In ja, this message translates to:
  /// **'家賃振込'**
  String get ob2AfterTask2;

  /// No description provided for @ob2AfterComment2.
  ///
  /// In ja, this message translates to:
  /// **'明日が期限。ネットバンキングで今日中に'**
  String get ob2AfterComment2;

  /// No description provided for @ob2AfterTask3.
  ///
  /// In ja, this message translates to:
  /// **'日用品買い出し'**
  String get ob2AfterTask3;

  /// No description provided for @ob2AfterComment3.
  ///
  /// In ja, this message translates to:
  /// **'週末にまとめ買いが効率的'**
  String get ob2AfterComment3;

  /// No description provided for @ob2AfterTask4.
  ///
  /// In ja, this message translates to:
  /// **'パスポート更新'**
  String get ob2AfterTask4;

  /// No description provided for @ob2AfterComment4.
  ///
  /// In ja, this message translates to:
  /// **'窓口は平日のみ。来週の午前中に'**
  String get ob2AfterComment4;

  /// No description provided for @ob2AfterTask5.
  ///
  /// In ja, this message translates to:
  /// **'本を読む'**
  String get ob2AfterTask5;

  /// No description provided for @ob2AfterComment5.
  ///
  /// In ja, this message translates to:
  /// **'余裕あり。週末のリラックスタイムに'**
  String get ob2AfterComment5;

  /// No description provided for @ob3Title.
  ///
  /// In ja, this message translates to:
  /// **'カレンダーで実行日が見える'**
  String get ob3Title;

  /// No description provided for @ob3Desc.
  ///
  /// In ja, this message translates to:
  /// **'いつやるかが一目でわかる。\nAIが最適な実行日を提案します'**
  String get ob3Desc;

  /// No description provided for @ob3LegendUrgent.
  ///
  /// In ja, this message translates to:
  /// **'緊急'**
  String get ob3LegendUrgent;

  /// No description provided for @ob3LegendWeek.
  ///
  /// In ja, this message translates to:
  /// **'今週'**
  String get ob3LegendWeek;

  /// No description provided for @ob3LegendLater.
  ///
  /// In ja, this message translates to:
  /// **'来週〜'**
  String get ob3LegendLater;

  /// No description provided for @ob4Title.
  ///
  /// In ja, this message translates to:
  /// **'通知で忘れない'**
  String get ob4Title;

  /// No description provided for @ob4Desc.
  ///
  /// In ja, this message translates to:
  /// **'AIが最適なタイミングで通知。\n必要な日だけお知らせ'**
  String get ob4Desc;

  /// No description provided for @ob4Sub.
  ///
  /// In ja, this message translates to:
  /// **'やることがない日は静かです'**
  String get ob4Sub;

  /// No description provided for @ob4MockLabel.
  ///
  /// In ja, this message translates to:
  /// **'こんな通知が届きます'**
  String get ob4MockLabel;

  /// No description provided for @ob4Time1.
  ///
  /// In ja, this message translates to:
  /// **'今日 9:00'**
  String get ob4Time1;

  /// No description provided for @ob4Notify1.
  ///
  /// In ja, this message translates to:
  /// **'家賃振込 — ネットバンキングで今日中に'**
  String get ob4Notify1;

  /// No description provided for @ob4Time2.
  ///
  /// In ja, this message translates to:
  /// **'明日 9:00'**
  String get ob4Time2;

  /// No description provided for @ob4Notify2.
  ///
  /// In ja, this message translates to:
  /// **'日用品買い出し — 買い物リストを確認'**
  String get ob4Notify2;

  /// No description provided for @ob5Title.
  ///
  /// In ja, this message translates to:
  /// **'プレミアムでもっと便利に'**
  String get ob5Title;

  /// No description provided for @ob5Free.
  ///
  /// In ja, this message translates to:
  /// **'無料'**
  String get ob5Free;

  /// No description provided for @ob5AiSort.
  ///
  /// In ja, this message translates to:
  /// **'AI整理'**
  String get ob5AiSort;

  /// No description provided for @ob5Tasks.
  ///
  /// In ja, this message translates to:
  /// **'タスク'**
  String get ob5Tasks;

  /// No description provided for @ob5Notify.
  ///
  /// In ja, this message translates to:
  /// **'通知'**
  String get ob5Notify;

  /// No description provided for @ob5Calendar.
  ///
  /// In ja, this message translates to:
  /// **'カレンダー'**
  String get ob5Calendar;

  /// No description provided for @ob5AiComment.
  ///
  /// In ja, this message translates to:
  /// **'AIコメント'**
  String get ob5AiComment;

  /// No description provided for @ob5Ads.
  ///
  /// In ja, this message translates to:
  /// **'広告'**
  String get ob5Ads;

  /// No description provided for @ob5Recurring.
  ///
  /// In ja, this message translates to:
  /// **'定期タスク'**
  String get ob5Recurring;

  /// No description provided for @ob5FreeAi.
  ///
  /// In ja, this message translates to:
  /// **'初回2回+動画'**
  String get ob5FreeAi;

  /// No description provided for @ob5FreeTasks.
  ///
  /// In ja, this message translates to:
  /// **'10件まで'**
  String get ob5FreeTasks;

  /// No description provided for @ob5FreeRecurring.
  ///
  /// In ja, this message translates to:
  /// **'1件'**
  String get ob5FreeRecurring;

  /// No description provided for @ob5FreeAds.
  ///
  /// In ja, this message translates to:
  /// **'あり'**
  String get ob5FreeAds;

  /// No description provided for @ob5PremiumAi.
  ///
  /// In ja, this message translates to:
  /// **'月50回'**
  String get ob5PremiumAi;

  /// No description provided for @ob5PremiumTasks.
  ///
  /// In ja, this message translates to:
  /// **'無制限'**
  String get ob5PremiumTasks;

  /// No description provided for @ob5PremiumNotify.
  ///
  /// In ja, this message translates to:
  /// **'自動設定'**
  String get ob5PremiumNotify;

  /// No description provided for @ob5PremiumCalendar.
  ///
  /// In ja, this message translates to:
  /// **'連携可'**
  String get ob5PremiumCalendar;

  /// No description provided for @ob5PremiumComment.
  ///
  /// In ja, this message translates to:
  /// **'全表示'**
  String get ob5PremiumComment;

  /// No description provided for @ob5PremiumRecurring.
  ///
  /// In ja, this message translates to:
  /// **'無制限'**
  String get ob5PremiumRecurring;

  /// No description provided for @ob5PremiumAds.
  ///
  /// In ja, this message translates to:
  /// **'なし'**
  String get ob5PremiumAds;

  /// No description provided for @ob5Price.
  ///
  /// In ja, this message translates to:
  /// **'月額¥580 / 年額¥4,200（40%おトク）'**
  String get ob5Price;

  /// No description provided for @ob5TrialButton.
  ///
  /// In ja, this message translates to:
  /// **'7日間無料で試す'**
  String get ob5TrialButton;

  /// No description provided for @ob5FreeButton.
  ///
  /// In ja, this message translates to:
  /// **'まずは無料で始める'**
  String get ob5FreeButton;

  /// No description provided for @ob6Title.
  ///
  /// In ja, this message translates to:
  /// **'さあ、始めましょう'**
  String get ob6Title;

  /// No description provided for @ob6Desc.
  ///
  /// In ja, this message translates to:
  /// **'タスクを追加して、AIに整理してもらおう'**
  String get ob6Desc;

  /// No description provided for @taskLoadError.
  ///
  /// In ja, this message translates to:
  /// **'タスクの読み込みに失敗しました'**
  String get taskLoadError;

  /// No description provided for @aiFallbackNotice.
  ///
  /// In ja, this message translates to:
  /// **'AI整理でエラーが発生しました。期限日ベースで整理しました'**
  String get aiFallbackNotice;

  /// No description provided for @aiRewardedAdPrompt.
  ///
  /// In ja, this message translates to:
  /// **'無料のAI整理回数を使い切りました'**
  String get aiRewardedAdPrompt;

  /// No description provided for @aiRewardedAdDesc.
  ///
  /// In ja, this message translates to:
  /// **'動画を視聴すると、今日1回AI整理を利用できます。プレミアムなら制限なしで利用できます。'**
  String get aiRewardedAdDesc;

  /// No description provided for @aiWatchAdButton.
  ///
  /// In ja, this message translates to:
  /// **'動画を視聴して整理'**
  String get aiWatchAdButton;

  /// No description provided for @aiRewardedAdNotReady.
  ///
  /// In ja, this message translates to:
  /// **'広告の準備ができていません。しばらく待ってからお試しください'**
  String get aiRewardedAdNotReady;

  /// No description provided for @aiRewardedAdUsedToday.
  ///
  /// In ja, this message translates to:
  /// **'今日の動画視聴によるAI整理は使用済みです'**
  String get aiRewardedAdUsedToday;

  /// No description provided for @aiRewardedAdTomorrow.
  ///
  /// In ja, this message translates to:
  /// **'明日またご利用いただけます。プレミアムなら制限なしでいつでも利用できます。'**
  String get aiRewardedAdTomorrow;

  /// No description provided for @aiRecommendedPeriod.
  ///
  /// In ja, this message translates to:
  /// **'{period}に実行がおすすめ'**
  String aiRecommendedPeriod(String period);

  /// No description provided for @aiQuestionAnswer.
  ///
  /// In ja, this message translates to:
  /// **'質問{number}の回答: {answer}'**
  String aiQuestionAnswer(int number, String answer);

  /// No description provided for @aiPremiumBannerTitle.
  ///
  /// In ja, this message translates to:
  /// **'プレミアムならAIコメント・通知・カレンダーが使えます'**
  String get aiPremiumBannerTitle;

  /// No description provided for @aiPremiumBannerDesc.
  ///
  /// In ja, this message translates to:
  /// **'AI整理 月50回、通知自動設定、カレンダー連携、広告なし'**
  String get aiPremiumBannerDesc;

  /// No description provided for @aiPremiumBannerButton.
  ///
  /// In ja, this message translates to:
  /// **'7日間無料で試す →'**
  String get aiPremiumBannerButton;

  /// No description provided for @aiLimitUpgradeHint.
  ///
  /// In ja, this message translates to:
  /// **'AIの整理をもっと使いたい方へ'**
  String get aiLimitUpgradeHint;

  /// No description provided for @aiLimitUpgradeDesc.
  ///
  /// In ja, this message translates to:
  /// **'プレミアムなら月50回のAI整理、通知自動設定、カレンダー連携が使えます'**
  String get aiLimitUpgradeDesc;

  /// No description provided for @settingsReplayOnboarding.
  ///
  /// In ja, this message translates to:
  /// **'操作ガイドを再表示'**
  String get settingsReplayOnboarding;

  /// No description provided for @coachAddTask.
  ///
  /// In ja, this message translates to:
  /// **'ここからタスクを追加'**
  String get coachAddTask;

  /// No description provided for @coachAiSort.
  ///
  /// In ja, this message translates to:
  /// **'AIがタスクの優先順位を整理します'**
  String get coachAiSort;

  /// No description provided for @coachFilterTabs.
  ///
  /// In ja, this message translates to:
  /// **'タブで表示を切り替えられます'**
  String get coachFilterTabs;

  /// No description provided for @coachCalendarToggle.
  ///
  /// In ja, this message translates to:
  /// **'カレンダー表示にも切り替えられます'**
  String get coachCalendarToggle;

  /// No description provided for @coachNext.
  ///
  /// In ja, this message translates to:
  /// **'次へ'**
  String get coachNext;

  /// No description provided for @coachDone.
  ///
  /// In ja, this message translates to:
  /// **'OK'**
  String get coachDone;

  /// No description provided for @tabList.
  ///
  /// In ja, this message translates to:
  /// **'タスク'**
  String get tabList;

  /// No description provided for @tabCalendar.
  ///
  /// In ja, this message translates to:
  /// **'カレンダー'**
  String get tabCalendar;

  /// No description provided for @notifyPremiumOnly.
  ///
  /// In ja, this message translates to:
  /// **'プレミアムで通知を設定'**
  String get notifyPremiumOnly;

  /// No description provided for @notifyPremiumOnlySnack.
  ///
  /// In ja, this message translates to:
  /// **'通知設定はプレミアム機能です'**
  String get notifyPremiumOnlySnack;

  /// No description provided for @proBadge.
  ///
  /// In ja, this message translates to:
  /// **'PRO'**
  String get proBadge;

  /// No description provided for @aiNotifyPremiumPrompt.
  ///
  /// In ja, this message translates to:
  /// **'プレミアムで通知を受け取れます'**
  String get aiNotifyPremiumPrompt;

  /// No description provided for @aiSortMonthlyLimitReached.
  ///
  /// In ja, this message translates to:
  /// **'今月のAI整理上限に達しました。来月リセットされます'**
  String get aiSortMonthlyLimitReached;

  /// No description provided for @premiumGateTitle.
  ///
  /// In ja, this message translates to:
  /// **'🔔 通知 / 📅 カレンダー連携はプレミアムで'**
  String get premiumGateTitle;

  /// No description provided for @premiumGateDesc.
  ///
  /// In ja, this message translates to:
  /// **'プレミアムに登録すると、AIが最適な通知日を自動設定、タスクをカレンダーに追加、広告非表示、AI整理 月50回まで利用できます。'**
  String get premiumGateDesc;

  /// No description provided for @premiumGateUpgrade.
  ///
  /// In ja, this message translates to:
  /// **'プレミアムに登録して今すぐ設定する'**
  String get premiumGateUpgrade;

  /// No description provided for @premiumGateLater.
  ///
  /// In ja, this message translates to:
  /// **'あとで'**
  String get premiumGateLater;

  /// No description provided for @aiNotifyOn.
  ///
  /// In ja, this message translates to:
  /// **'{date} に通知する'**
  String aiNotifyOn(String date);

  /// No description provided for @aiCalendarAdd.
  ///
  /// In ja, this message translates to:
  /// **'カレンダーに追加'**
  String get aiCalendarAdd;

  /// No description provided for @aiCalendarAdded.
  ///
  /// In ja, this message translates to:
  /// **'カレンダーに追加しました'**
  String get aiCalendarAdded;

  /// No description provided for @notifyScheduled.
  ///
  /// In ja, this message translates to:
  /// **'通知をセットしました'**
  String get notifyScheduled;

  /// No description provided for @notifyScheduledLabel.
  ///
  /// In ja, this message translates to:
  /// **'通知予定'**
  String get notifyScheduledLabel;

  /// No description provided for @aiAutoNotifyHint.
  ///
  /// In ja, this message translates to:
  /// **'AIが整理時に通知日を決定します'**
  String get aiAutoNotifyHint;

  /// No description provided for @calendarAddedBadge.
  ///
  /// In ja, this message translates to:
  /// **'カレンダー追加済み'**
  String get calendarAddedBadge;

  /// No description provided for @aiNotOrganizedHint.
  ///
  /// In ja, this message translates to:
  /// **'AIで整理するとアドバイスが表示されます'**
  String get aiNotOrganizedHint;

  /// No description provided for @aiCommentLockedHint.
  ///
  /// In ja, this message translates to:
  /// **'プレミアムでAIコメントを見る'**
  String get aiCommentLockedHint;

  /// No description provided for @recommendedDateHint.
  ///
  /// In ja, this message translates to:
  /// **'📌 {date} にやるのがおすすめ'**
  String recommendedDateHint(String date);

  /// No description provided for @calendarSectionRecommended.
  ///
  /// In ja, this message translates to:
  /// **'📋 この日にやるべきタスク'**
  String get calendarSectionRecommended;

  /// No description provided for @calendarSectionDue.
  ///
  /// In ja, this message translates to:
  /// **'⏰ この日が期限のタスク'**
  String get calendarSectionDue;

  /// No description provided for @taskCardEdit.
  ///
  /// In ja, this message translates to:
  /// **'編集'**
  String get taskCardEdit;

  /// No description provided for @aiAutoNotifyHintFull.
  ///
  /// In ja, this message translates to:
  /// **'プレミアムなら整理時に通知も自動セットされます'**
  String get aiAutoNotifyHintFull;

  /// No description provided for @settingsAccount.
  ///
  /// In ja, this message translates to:
  /// **'アカウント'**
  String get settingsAccount;

  /// No description provided for @settingsPremiumStatus.
  ///
  /// In ja, this message translates to:
  /// **'プレミアムステータス'**
  String get settingsPremiumStatus;

  /// No description provided for @settingsPremiumActive.
  ///
  /// In ja, this message translates to:
  /// **'プレミアム有効'**
  String get settingsPremiumActive;

  /// No description provided for @settingsFreeUser.
  ///
  /// In ja, this message translates to:
  /// **'無料プラン'**
  String get settingsFreeUser;

  /// No description provided for @settingsUpgradeToPremium.
  ///
  /// In ja, this message translates to:
  /// **'プレミアムに登録'**
  String get settingsUpgradeToPremium;

  /// No description provided for @settingsDefaultNotify.
  ///
  /// In ja, this message translates to:
  /// **'デフォルト通知タイミング'**
  String get settingsDefaultNotify;

  /// No description provided for @settingsLanguage.
  ///
  /// In ja, this message translates to:
  /// **'言語'**
  String get settingsLanguage;

  /// No description provided for @settingsJapanese.
  ///
  /// In ja, this message translates to:
  /// **'日本語'**
  String get settingsJapanese;

  /// No description provided for @settingsEnglish.
  ///
  /// In ja, this message translates to:
  /// **'English'**
  String get settingsEnglish;

  /// No description provided for @settingsTheme.
  ///
  /// In ja, this message translates to:
  /// **'テーマ'**
  String get settingsTheme;

  /// No description provided for @settingsExportCsv.
  ///
  /// In ja, this message translates to:
  /// **'CSVエクスポート'**
  String get settingsExportCsv;

  /// No description provided for @settingsExportSuccess.
  ///
  /// In ja, this message translates to:
  /// **'CSVをエクスポートしました'**
  String get settingsExportSuccess;

  /// No description provided for @settingsExportFailed.
  ///
  /// In ja, this message translates to:
  /// **'エクスポートに失敗しました'**
  String get settingsExportFailed;

  /// No description provided for @settingsDeleteAllData.
  ///
  /// In ja, this message translates to:
  /// **'全データ削除'**
  String get settingsDeleteAllData;

  /// No description provided for @settingsDeleteAllConfirmTitle.
  ///
  /// In ja, this message translates to:
  /// **'全データ削除の確認'**
  String get settingsDeleteAllConfirmTitle;

  /// No description provided for @settingsDeleteAllConfirmMessage.
  ///
  /// In ja, this message translates to:
  /// **'すべてのタスクとデータが削除されます。この操作は取り消せません。本当に削除しますか？'**
  String get settingsDeleteAllConfirmMessage;

  /// No description provided for @settingsDeleteAllSuccess.
  ///
  /// In ja, this message translates to:
  /// **'全データを削除しました'**
  String get settingsDeleteAllSuccess;

  /// No description provided for @settingsVersion.
  ///
  /// In ja, this message translates to:
  /// **'バージョン'**
  String get settingsVersion;

  /// No description provided for @settingsLicenses.
  ///
  /// In ja, this message translates to:
  /// **'ライセンス'**
  String get settingsLicenses;

  /// No description provided for @estimatedTime.
  ///
  /// In ja, this message translates to:
  /// **'所要時間'**
  String get estimatedTime;

  /// No description provided for @estimatedTimeNone.
  ///
  /// In ja, this message translates to:
  /// **'未設定'**
  String get estimatedTimeNone;

  /// No description provided for @estimatedTime5min.
  ///
  /// In ja, this message translates to:
  /// **'5分'**
  String get estimatedTime5min;

  /// No description provided for @estimatedTime30min.
  ///
  /// In ja, this message translates to:
  /// **'30分'**
  String get estimatedTime30min;

  /// No description provided for @estimatedTime1hour.
  ///
  /// In ja, this message translates to:
  /// **'1時間'**
  String get estimatedTime1hour;

  /// No description provided for @estimatedTimeHalfDay.
  ///
  /// In ja, this message translates to:
  /// **'半日'**
  String get estimatedTimeHalfDay;

  /// No description provided for @estimatedTime1day.
  ///
  /// In ja, this message translates to:
  /// **'1日'**
  String get estimatedTime1day;

  /// No description provided for @importance.
  ///
  /// In ja, this message translates to:
  /// **'重要度'**
  String get importance;

  /// No description provided for @importanceLow.
  ///
  /// In ja, this message translates to:
  /// **'低'**
  String get importanceLow;

  /// No description provided for @importanceMedium.
  ///
  /// In ja, this message translates to:
  /// **'中'**
  String get importanceMedium;

  /// No description provided for @importanceHigh.
  ///
  /// In ja, this message translates to:
  /// **'高'**
  String get importanceHigh;

  /// No description provided for @memoHint.
  ///
  /// In ja, this message translates to:
  /// **'詳細を入力するとAIの整理精度が上がります（例: 市役所で手続き、平日のみ対応可）'**
  String get memoHint;

  /// No description provided for @notifyAiAuto.
  ///
  /// In ja, this message translates to:
  /// **'AIおまかせ'**
  String get notifyAiAuto;

  /// No description provided for @notifyManual.
  ///
  /// In ja, this message translates to:
  /// **'自分で設定'**
  String get notifyManual;

  /// No description provided for @aiSubtaskSuggestion.
  ///
  /// In ja, this message translates to:
  /// **'分割して進めませんか？'**
  String get aiSubtaskSuggestion;

  /// No description provided for @aiSubtaskAdd.
  ///
  /// In ja, this message translates to:
  /// **'この分割で追加'**
  String get aiSubtaskAdd;

  /// No description provided for @aiSubtaskAdded.
  ///
  /// In ja, this message translates to:
  /// **'サブタスクを追加しました'**
  String get aiSubtaskAdded;

  /// No description provided for @aiCompleteOriginal.
  ///
  /// In ja, this message translates to:
  /// **'元のタスクを完了にしますか？'**
  String get aiCompleteOriginal;

  /// No description provided for @aiNotifyUpdated.
  ///
  /// In ja, this message translates to:
  /// **'AIが通知日を設定しました'**
  String get aiNotifyUpdated;

  /// No description provided for @calendarView.
  ///
  /// In ja, this message translates to:
  /// **'カレンダー'**
  String get calendarView;

  /// No description provided for @listView.
  ///
  /// In ja, this message translates to:
  /// **'リスト'**
  String get listView;

  /// No description provided for @debugSection.
  ///
  /// In ja, this message translates to:
  /// **'デバッグ'**
  String get debugSection;

  /// No description provided for @debugInsertTestData.
  ///
  /// In ja, this message translates to:
  /// **'テストデータを投入'**
  String get debugInsertTestData;

  /// No description provided for @debugDeleteAndInsertTestData.
  ///
  /// In ja, this message translates to:
  /// **'全データ削除してテストデータを投入'**
  String get debugDeleteAndInsertTestData;

  /// No description provided for @debugTestDataInserted.
  ///
  /// In ja, this message translates to:
  /// **'テストデータを投入しました'**
  String get debugTestDataInserted;

  /// No description provided for @debugConfirmInsert.
  ///
  /// In ja, this message translates to:
  /// **'テストデータを投入しますか？'**
  String get debugConfirmInsert;

  /// No description provided for @debugConfirmDeleteAndInsert.
  ///
  /// In ja, this message translates to:
  /// **'全データを削除してテストデータを投入しますか？'**
  String get debugConfirmDeleteAndInsert;

  /// No description provided for @debugAiTestData.
  ///
  /// In ja, this message translates to:
  /// **'AI整理テストデータ'**
  String get debugAiTestData;

  /// No description provided for @debugAiTestDataTitle.
  ///
  /// In ja, this message translates to:
  /// **'AI整理テストデータ投入（15件固定）'**
  String get debugAiTestDataTitle;

  /// No description provided for @debugAiTestDataDesc.
  ///
  /// In ja, this message translates to:
  /// **'全データ削除後、AI評価用の固定テストデータを投入'**
  String get debugAiTestDataDesc;

  /// No description provided for @debugAiTestDataConfirm.
  ///
  /// In ja, this message translates to:
  /// **'全データを削除してAI評価用の15件を投入します。よろしいですか？'**
  String get debugAiTestDataConfirm;

  /// No description provided for @debugAiTestDataInserted.
  ///
  /// In ja, this message translates to:
  /// **'AI整理テストデータ（15件）を投入しました'**
  String get debugAiTestDataInserted;

  /// No description provided for @aiTodayPlan.
  ///
  /// In ja, this message translates to:
  /// **'今日のプラン'**
  String get aiTodayPlan;

  /// No description provided for @aiTodayTasks.
  ///
  /// In ja, this message translates to:
  /// **'今日やること: {count}件'**
  String aiTodayTasks(int count);

  /// No description provided for @aiWeekTasks.
  ///
  /// In ja, this message translates to:
  /// **'今週中: {count}件'**
  String aiWeekTasks(int count);

  /// No description provided for @aiLaterTasks.
  ///
  /// In ja, this message translates to:
  /// **'急がない: {count}件'**
  String aiLaterTasks(int count);

  /// No description provided for @aiViewSchedule.
  ///
  /// In ja, this message translates to:
  /// **'整理後のスケジュールを確認'**
  String get aiViewSchedule;

  /// No description provided for @aiQuestions.
  ///
  /// In ja, this message translates to:
  /// **'AIからの質問'**
  String get aiQuestions;

  /// No description provided for @aiAnswerAndResort.
  ///
  /// In ja, this message translates to:
  /// **'回答してもう一度整理'**
  String get aiAnswerAndResort;

  /// No description provided for @aiAnswerHint.
  ///
  /// In ja, this message translates to:
  /// **'回答を入力...'**
  String get aiAnswerHint;

  /// No description provided for @aiNotifySchedule.
  ///
  /// In ja, this message translates to:
  /// **'通知予定'**
  String get aiNotifySchedule;

  /// No description provided for @aiLoadingAnalyze.
  ///
  /// In ja, this message translates to:
  /// **'タスクを分析しています...'**
  String get aiLoadingAnalyze;

  /// No description provided for @aiLoadingPriority.
  ///
  /// In ja, this message translates to:
  /// **'優先順位を判断しています...'**
  String get aiLoadingPriority;

  /// No description provided for @aiLoadingNotify.
  ///
  /// In ja, this message translates to:
  /// **'通知スケジュールを最適化中...'**
  String get aiLoadingNotify;

  /// No description provided for @aiLoadingAdvice.
  ///
  /// In ja, this message translates to:
  /// **'あなたへのアドバイスを作成中...'**
  String get aiLoadingAdvice;

  /// No description provided for @aiLoadingAlmost.
  ///
  /// In ja, this message translates to:
  /// **'もう少しで完了します...'**
  String get aiLoadingAlmost;

  /// No description provided for @aiRunBackground.
  ///
  /// In ja, this message translates to:
  /// **'バックグラウンドで実行'**
  String get aiRunBackground;

  /// No description provided for @aiCompleteNotify.
  ///
  /// In ja, this message translates to:
  /// **'AI整理が完了しました。結果を確認しましょう'**
  String get aiCompleteNotify;

  /// No description provided for @aiCompleteBanner.
  ///
  /// In ja, this message translates to:
  /// **'AI整理完了 — タップで結果を見る'**
  String get aiCompleteBanner;

  /// No description provided for @aiHistory.
  ///
  /// In ja, this message translates to:
  /// **'AI整理の履歴'**
  String get aiHistory;

  /// No description provided for @aiHistoryEmpty.
  ///
  /// In ja, this message translates to:
  /// **'AI整理の履歴はありません'**
  String get aiHistoryEmpty;

  /// No description provided for @aiHistoryCount.
  ///
  /// In ja, this message translates to:
  /// **'{count}件のタスクを整理'**
  String aiHistoryCount(int count);

  /// No description provided for @storeRecommended.
  ///
  /// In ja, this message translates to:
  /// **'おすすめ'**
  String get storeRecommended;

  /// No description provided for @calendarNoTasks.
  ///
  /// In ja, this message translates to:
  /// **'この日のタスクはありません'**
  String get calendarNoTasks;

  /// No description provided for @calendarToday.
  ///
  /// In ja, this message translates to:
  /// **'今日'**
  String get calendarToday;

  /// No description provided for @swipeComplete.
  ///
  /// In ja, this message translates to:
  /// **'完了'**
  String get swipeComplete;

  /// No description provided for @swipeDelete.
  ///
  /// In ja, this message translates to:
  /// **'削除'**
  String get swipeDelete;

  /// No description provided for @swipeUndo.
  ///
  /// In ja, this message translates to:
  /// **'戻す'**
  String get swipeUndo;

  /// No description provided for @reorderHint.
  ///
  /// In ja, this message translates to:
  /// **'長押しでドラッグして並び替え'**
  String get reorderHint;

  /// No description provided for @categoryManageTitle.
  ///
  /// In ja, this message translates to:
  /// **'カテゴリ管理'**
  String get categoryManageTitle;

  /// No description provided for @categoryAdd.
  ///
  /// In ja, this message translates to:
  /// **'カテゴリを追加'**
  String get categoryAdd;

  /// No description provided for @categoryEdit.
  ///
  /// In ja, this message translates to:
  /// **'カテゴリを編集'**
  String get categoryEdit;

  /// No description provided for @categoryDefault.
  ///
  /// In ja, this message translates to:
  /// **'デフォルト'**
  String get categoryDefault;

  /// No description provided for @categoryEmpty.
  ///
  /// In ja, this message translates to:
  /// **'カテゴリがありません'**
  String get categoryEmpty;

  /// No description provided for @categoryNameLabel.
  ///
  /// In ja, this message translates to:
  /// **'カテゴリ名'**
  String get categoryNameLabel;

  /// No description provided for @categoryNameHint.
  ///
  /// In ja, this message translates to:
  /// **'例: 健康、趣味'**
  String get categoryNameHint;

  /// No description provided for @categoryIconLabel.
  ///
  /// In ja, this message translates to:
  /// **'アイコンを選択'**
  String get categoryIconLabel;

  /// No description provided for @categoryDeleteTitle.
  ///
  /// In ja, this message translates to:
  /// **'カテゴリを削除'**
  String get categoryDeleteTitle;

  /// No description provided for @categoryDeleteMessage.
  ///
  /// In ja, this message translates to:
  /// **'このカテゴリに割り当てられたタスクのカテゴリは未設定になります。削除しますか？'**
  String get categoryDeleteMessage;

  /// No description provided for @devModeSection.
  ///
  /// In ja, this message translates to:
  /// **'開発者モード'**
  String get devModeSection;

  /// No description provided for @devModeAiUnlimited.
  ///
  /// In ja, this message translates to:
  /// **'AI回数制限を無視'**
  String get devModeAiUnlimited;

  /// No description provided for @devModeAiUnlimitedDesc.
  ///
  /// In ja, this message translates to:
  /// **'ONでAI整理の回数制限をスキップ'**
  String get devModeAiUnlimitedDesc;

  /// No description provided for @devModePremium.
  ///
  /// In ja, this message translates to:
  /// **'プレミアム機能を解放'**
  String get devModePremium;

  /// No description provided for @devModePremiumDesc.
  ///
  /// In ja, this message translates to:
  /// **'ONで全FeatureGateを解除'**
  String get devModePremiumDesc;

  /// No description provided for @devModeResetAiUsage.
  ///
  /// In ja, this message translates to:
  /// **'AI使用回数リセット'**
  String get devModeResetAiUsage;

  /// No description provided for @devModeResetAiUsageDesc.
  ///
  /// In ja, this message translates to:
  /// **'当月のAI使用回数をリセットします'**
  String get devModeResetAiUsageDesc;

  /// No description provided for @devModeResetAiUsageDone.
  ///
  /// In ja, this message translates to:
  /// **'AI使用回数をリセットしました'**
  String get devModeResetAiUsageDone;

  /// No description provided for @devModeConfirmResetAiUsage.
  ///
  /// In ja, this message translates to:
  /// **'当月のAI使用回数をリセットしますか？'**
  String get devModeConfirmResetAiUsage;

  /// No description provided for @devModeEnabled.
  ///
  /// In ja, this message translates to:
  /// **'開発者モードが有効になりました'**
  String get devModeEnabled;

  /// No description provided for @devModeRemaining.
  ///
  /// In ja, this message translates to:
  /// **'あと{count}回タップで開発者モード'**
  String devModeRemaining(int count);

  /// No description provided for @allCompleteTitle.
  ///
  /// In ja, this message translates to:
  /// **'すべて完了！お疲れさまでした'**
  String get allCompleteTitle;

  /// No description provided for @allCompleteSubtitle.
  ///
  /// In ja, this message translates to:
  /// **'新しいタスクを追加して、次のやることを整理しましょう'**
  String get allCompleteSubtitle;

  /// No description provided for @allCompleteAddTask.
  ///
  /// In ja, this message translates to:
  /// **'タスクを追加する'**
  String get allCompleteAddTask;

  /// No description provided for @allCompleteAiSort.
  ///
  /// In ja, this message translates to:
  /// **'AIで整理'**
  String get allCompleteAiSort;

  /// No description provided for @allCompleteNoTaskForAi.
  ///
  /// In ja, this message translates to:
  /// **'タスクを追加してから整理しましょう'**
  String get allCompleteNoTaskForAi;

  /// No description provided for @allExpiredBannerTitle.
  ///
  /// In ja, this message translates to:
  /// **'すべてのタスクの期限が過ぎています'**
  String get allExpiredBannerTitle;

  /// No description provided for @allExpiredAddTask.
  ///
  /// In ja, this message translates to:
  /// **'新しいタスクを追加'**
  String get allExpiredAddTask;

  /// No description provided for @allExpiredUpdateDue.
  ///
  /// In ja, this message translates to:
  /// **'期限を更新'**
  String get allExpiredUpdateDue;

  /// No description provided for @allExpiredNotification.
  ///
  /// In ja, this message translates to:
  /// **'すべてのタスクの期限が過ぎました。新しいやることを追加しませんか？'**
  String get allExpiredNotification;
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
