// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'YaruNavi';

  @override
  String get home => 'Home';

  @override
  String get settings => 'Settings';

  @override
  String get addTask => 'Add Task';

  @override
  String get editTask => 'Edit Task';

  @override
  String get taskName => 'Task Name';

  @override
  String get dueDate => 'Due Date';

  @override
  String get memo => 'Memo';

  @override
  String get category => 'Category';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get all => 'All';

  @override
  String get today => 'Today';

  @override
  String get thisWeek => 'This Week';

  @override
  String get overdue => 'Overdue';

  @override
  String get completed => 'Completed';

  @override
  String get aiSort => 'AI Sort';

  @override
  String get premium => 'Premium';

  @override
  String get store => 'Store';

  @override
  String get language => 'Language';

  @override
  String get theme => 'Theme';

  @override
  String get lightTheme => 'Light';

  @override
  String get darkTheme => 'Dark';

  @override
  String get systemTheme => 'Follow System';

  @override
  String get notification => 'Notifications';

  @override
  String get dataManagement => 'Data Management';

  @override
  String get termsOfUse => 'Terms of Use';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get appInfo => 'App Info';

  @override
  String get deleteConfirmTitle => 'Confirm Delete';

  @override
  String get deleteConfirmMessage =>
      'Are you sure you want to delete this task?';

  @override
  String get categoryPayment => 'Payment';

  @override
  String get categoryPaperwork => 'Paperwork';

  @override
  String get categoryShopping => 'Shopping';

  @override
  String get categoryHousehold => 'Household';

  @override
  String get categoryWork => 'Work';

  @override
  String get categoryOther => 'Other';

  @override
  String get emptyTaskMessage => 'Add a task to get started';

  @override
  String get emptyTodayMessage => 'No tasks for today';

  @override
  String get emptyWeekMessage => 'No tasks this week';

  @override
  String get emptyOverdueMessage => 'No overdue tasks';

  @override
  String get emptyCompletedMessage => 'No completed tasks';

  @override
  String get tomorrow => 'Tomorrow';

  @override
  String get yesterday => 'Yesterday';

  @override
  String daysLater(int count) {
    return 'In $count days';
  }

  @override
  String daysAgo(int count) {
    return '$count days ago';
  }

  @override
  String get markComplete => 'Complete';

  @override
  String get markIncomplete => 'Undo Complete';

  @override
  String get taskNameRequired => 'Please enter a task name';

  @override
  String get selectDate => 'Select Date';

  @override
  String get noCategory => 'None';

  @override
  String get recurrence => 'Repeat';

  @override
  String get recurrenceNone => 'None';

  @override
  String get recurrenceWeekly => 'Weekly';

  @override
  String get recurrenceMonthly => 'Monthly';

  @override
  String get recurrenceYearly => 'Yearly';

  @override
  String get recurrenceCustom => 'Custom';

  @override
  String recurrenceEveryNDays(int count) {
    return 'Every $count days';
  }

  @override
  String get recurrenceInterval => 'Interval (days)';

  @override
  String get notifySettings => 'Notifications';

  @override
  String get notifyOnDue => 'On due date';

  @override
  String get notifyOneDayBefore => '1 day before';

  @override
  String get notifyThreeDaysBefore => '3 days before';

  @override
  String get notifyOneWeekBefore => '1 week before';

  @override
  String get premiumOnly => 'Premium only';

  @override
  String recurringTaskCreated(String date) {
    return 'Next task created: $date';
  }

  @override
  String get aiResultTitle => 'AI has organized your tasks';

  @override
  String aiResultSortedAt(String dateTime) {
    return 'Sorted at: $dateTime';
  }

  @override
  String get aiPriorityUrgent => '🔴 Focus on these today';

  @override
  String get aiPriorityWarning => '🟠 Get it done this week';

  @override
  String get aiPriorityNormal => '🔵 Next week is fine';

  @override
  String get aiPriorityRelaxed => '⚪ Keep in mind';

  @override
  String get backToHome => 'Back to Home';

  @override
  String aiSortRemaining(int count) {
    return '$count remaining';
  }

  @override
  String get aiSortLimitReached => 'You\'ve used all free AI sorts this month';

  @override
  String get aiSortDailyLimitReached => 'You\'ve reached today\'s limit';

  @override
  String get aiSortUpgradeToPremium => 'Upgrade to Premium';

  @override
  String get aiSortWatchAd => 'Watch ad to use';

  @override
  String get aiSortNoTasks => 'No tasks to organize';

  @override
  String get aiErrorNetwork => 'Connection failed. Please check your network';

  @override
  String get aiErrorParse =>
      'Could not process AI response. Sorted by due date instead';

  @override
  String get aiErrorRateLimit => 'Please try again later';

  @override
  String get aiSorting => 'AI is organizing...';

  @override
  String get notificationTitle => 'YaruNavi';

  @override
  String notifyDueToday(String taskName) {
    return '$taskName is due today';
  }

  @override
  String notifyDueInDays(String taskName, int count) {
    return '$taskName is due in $count days';
  }

  @override
  String notifyRecurring(String taskName) {
    return 'It\'s time for $taskName';
  }

  @override
  String get addToCalendar => 'Add to Calendar';

  @override
  String get calendarPermissionDenied => 'Please allow calendar access';

  @override
  String get calendarAddFailed => 'Failed to add to calendar';

  @override
  String get storePremiumTitle => 'Premium Plan';

  @override
  String get storeFeatureAiUnlimited => 'Unlimited AI Sort (Free: 3/month)';

  @override
  String get storeFeatureTaskUnlimited => 'Unlimited Tasks (Free: 10)';

  @override
  String get storeFeatureRecurringUnlimited =>
      'Unlimited Recurring Tasks (Free: 1)';

  @override
  String get storeFeatureCategoryUnlimited => 'Unlimited Categories (Free: 2)';

  @override
  String get storeFeatureCalendar => 'Calendar Export';

  @override
  String get storeFeatureNotification =>
      'Due Date Notifications (Free: in-app only)';

  @override
  String get storeFeatureNoAds => 'No Ads';

  @override
  String get storeMonthlyPrice => '¥580/mo';

  @override
  String get storeYearlyPrice => '¥4,200/yr (¥350/mo, save 40%)';

  @override
  String get storeMonthlyTrial => '7-day free trial → then ¥580/mo';

  @override
  String get storeYearlyTrial => '7-day free trial → then ¥4,200/yr';

  @override
  String get storeAutoRenewWarning1 =>
      'You will be charged after the free trial ends';

  @override
  String get storeAutoRenewWarning2 =>
      'Cancel anytime. No charge if cancelled during free trial';

  @override
  String get storeRestore => 'Restore Purchases';

  @override
  String get storePurchaseSuccess => 'You are now a Premium member!';

  @override
  String get storePurchaseFailed => 'Purchase failed. Please try again';

  @override
  String get storeRestoreSuccess => 'Purchases restored';

  @override
  String get storeRestoreNone => 'No purchases to restore';

  @override
  String get storeAlreadyPremium => 'Premium Active';

  @override
  String get storeStoreUnavailable => 'Store is unavailable';

  @override
  String get onboardingTitle1 => 'Just enter a task and deadline';

  @override
  String get onboardingDesc1 =>
      'No complicated setup needed.\nJust enter a task name and due date\nto get started right away.';

  @override
  String get onboardingTitle2 => 'AI organizes your priorities';

  @override
  String get onboardingDesc2 =>
      '\"What should I do first?\"\nAI figures it out for you.\nSuggests the best order based on deadlines.';

  @override
  String get onboardingTitle3 => 'Get notified when it\'s time';

  @override
  String get onboardingDesc3 =>
      'Push notifications as deadlines approach.\nNever forget again.\nAllow notifications to stay on track.';

  @override
  String get onboardingSkip => 'Skip';

  @override
  String get onboardingNext => 'Next';

  @override
  String get onboardingStart => 'Get Started';

  @override
  String get settingsAccount => 'Account';

  @override
  String get settingsPremiumStatus => 'Premium Status';

  @override
  String get settingsPremiumActive => 'Premium Active';

  @override
  String get settingsFreeUser => 'Free Plan';

  @override
  String get settingsUpgradeToPremium => 'Upgrade to Premium';

  @override
  String get settingsDefaultNotify => 'Default Notification Timing';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsJapanese => '日本語';

  @override
  String get settingsEnglish => 'English';

  @override
  String get settingsTheme => 'Theme';

  @override
  String get settingsExportCsv => 'Export CSV';

  @override
  String get settingsExportSuccess => 'CSV exported successfully';

  @override
  String get settingsExportFailed => 'Export failed';

  @override
  String get settingsDeleteAllData => 'Delete All Data';

  @override
  String get settingsDeleteAllConfirmTitle => 'Confirm Delete All';

  @override
  String get settingsDeleteAllConfirmMessage =>
      'All tasks and data will be permanently deleted. This cannot be undone. Are you sure?';

  @override
  String get settingsDeleteAllSuccess => 'All data deleted';

  @override
  String get settingsVersion => 'Version';

  @override
  String get settingsLicenses => 'Licenses';

  @override
  String get estimatedTime => 'Estimated Time';

  @override
  String get estimatedTimeNone => 'Not set';

  @override
  String get estimatedTime5min => '5 min';

  @override
  String get estimatedTime30min => '30 min';

  @override
  String get estimatedTime1hour => '1 hour';

  @override
  String get estimatedTimeHalfDay => 'Half day';

  @override
  String get estimatedTime1day => '1 day';

  @override
  String get importance => 'Importance';

  @override
  String get importanceLow => 'Low';

  @override
  String get importanceMedium => 'Medium';

  @override
  String get importanceHigh => 'High';

  @override
  String get memoHint =>
      'Adding details improves AI sorting (e.g., city hall, weekdays only)';

  @override
  String get notifyAiAuto => 'AI Auto';

  @override
  String get notifyManual => 'Manual';

  @override
  String get aiSubtaskSuggestion => 'Break it down?';

  @override
  String get aiSubtaskAdd => 'Add these subtasks';

  @override
  String get aiSubtaskAdded => 'Subtasks added';

  @override
  String get aiCompleteOriginal => 'Mark the original task as complete?';

  @override
  String get aiNotifyUpdated => 'AI set notification dates';

  @override
  String get calendarView => 'Calendar';

  @override
  String get listView => 'List';

  @override
  String get debugSection => 'Debug';

  @override
  String get debugInsertTestData => 'Insert Test Data';

  @override
  String get debugDeleteAndInsertTestData => 'Delete All & Insert Test Data';

  @override
  String get debugTestDataInserted => 'Test data inserted';

  @override
  String get debugConfirmInsert => 'Insert test data?';

  @override
  String get debugConfirmDeleteAndInsert =>
      'Delete all data and insert test data?';

  @override
  String get aiTodayPlan => 'Today\'s Plan';

  @override
  String aiTodayTasks(int count) {
    return 'Today: $count';
  }

  @override
  String aiWeekTasks(int count) {
    return 'This week: $count';
  }

  @override
  String aiLaterTasks(int count) {
    return 'Later: $count';
  }

  @override
  String get aiViewSchedule => 'View organized schedule';

  @override
  String get aiQuestions => 'Questions from AI';

  @override
  String get aiAnswerAndResort => 'Answer and re-sort';

  @override
  String get aiAnswerHint => 'Type your answer...';

  @override
  String get aiNotifySchedule => 'Notification schedule';

  @override
  String get aiLoadingAnalyze => 'Analyzing tasks...';

  @override
  String get aiLoadingPriority => 'Determining priorities...';

  @override
  String get aiLoadingNotify => 'Optimizing notifications...';

  @override
  String get aiLoadingAdvice => 'Creating advice for you...';

  @override
  String get aiLoadingAlmost => 'Almost done...';

  @override
  String get aiRunBackground => 'Run in background';

  @override
  String get aiCompleteNotify => 'AI sorting is complete. Check the results!';

  @override
  String get aiCompleteBanner => 'AI sorting complete — tap to view';

  @override
  String get aiHistory => 'AI Sort History';

  @override
  String get aiHistoryEmpty => 'No AI sort history';

  @override
  String aiHistoryCount(int count) {
    return 'Sorted $count tasks';
  }

  @override
  String get storeRecommended => 'Recommended';
}
