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
  String get aiPriorityUrgent => 'Do today';

  @override
  String get aiPriorityWarning => 'This week';

  @override
  String get aiPriorityNormal => 'Next week+';

  @override
  String get aiPriorityRelaxed => 'Later';

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
  String get aiSorting => 'Sorting…';

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
  String get storeFeatureAiUnlimited => '30 AI sorts / month (free: 2)';

  @override
  String get storeFeatureTaskUnlimited => 'Unlimited tasks';

  @override
  String get storeFeatureRecurringUnlimited => 'Unlimited recurring tasks';

  @override
  String get storeFeatureCategoryUnlimited => 'Unlimited categories';

  @override
  String get storeFeatureCalendar => 'Calendar export';

  @override
  String get storeFeatureNotification => 'Auto-scheduled notifications';

  @override
  String get storeFeatureNoAds => 'No ads';

  @override
  String get storeMonthlyPrice => '¥580/mo';

  @override
  String get storeYearlyPrice => '¥4,200/yr';

  @override
  String get storeYearlySub => '¥350/mo · save 40%';

  @override
  String get storeMonthlyPlanTitle => 'Monthly';

  @override
  String get storeYearlyPlanTitle => 'Yearly';

  @override
  String get storeMonthlyTrial => '7-day free trial';

  @override
  String get storeYearlyTrial => '7-day free trial';

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
  String get ob2BeforeDate2 => 'May 15';

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
  String get ob2BeforeDate5 => 'May 20';

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
  String get ob2AfterComment2 => 'Wrap it up by May 13. Online banking is easy';

  @override
  String get ob2AfterTask3 => 'Buy groceries';

  @override
  String get ob2AfterComment3 => 'Batch your shopping on the weekend of May 17';

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
  String get ob5PremiumAi => '30/month';

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
      '30 AI sorts/month, auto-notifications, calendar sync, no ads';

  @override
  String get aiPremiumBannerButton => 'Start 7-day free trial →';

  @override
  String get aiLimitUpgradeHint => 'Want more AI sorting?';

  @override
  String get aiLimitUpgradeDesc =>
      'Premium gives you 30 AI sorts/month, auto-notifications, and calendar sync';

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
  String get premiumGateTitle => 'Notifications & Calendar are Premium';

  @override
  String get premiumGateDesc =>
      'Upgrade to Premium for AI-suggested notifications, calendar sync, ad-free experience, and 30 AI sorts per month.';

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
  String get aiCommentLockedHint => 'AI comments are Premium';

  @override
  String recommendedDateHint(String date) {
    return 'Best to do on $date';
  }

  @override
  String get calendarSectionRecommended => 'Do on this day';

  @override
  String get calendarSectionDue => 'Due on this day';

  @override
  String get taskCardEdit => 'Edit';

  @override
  String get aiAutoNotifyHintFull => 'Premium auto-sets reminder days';

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
  String get debugSection => 'Test Data';

  @override
  String get debugSimpleData => 'Simple Data';

  @override
  String get debugSimpleDataDesc => 'Title and due date only (5 tasks)';

  @override
  String get debugDetailedData => 'Detailed Data';

  @override
  String get debugDetailedDataDesc => 'All fields populated (10 tasks)';

  @override
  String get debugEdgeCaseData => 'Edge Case Data';

  @override
  String get debugEdgeCaseDataDesc =>
      'Boundary values & special patterns (8 tasks)';

  @override
  String get debugConfirmInsert =>
      'Delete all existing tasks and insert test data?';

  @override
  String get debugConfirmInsertAction => 'Insert';

  @override
  String get debugTestDataInserted => 'Test data inserted';

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
  String get allCompleteSubtitle => 'Add what\'s next';

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
  String get todaySectionEmpty => 'Nothing to do today';

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
  String get calendarViewRecommended => 'AI plan day';

  @override
  String get calendarViewDue => 'Due day';

  @override
  String get calendarViewRecommendedTooltip =>
      'Show tasks on the day AI suggests starting them';

  @override
  String get calendarViewDueTooltip => 'Show tasks on their due dates';

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
      'Premium: notifications & calendar are auto too';

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

  @override
  String get settingsAiSection => 'AI Sort';

  @override
  String get executionTimingLabel => 'Execution Timing';

  @override
  String get executionTimingDeadline => 'Last minute';

  @override
  String get executionTimingEarly => 'Early';

  @override
  String get executionTimingDesc0 => 'Right before deadline';

  @override
  String get executionTimingDesc1 => 'Slightly closer to deadline';

  @override
  String get executionTimingDesc2 => 'Balanced';

  @override
  String get executionTimingDesc3 => 'Slightly early';

  @override
  String get executionTimingDesc4 => 'Well ahead of deadline';

  @override
  String recommendedDateEditHint(String date) {
    return 'Best on $date';
  }

  @override
  String get recommendedDateManual => 'Recommended date (manual)';

  @override
  String get recommendedDateAiSet => 'Recommended date';

  @override
  String get recommendedDateNotSet => 'Set after AI sort';

  @override
  String get manualDateOverwriteTitle => 'Manual dates found';

  @override
  String manualDateOverwriteMessage(int count) {
    return '$count task(s) have manually set dates. Overwrite with AI suggestions?';
  }

  @override
  String get manualDateOverwriteAll => 'Overwrite all';

  @override
  String get manualDateKeep => 'Keep manual';

  @override
  String get weekTabThisWeek => 'This Week';

  @override
  String get weekTabNextWeek => 'Next Week';

  @override
  String get weekTabLater => 'Later';

  @override
  String weekTabCount(String label, int count) {
    return '$label ($count)';
  }

  @override
  String get noTasksNextWeek => 'No tasks next week';

  @override
  String get noTasksLater => 'No tasks after next week';

  @override
  String get calendarHintBubble => 'Check execution dates on calendar →';

  @override
  String get aiSortExecute => 'Run AI Sort';

  @override
  String get aiHistoryLabel => 'AI History';

  @override
  String get settingsSound => 'Sound';

  @override
  String get settingsSoundDesc => 'Play a sound effect when tasks complete';

  @override
  String get aiErrorNetworkTitle => 'Couldn\'t connect';

  @override
  String get aiErrorNetworkBody =>
      'Please check your internet connection and try again.';

  @override
  String get aiErrorApiTitle => 'AI sort could not run';

  @override
  String get aiErrorApiBody => 'Please wait a moment and try again.';

  @override
  String get aiErrorRateLimitTitle => 'Request limit reached';

  @override
  String get aiErrorRateLimitBody => 'Please wait a moment and try again.';

  @override
  String get aiErrorClose => 'Close';

  @override
  String get recurringGuideTitle => 'Make this a recurring task?';

  @override
  String recurringGuideMessage(String taskName) {
    return 'Is \"$taskName\" monthly?';
  }

  @override
  String get recurringGuideDescription =>
      'Recurring tasks will be created automatically each month.';

  @override
  String get recurringGuideAccept => 'Set as recurring';

  @override
  String get recurringGuideDecline => 'Just this once';

  @override
  String get recurringGuideApplied => 'Set as recurring task';

  @override
  String get allCompleteNextPrompt => 'Want to add what\'s next?';

  @override
  String get devModeAnimationsPreview => 'Animation Preview';

  @override
  String get devModeAnimationsPreviewDesc =>
      'Replay AI sort, all-complete, burst and confetti independently';

  @override
  String get calendarLegendUrgent => 'Urgent';

  @override
  String get calendarLegendWeek => 'This week';

  @override
  String get calendarLegendLater => 'Later';

  @override
  String get calendarLegendUnsorted => 'Unsorted';

  @override
  String get devModeUseNewUi => 'Enable redesigned UI';

  @override
  String get devModeUseNewUiDesc =>
      'Use the new design preview (home screen and more)';

  @override
  String get heroTodayMission => 'Today\'s progress';

  @override
  String get aiSortHeroCta => 'Sort today with AI';

  @override
  String get statsTitle => 'Stats';

  @override
  String get statsStreakActive => 'Streak';

  @override
  String statsStreakDays(int n) {
    return '$n days';
  }

  @override
  String get statsLongest => 'Best';

  @override
  String get statsDone => 'Done';

  @override
  String get statsWeek => 'Week';

  @override
  String get statsPast14Days => 'Past 14 days';

  @override
  String statsLevelXp(int cur, int next) {
    return '$cur / $next XP';
  }

  @override
  String get statsBadges => 'Badges';

  @override
  String get statsHelpTooltip => 'How it works';

  @override
  String get gamificationHelpTitle => 'How YaruNavi rewards you';

  @override
  String get gamificationHelpSubtitle =>
      'A simple level system that rewards consistent use';

  @override
  String get gamificationHelpXpTitle => 'Earn XP and level up';

  @override
  String get gamificationHelpXpBody =>
      '+10 XP per done task, +5 XP for AI sort, +25 XP bonus for clearing today.';

  @override
  String get gamificationHelpStreakTitle => 'Streak (consecutive days)';

  @override
  String get gamificationHelpStreakBody =>
      'Any activity once a day keeps your streak. Day 3/7/14/30 unlock bonus XP and badges.';

  @override
  String get gamificationHelpLevelTitle => '8 named levels';

  @override
  String get gamificationHelpLevelBody =>
      'Lv.1 First Steps → Lv.5 AI Companion → Lv.8 Legendary Planner. Continues beyond Lv.9.';

  @override
  String get gamificationHelpBadgeTitle => '11 badges to unlock';

  @override
  String get gamificationHelpBadgeBody =>
      'Earn them by completing your first task, hitting 10/50/100 completions, AI first run, streak milestones, level reaches.';

  @override
  String statsNextLevelHint(int xp, int level) {
    return '$xp XP to Lv.$level';
  }

  @override
  String get levelName1 => 'First Step Navigator';

  @override
  String get levelName2 => 'Rookie Planner';

  @override
  String get levelName3 => 'Quick Organizer';

  @override
  String get levelName4 => 'Task Master';

  @override
  String get levelName5 => 'AI\'s Right Hand';

  @override
  String get levelName6 => 'Pro Organizer';

  @override
  String get levelName7 => 'Time Lord';

  @override
  String get levelName8 => 'Legendary Planner';

  @override
  String levelNameHigh(int level) {
    return 'Lv.$level';
  }

  @override
  String get badgeName_first_step => 'First Step';

  @override
  String get badgeDesc_first_step => 'Complete your first task';

  @override
  String get badgeName_streak_3 => 'No More Quitting on Day Three';

  @override
  String get badgeDesc_streak_3 => 'Open the app 3 days in a row';

  @override
  String get badgeName_streak_7 => 'Week-long Habit';

  @override
  String get badgeDesc_streak_7 => 'Open the app 7 days in a row';

  @override
  String get badgeName_streak_14 => 'Fortnight Achieved';

  @override
  String get badgeDesc_streak_14 => 'Open the app 14 days in a row';

  @override
  String get badgeName_streak_30 => 'Monthly Perfect Attendance';

  @override
  String get badgeDesc_streak_30 => 'Open the app 30 days in a row';

  @override
  String get badgeName_ai_first => 'First Brush with AI';

  @override
  String get badgeDesc_ai_first => 'Run AI sort for the first time';

  @override
  String get badgeName_task_10 => 'Steady Hand';

  @override
  String get badgeDesc_task_10 => 'Complete 10 tasks total';

  @override
  String get badgeName_task_50 => 'Half Century';

  @override
  String get badgeDesc_task_50 => 'Complete 50 tasks total';

  @override
  String get badgeName_task_100 => 'Centurion';

  @override
  String get badgeDesc_task_100 => 'Complete 100 tasks total';

  @override
  String get badgeName_level_5 => 'Rookie Planner';

  @override
  String get badgeDesc_level_5 => 'Reach Lv.5';

  @override
  String get badgeName_level_10 => 'Full-fledged Organizer';

  @override
  String get badgeDesc_level_10 => 'Reach Lv.10';

  @override
  String get greetingMorning => 'Good morning';

  @override
  String get greetingAfternoon => 'Good afternoon';

  @override
  String get greetingEvening => 'Good evening';

  @override
  String get navHome => 'Home';

  @override
  String get navCalendar => 'Calendar';

  @override
  String get navStats => 'Stats';

  @override
  String get navSettings => 'Settings';

  @override
  String xpEarned(int xp) {
    return '+$xp XP';
  }

  @override
  String get levelUpTitle => 'Level Up!';

  @override
  String levelUpMessage(int level, String name) {
    return 'Lv.$level $name';
  }

  @override
  String get badgeUnlocked => 'Badge unlocked!';

  @override
  String get sectionNow => 'Today';

  @override
  String get sectionUpcoming => 'This/Next week';

  @override
  String get sectionThisWeek => 'This week';

  @override
  String get sectionLater => 'Next week & later';

  @override
  String get sectionEmptyNow => 'Nothing to do today';

  @override
  String get sectionEmptyThisWeek => 'No plans this week';

  @override
  String get sectionEmptyLater => 'No upcoming plans';

  @override
  String get taskDetailCountdown => 'Time left';

  @override
  String get taskCompleteAction => 'Mark complete';

  @override
  String get aiResultStartCta => 'Start with this order';

  @override
  String get aiResultRetryCta => 'Re-run';

  @override
  String get aiResultNowLabel => 'Today';

  @override
  String get aiResultWeekLabel => 'This week';

  @override
  String get aiResultLaterLabel => 'Next week+';

  @override
  String get aiResultOptimized => 'All sorted';

  @override
  String get premiumYearlyCta => 'Start yearly plan';

  @override
  String get premiumMonthlyCta => 'Start monthly plan';

  @override
  String get premiumTrialCopy => '7-day free trial · cancel anytime';

  @override
  String get calendarExecutionDate => 'Plan date';

  @override
  String get calendarDueDate => 'Due date';

  @override
  String get onbV2WelcomeBadge => 'AI Navigator';

  @override
  String get onbV2WelcomeTitlePart1 => 'What\'s the ';

  @override
  String get onbV2WelcomeTitleAccent => 'next move?';

  @override
  String get onbV2WelcomeTitlePart2 => '';

  @override
  String get onbV2WelcomeBody =>
      'Just drop in what\'s on your mind.\nNavi sorts it out and tells you\nthe one task to tackle next.';

  @override
  String get onbV2BeforeAfterTitle => 'Clear the mental clutter';

  @override
  String get onbV2BeforeAfterSub =>
      'Navi doesn\'t just list — it picks\nthe one thing you should do now.';

  @override
  String get onbV2BeforeLabel => 'Before';

  @override
  String get onbV2BeforeCaption => 'Where do I even start?';

  @override
  String get onbV2BeforeTask1 => 'Submit weekly report';

  @override
  String get onbV2BeforeTask2 => 'Pay rent';

  @override
  String get onbV2BeforeTask3 => 'Grocery run';

  @override
  String get onbV2BeforeDate1 => 'Today';

  @override
  String get onbV2BeforeDate2 => 'May 15';

  @override
  String get onbV2BeforeDate3 => 'May 20';

  @override
  String get onbV2NaviArrow => 'Sort with AI';

  @override
  String get onbV2AfterLabel => 'After';

  @override
  String get onbV2AfterCaption => 'Now the next step is obvious';

  @override
  String get onbV2AfterBadgeUrgent => 'Now';

  @override
  String get onbV2AfterBadgeWeek => 'This week';

  @override
  String get onbV2AfterBadgeLater => 'Later';

  @override
  String get onbV2AfterTask1 => 'Submit weekly report';

  @override
  String get onbV2AfterTask2 => 'Pay rent';

  @override
  String get onbV2AfterTask3 => 'Grocery run';

  @override
  String get onbV2AfterComment1 => 'Knock it out in the morning';

  @override
  String get onbV2AfterComment2 => 'Use online banking by Friday';

  @override
  String get onbV2AfterComment3 => 'Stock up on the weekend';

  @override
  String get onbV2GameTitle => 'The more you go, the more it gives back';

  @override
  String get onbV2GameSub => 'Tiny wins become real motivation';

  @override
  String get onbV2GameXpTitle => '+10 XP for every task done';

  @override
  String get onbV2GameXpSub => 'Clear today\'s list for a +25 bonus';

  @override
  String get onbV2GameStreakTitle => 'Your streak flame grows';

  @override
  String get onbV2GameStreakSub => 'Day 3 · 7 · 30 unlock special badges';

  @override
  String get onbV2GameLevelTitle => 'Level up your title';

  @override
  String get onbV2GameLevelSub => 'From Navi Rookie to Legendary Planner';

  @override
  String get onbV2GameFooter =>
      'You don\'t have to be perfect —\njust stack one small win each day.';

  @override
  String get onbV2CtaTitle => 'Ready when you are.';

  @override
  String get onbV2CtaBody =>
      'Add the one thing nagging at you.\nFrom there, Navi takes the wheel.';

  @override
  String get onbV2CtaButton => 'Add my first task';

  @override
  String get homeQuickTotalLabel => 'All tasks';

  @override
  String get homeQuickTotalUnit => '';

  @override
  String homeNextHint(String date, int count) {
    return 'Next: $count on $date';
  }

  @override
  String get homeNoUpcoming => 'No open tasks';

  @override
  String get homeJumpAll => 'See all';

  @override
  String homeOverdueChip(int count) {
    return '$count overdue';
  }

  @override
  String get calendarMonthListMode => 'List';

  @override
  String get calendarGridMode => 'Month';

  @override
  String get calendarMonthAllTasks => 'This month';

  @override
  String calendarNoTasksNextHint(String date, int count) {
    return 'Free day. Next is $count on $date';
  }

  @override
  String get calendarJumpToNext => 'Jump to next';

  @override
  String get calendarMonthEmpty => 'No tasks scheduled this month';

  @override
  String get aiResultOptimizedBadge => 'Sorted by AI';

  @override
  String get aiNaviNoteLabel => 'A note from Navi';

  @override
  String get aiNaviAdviceLabel => 'Navi\'s advice';

  @override
  String get aiNaviAdviceBadge => 'AI advice';

  @override
  String aiSortQuotaFree(int remaining, int total) {
    return 'Free: $remaining/$total sorts left';
  }

  @override
  String aiSortQuotaPremium(int remaining, int total) {
    return 'This month: $remaining/$total left';
  }

  @override
  String archiveOpenButton(int count) {
    return 'See older ($count)';
  }

  @override
  String get archiveTitle => 'Completed archive';

  @override
  String get archiveEmpty => 'No archived completions yet';

  @override
  String get archiveRecentLabel => 'Past 7 days';

  @override
  String streakMilestoneTitle(int days) {
    return '$days-day streak!';
  }

  @override
  String get streakMilestoneBody => 'Awesome — keep stacking small wins.';

  @override
  String taskCompletedOn(String date) {
    return 'Done $date';
  }

  @override
  String get calendarLegendDone => 'Done';

  @override
  String get executionTimingHint =>
      'How AI picks the day to start each task. \'Deadline\' keeps it close to the due date; \'Early\' gives more buffer.';

  @override
  String get archiveEmptyHint =>
      'Tasks completed more than 7 days ago show up here';

  @override
  String get archiveEmptyCta => 'Back to home';

  @override
  String get uncompleteTask => 'Mark active';

  @override
  String get taskUncompletedSnack => 'Task moved back to active';

  @override
  String get undo => 'Undo';

  @override
  String get deleteHistory => 'Clear history';

  @override
  String get deleteHistoryConfirmTitle => 'Delete this entry?';

  @override
  String get deleteHistoryConfirmBody =>
      'The selected completed task will be removed. This cannot be undone.';

  @override
  String get deleteAllHistoryConfirmTitle => 'Clear all completed history?';

  @override
  String get deleteAllHistoryConfirmBody =>
      'All completed task history will be removed. This cannot be undone.';

  @override
  String get deleteAllAction => 'Delete all';

  @override
  String historyDeletedSnack(int count) {
    return '$count entries deleted';
  }

  @override
  String get scheduleSection => 'Task schedule';

  @override
  String get scheduleBusynessLabel =>
      'How busy each weekday is (1 = free, 5 = busy)';

  @override
  String get blockedDatesLabel => 'Days I can\'t work on tasks';

  @override
  String get blockedDatesAdd => 'Add date';

  @override
  String get blockedDatesEmpty => 'None set';

  @override
  String get weekdayMonShort => 'Mon';

  @override
  String get weekdayTueShort => 'Tue';

  @override
  String get weekdayWedShort => 'Wed';

  @override
  String get weekdayThuShort => 'Thu';

  @override
  String get weekdayFriShort => 'Fri';

  @override
  String get weekdaySatShort => 'Sat';

  @override
  String get weekdaySunShort => 'Sun';

  @override
  String get levelName9 => 'Task Sage';

  @override
  String get levelName10 => 'Ultimate Organizer';

  @override
  String get levelName15 => 'Task Devotee';

  @override
  String get levelName20 => 'Philosopher of Order';

  @override
  String get levelName30 => 'Emperor of Efficiency';

  @override
  String get levelName50 => 'A Living Legend of Tasks';

  @override
  String get levelName70 => 'Transcender of Time';

  @override
  String get levelName100 => '∞ Infinite Planner';

  @override
  String get badgeName_task_25 => 'Skilled Juggler';

  @override
  String get badgeDesc_task_25 => 'Complete 25 tasks total';

  @override
  String get badgeName_task_250 => 'Task Hunter';

  @override
  String get badgeDesc_task_250 => 'Complete 250 tasks total';

  @override
  String get badgeName_task_500 => 'Peak of 500';

  @override
  String get badgeDesc_task_500 => 'Complete 500 tasks total';

  @override
  String get badgeName_task_1000 => 'Mark of a Thousand';

  @override
  String get badgeDesc_task_1000 => 'Complete 1000 tasks total';

  @override
  String get badgeName_streak_60 => 'Iron Will';

  @override
  String get badgeDesc_streak_60 => 'Open the app 60 days in a row';

  @override
  String get badgeName_streak_100 => 'It\'s a Lifestyle Now';

  @override
  String get badgeDesc_streak_100 => 'Open the app 100 days in a row';

  @override
  String get badgeName_ai_10 => 'AI Regular';

  @override
  String get badgeDesc_ai_10 => 'Run AI sort 10 times';

  @override
  String get badgeName_ai_50 => 'AI Sort Aficionado';

  @override
  String get badgeDesc_ai_50 => 'Run AI sort 50 times';

  @override
  String get badgeName_level_20 => 'Devotee of Efficiency';

  @override
  String get badgeDesc_level_20 => 'Reach Lv.20';

  @override
  String get badgeName_level_30 => 'Legendary Organizer';

  @override
  String get badgeDesc_level_30 => 'Reach Lv.30';

  @override
  String get badgeName_early_bird => 'Early Bird Catches the Task';

  @override
  String get badgeDesc_early_bird => 'Complete a task before 6am';

  @override
  String get badgeName_night_owl => 'Midnight Task Runner';

  @override
  String get badgeDesc_night_owl => 'Complete a task between 0 and 3 am';

  @override
  String get badgeName_busy_day_5 => 'Cram It All In One Day';

  @override
  String get badgeDesc_busy_day_5 => 'Complete 5+ tasks in a single day';

  @override
  String get badgeName_busy_day_10 => 'A Stormy Day';

  @override
  String get badgeDesc_busy_day_10 => 'Complete 10+ tasks in a single day';

  @override
  String get badgeName_busy_month_30 => 'Monthly Marathon Runner';

  @override
  String get badgeDesc_busy_month_30 => 'Complete 30+ tasks in a month';

  @override
  String get badgeName_back_from_hibernation => 'Back from Hibernation';

  @override
  String get badgeDesc_back_from_hibernation =>
      'Complete a task after 60+ days of silence';

  @override
  String get badgeName_long_time_no_see => 'Long Time No See';

  @override
  String get badgeDesc_long_time_no_see => 'Open the app after 30+ days away';

  @override
  String get badgeName_category_master => 'Tidiness Master';

  @override
  String get badgeDesc_category_master => 'Create 5+ categories';

  @override
  String get badgeName_habit_demon => 'Demon of Habit';

  @override
  String get badgeDesc_habit_demon => 'Register 5+ recurring tasks';

  @override
  String get badgeName_schedule_master => 'Schedule Master';

  @override
  String get badgeDesc_schedule_master =>
      'Change weekday busyness for the first time';

  @override
  String get badgeName_zero_overdue => 'Inbox Zero State of Mind';

  @override
  String get badgeDesc_zero_overdue => 'Bring overdue tasks down to zero';

  @override
  String get badgeName_multi_tasker => 'Multitasker';

  @override
  String get badgeDesc_multi_tasker =>
      'Complete tasks in 3+ different categories';

  @override
  String get badgeName_ticket_buyer => 'AI Ticket Believer';

  @override
  String get badgeDesc_ticket_buyer =>
      'Purchase an AI sort ticket for the first time';

  @override
  String get badgeName_weekend_warrior => 'Weekend Warrior';

  @override
  String get badgeDesc_weekend_warrior =>
      'Complete 5+ tasks across Saturday and Sunday';

  @override
  String get badgeName_perfect_week => 'Perfect Week';

  @override
  String get badgeDesc_perfect_week =>
      'Complete at least 1 task every day for a week';

  @override
  String get badgeName_level_50 => 'A Living Legend of Tasks';

  @override
  String get badgeDesc_level_50 => 'Reach Lv.50';

  @override
  String get badgeName_level_70 => 'Transcender of Time';

  @override
  String get badgeDesc_level_70 => 'Reach Lv.70';

  @override
  String get badgeName_level_100 => '∞ The Impossible Made Possible';

  @override
  String get badgeDesc_level_100 => 'Reach Lv.100';

  @override
  String get badgeHidden => '???';

  @override
  String get badgeHiddenLabel => 'Hidden';

  @override
  String get aiReminderToggle => 'Sort reminders';

  @override
  String get aiReminderToggleDesc =>
      'Evening nudge when tasks pile up (once a day)';

  @override
  String get aiPurchaseSheetTitle => 'Keep AI sorting';

  @override
  String get aiPurchaseSheetBody =>
      'You\'re out of free runs today. Pick how to continue.';

  @override
  String get aiPurchasePremiumTitle => 'Premium ¥580/mo';

  @override
  String get aiPurchasePremiumSubtitle =>
      '30 AI sorts/month + every feature unlocked';

  @override
  String get aiPurchaseTicketTitle => 'AI sort ticket ¥120';

  @override
  String aiPurchaseTicketSubtitle(int remaining, int max) {
    return 'Add 1 run ($remaining of $max left to buy)';
  }

  @override
  String get aiPurchaseTicketDisabled => 'Ticket limit reached';

  @override
  String get aiPurchaseRewardedTitle => 'Watch a video (1×/day)';

  @override
  String get aiPurchaseRewardedSubtitle => 'See a short ad for today\'s run';
}
