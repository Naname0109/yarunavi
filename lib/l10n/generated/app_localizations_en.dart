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
  String get onboardingSkip => 'Skip';

  @override
  String get onboardingNext => 'Next';

  @override
  String get onboardingStart => 'Get Started';

  @override
  String get ob1Title => 'Just add your tasks';

  @override
  String get ob1Desc =>
      'Enter a task name and due date.\nYou can add notes too.';

  @override
  String get ob1Sub => 'Get everything out of your head';

  @override
  String get ob1Task1 => 'Pay rent';

  @override
  String get ob1Task2 => 'Renew license';

  @override
  String get ob1Task3 => 'Buy groceries';

  @override
  String get ob1Task4 => 'Tax filing prep...';

  @override
  String get ob2Title => 'AI organizes for you';

  @override
  String get ob2Desc => 'AI prioritizes and gives actionable advice';

  @override
  String get ob2ArrowLabel => 'AI Sort';

  @override
  String get ob2BeforeLabel => 'Before';

  @override
  String get ob2BeforeTask1 => 'Read a book';

  @override
  String get ob2BeforeDate1 => 'May 1';

  @override
  String get ob2BeforeTask2 => 'Pay rent';

  @override
  String get ob2BeforeDate2 => 'Tomorrow';

  @override
  String get ob2BeforeTask3 => 'Renew passport';

  @override
  String get ob2BeforeDate3 => 'May 20';

  @override
  String get ob2BeforeTask4 => 'Weekly report';

  @override
  String get ob2BeforeDate4 => 'Today';

  @override
  String get ob2BeforeTask5 => 'Buy groceries';

  @override
  String get ob2BeforeDate5 => 'Apr 18';

  @override
  String get ob2AfterUrgent => 'Do now';

  @override
  String get ob2AfterWarning => 'This week';

  @override
  String get ob2AfterNormal => 'Next week+';

  @override
  String get ob2AfterRelaxed => 'No rush';

  @override
  String get ob2AfterTask1 => 'Weekly report';

  @override
  String get ob2AfterComment1 => 'Submit today. Morning is best';

  @override
  String get ob2AfterTask2 => 'Pay rent';

  @override
  String get ob2AfterComment2 => 'Due tomorrow. Use online banking today';

  @override
  String get ob2AfterTask3 => 'Buy groceries';

  @override
  String get ob2AfterComment3 => 'Batch your shopping on the weekend';

  @override
  String get ob2AfterTask4 => 'Renew passport';

  @override
  String get ob2AfterComment4 => 'Office is weekdays only. Go next week AM';

  @override
  String get ob2AfterTask5 => 'Read a book';

  @override
  String get ob2AfterComment5 => 'Plenty of time. Weekend relaxation';

  @override
  String get ob3Title => 'See it on the calendar';

  @override
  String get ob3Desc =>
      'See at a glance when to do what.\nAI suggests the best execution days';

  @override
  String get ob3LegendUrgent => 'Urgent';

  @override
  String get ob3LegendWeek => 'This week';

  @override
  String get ob3LegendLater => 'Later';

  @override
  String get ob4Title => 'Never forget';

  @override
  String get ob4Desc =>
      'AI notifies you at the right time.\nOnly on the days you need';

  @override
  String get ob4Sub => 'Quiet on days with nothing to do';

  @override
  String get ob4MockLabel => 'You\'ll get notifications like this';

  @override
  String get ob4Time1 => 'Today 9:00';

  @override
  String get ob4Notify1 => 'Pay rent — Use online banking today';

  @override
  String get ob4Time2 => 'Tomorrow 9:00';

  @override
  String get ob4Notify2 => 'Buy groceries — Check your shopping list';

  @override
  String get ob5Title => 'Do more with Premium';

  @override
  String get ob5Free => 'Free';

  @override
  String get ob5AiSort => 'AI Sort';

  @override
  String get ob5Tasks => 'Tasks';

  @override
  String get ob5Notify => 'Notifications';

  @override
  String get ob5Calendar => 'Calendar';

  @override
  String get ob5AiComment => 'AI Comments';

  @override
  String get ob5Ads => 'Ads';

  @override
  String get ob5Recurring => 'Recurring';

  @override
  String get ob5FreeAi => '2 free + ads';

  @override
  String get ob5FreeTasks => 'Up to 10';

  @override
  String get ob5FreeRecurring => '1';

  @override
  String get ob5FreeAds => 'Yes';

  @override
  String get ob5PremiumAi => '50/month';

  @override
  String get ob5PremiumTasks => 'Unlimited';

  @override
  String get ob5PremiumNotify => 'Auto-set';

  @override
  String get ob5PremiumCalendar => 'Sync';

  @override
  String get ob5PremiumComment => 'Full access';

  @override
  String get ob5PremiumRecurring => 'Unlimited';

  @override
  String get ob5PremiumAds => 'None';

  @override
  String get ob5Price => '\$4.99/mo or \$39.99/yr (save 40%)';

  @override
  String get ob5TrialButton => 'Start 7-day free trial';

  @override
  String get ob5FreeButton => 'Start free';

  @override
  String get ob6Title => 'Let\'s get started';

  @override
  String get ob6Desc => 'Add your tasks and let AI organize them';

  @override
  String get taskLoadError => 'Failed to load tasks';

  @override
  String get aiFallbackNotice =>
      'AI sort encountered an error. Sorted by due date instead';

  @override
  String get aiRewardedAdPrompt => 'You\'ve used all free AI sorts';

  @override
  String get aiRewardedAdDesc =>
      'Watch a video to unlock one AI sort today. Or go premium for unlimited access.';

  @override
  String get aiWatchAdButton => 'Watch & Sort';

  @override
  String get aiRewardedAdNotReady =>
      'Ad not ready yet. Please try again shortly';

  @override
  String get aiRewardedAdUsedToday =>
      'You\'ve already used today\'s video AI sort';

  @override
  String get aiRewardedAdTomorrow =>
      'Come back tomorrow for another free sort, or go premium for unlimited access.';

  @override
  String aiRecommendedPeriod(String period) {
    return 'Recommended: $period';
  }

  @override
  String aiQuestionAnswer(int number, String answer) {
    return 'Answer to Q$number: $answer';
  }

  @override
  String get aiPremiumBannerTitle =>
      'Unlock AI comments, notifications & calendar with Premium';

  @override
  String get aiPremiumBannerDesc =>
      '50 AI sorts/month, auto-notifications, calendar sync, no ads';

  @override
  String get aiPremiumBannerButton => 'Start 7-day free trial →';

  @override
  String get aiLimitUpgradeHint => 'Want more AI sorting?';

  @override
  String get aiLimitUpgradeDesc =>
      'Premium gives you 50 AI sorts/month, auto-notifications, and calendar sync';

  @override
  String get settingsReplayOnboarding => 'Show guide again';

  @override
  String get coachAddTask => 'Add a task from here';

  @override
  String get coachAiSort => 'AI organizes your priorities';

  @override
  String get coachFilterTabs => 'Switch views with tabs';

  @override
  String get coachCalendarToggle => 'Toggle calendar view here';

  @override
  String get coachNext => 'Next';

  @override
  String get coachDone => 'OK';

  @override
  String get tabList => 'Tasks';

  @override
  String get tabCalendar => 'Calendar';

  @override
  String get notifyPremiumOnly => 'Set notifications with Premium';

  @override
  String get notifyPremiumOnlySnack => 'Notifications are a Premium feature';

  @override
  String get proBadge => 'PRO';

  @override
  String get aiNotifyPremiumPrompt => 'Get reminders with Premium';

  @override
  String get aiSortMonthlyLimitReached =>
      'You\'ve hit this month\'s AI sort limit. Resets next month.';

  @override
  String get premiumGateTitle => '🔔 Notifications & 📅 Calendar are Premium';

  @override
  String get premiumGateDesc =>
      'Upgrade to Premium for AI-suggested notifications, calendar sync, ad-free experience, and 50 AI sorts per month.';

  @override
  String get premiumGateUpgrade => 'Upgrade and set it up now';

  @override
  String get premiumGateLater => 'Later';

  @override
  String aiNotifyOn(String date) {
    return 'Notify on $date';
  }

  @override
  String get aiCalendarAdd => 'Add to calendar';

  @override
  String get aiCalendarAdded => 'Added to calendar';

  @override
  String get notifyScheduled => 'Notification scheduled';

  @override
  String get notifyScheduledLabel => 'Reminders';

  @override
  String get aiAutoNotifyHint => 'AI will pick the date when you organize';

  @override
  String get calendarAddedBadge => 'Added to calendar';

  @override
  String get aiNotOrganizedHint => 'Run AI sort to get personalized advice';

  @override
  String get aiCommentLockedHint => 'See AI comment with Premium';

  @override
  String recommendedDateHint(String date) {
    return '📌 Best to do on $date';
  }

  @override
  String get calendarSectionRecommended => '📋 Do on this day';

  @override
  String get calendarSectionDue => '⏰ Due on this day';

  @override
  String get taskCardEdit => 'Edit';

  @override
  String get aiAutoNotifyHintFull =>
      'Premium auto-schedules reminders during AI sort';

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
  String get advancedSettings => 'Advanced Settings';

  @override
  String get estimatedTime => 'Estimated Time';

  @override
  String get estimatedTimeNone => 'Not set';

  @override
  String get estimatedTime15min => '15 min';

  @override
  String get estimatedTime30min => '30 min';

  @override
  String get estimatedTime1hour => '1 hour';

  @override
  String get estimatedTime1_5hour => '1.5 hours';

  @override
  String get estimatedTime2hour => '2 hours';

  @override
  String get estimatedTime3hour => '3 hours';

  @override
  String get estimatedTime4hour => '4 hours';

  @override
  String get estimatedTimeHalfDay => 'Half day';

  @override
  String get estimatedTime1day => '1 day';

  @override
  String get estimatedTimeSeveralDays => 'Several days';

  @override
  String get estimatedTime1weekPlus => '1 week+';

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
  String get debugAiTestData => 'AI Sort Test Data';

  @override
  String get debugAiTestDataTitle => 'Insert AI Test Data (15 fixed tasks)';

  @override
  String get debugAiTestDataDesc =>
      'Delete all data and insert fixed test data for AI evaluation';

  @override
  String get debugAiTestDataConfirm =>
      'Delete all data and insert 15 AI evaluation tasks?';

  @override
  String get debugAiTestDataInserted => 'AI test data (15 tasks) inserted';

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

  @override
  String get calendarNoTasks => 'No tasks for this day';

  @override
  String get calendarToday => 'Today';

  @override
  String get swipeComplete => 'Done';

  @override
  String get swipeDelete => 'Delete';

  @override
  String get swipeUndo => 'Undo';

  @override
  String get reorderHint => 'Long press to drag and reorder';

  @override
  String get categoryManageTitle => 'Manage Categories';

  @override
  String get categoryAdd => 'Add Category';

  @override
  String get categoryEdit => 'Edit Category';

  @override
  String get categoryDefault => 'Default';

  @override
  String get categoryEmpty => 'No categories';

  @override
  String get categoryNameLabel => 'Category Name';

  @override
  String get categoryNameHint => 'e.g. Health, Hobby';

  @override
  String get categoryIconLabel => 'Choose Icon';

  @override
  String get categoryDeleteTitle => 'Delete Category';

  @override
  String get categoryDeleteMessage =>
      'Tasks assigned to this category will become uncategorized. Delete?';

  @override
  String get devModeSection => 'Developer Mode';

  @override
  String get devModeAiUnlimited => 'Ignore AI Limit';

  @override
  String get devModeAiUnlimitedDesc => 'Skip AI sort usage limit';

  @override
  String get devModePremium => 'Unlock Premium';

  @override
  String get devModePremiumDesc => 'Unlock all FeatureGates';

  @override
  String get devModeResetAiUsage => 'Reset AI Usage';

  @override
  String get devModeResetAiUsageDesc => 'Reset current month AI usage count';

  @override
  String get devModeResetAiUsageDone => 'AI usage count reset';

  @override
  String get devModeConfirmResetAiUsage =>
      'Reset this month\'s AI usage count?';

  @override
  String get devModeReviewSection => 'Review';

  @override
  String get devModeTestReview => 'Test review dialog';

  @override
  String get devModeTestReviewDesc => 'Show review dialog ignoring conditions';

  @override
  String get devModeTestReviewTriggered => 'Review dialog requested';

  @override
  String get devModeResetReview => 'Reset review counters';

  @override
  String get devModeResetReviewDesc => 'Reset all review-related counters';

  @override
  String get devModeResetReviewDone => 'Review counters reset';

  @override
  String get devModeEnabled => 'Developer mode enabled';

  @override
  String devModeRemaining(int count) {
    return '$count more taps for developer mode';
  }

  @override
  String get allCompleteTitle => 'All done! Great job';

  @override
  String get allCompleteSubtitle => 'Add new tasks and organize what\'s next';

  @override
  String get allCompleteAddTask => 'Add a Task';

  @override
  String get allCompleteAiSort => 'AI Sort';

  @override
  String get allCompleteNoTaskForAi => 'Add tasks first, then organize with AI';

  @override
  String get allExpiredBannerTitle => 'All task deadlines have passed';

  @override
  String get allExpiredAddTask => 'Add New Task';

  @override
  String get allExpiredUpdateDue => 'Update Deadline';

  @override
  String get allExpiredNotification =>
      'All task deadlines have passed. Add new tasks to stay organized!';

  @override
  String get todaySection => 'Today\'s Tasks';

  @override
  String get todaySectionEmpty => 'Nothing to do today 👍';

  @override
  String get otherTasks => 'Other Tasks';

  @override
  String get thisWeekSection => 'This Week';

  @override
  String get laterSection => 'Later';

  @override
  String laterSectionCount(int count) {
    return 'Later ($count)';
  }

  @override
  String get overdueSection => 'Overdue';

  @override
  String overdueSectionCount(int count) {
    return 'Overdue ($count)';
  }

  @override
  String get aiHistoryTooltip => 'AI Sort History';

  @override
  String executionDateLabel(String date) {
    return 'Do on: $date';
  }

  @override
  String dueDateLabel(String date) {
    return 'Due: $date';
  }

  @override
  String dueDateSub(String date) {
    return '(Due: $date)';
  }

  @override
  String get calendarViewRecommended => 'Planned';

  @override
  String get calendarViewDue => 'Due Date';

  @override
  String taskCount(int count) {
    return '$count total';
  }

  @override
  String get tabTodo => 'To Do';

  @override
  String get aiAutoSettingsComplete =>
      'Auto-configured notifications & calendar';

  @override
  String get aiAutoNotifyOnly => 'Auto-configured notifications';

  @override
  String get aiAutoCalendarPermission => 'Enable calendar sync in settings';

  @override
  String get aiPremiumAutoPrompt =>
      'Premium auto-configures notifications & calendar';

  @override
  String get aiPremiumAutoTrial => 'Start 7-day free trial';

  @override
  String get aiChangeSettings => 'Change settings';

  @override
  String get ob1TitleNew => 'Just enter a task name and due date';

  @override
  String get ob1SubNew => 'That\'s it. Leave the rest to AI';

  @override
  String get ob2TitleNew => 'AI does everything for you';

  @override
  String get ob2SubNew =>
      'Priorities, advice, and notifications — all automatic';

  @override
  String get ob3TitleNew => 'See when to do what at a glance';

  @override
  String get ob4TitleNew => 'Premium: auto notifications & calendar';

  @override
  String get ob4FreeStart => 'Start free';
}
