// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appTitle => 'やるナビ';

  @override
  String get home => 'ホーム';

  @override
  String get settings => '設定';

  @override
  String get addTask => 'タスクを追加';

  @override
  String get editTask => 'タスクを編集';

  @override
  String get taskName => 'タスク名';

  @override
  String get dueDate => '期限日';

  @override
  String get memo => 'メモ';

  @override
  String get category => 'カテゴリ';

  @override
  String get save => '保存';

  @override
  String get cancel => 'キャンセル';

  @override
  String get delete => '削除';

  @override
  String get all => 'すべて';

  @override
  String get today => '今日';

  @override
  String get thisWeek => '今週';

  @override
  String get overdue => '期限切れ';

  @override
  String get completed => '完了済み';

  @override
  String get aiSort => 'AIで整理';

  @override
  String get premium => 'プレミアム';

  @override
  String get store => 'ストア';

  @override
  String get language => '言語';

  @override
  String get theme => 'テーマ';

  @override
  String get lightTheme => 'ライト';

  @override
  String get darkTheme => 'ダーク';

  @override
  String get systemTheme => '端末設定に従う';

  @override
  String get notification => '通知';

  @override
  String get dataManagement => 'データ管理';

  @override
  String get termsOfUse => '利用規約';

  @override
  String get privacyPolicy => 'プライバシーポリシー';

  @override
  String get appInfo => 'アプリ情報';

  @override
  String get deleteConfirmTitle => '削除の確認';

  @override
  String get deleteConfirmMessage => 'このタスクを削除しますか？';

  @override
  String get categoryPayment => 'お金・支払い';

  @override
  String get categoryPaperwork => '手続き・届出';

  @override
  String get categoryShopping => '買い物';

  @override
  String get categoryHousehold => '家事・生活';

  @override
  String get categoryWork => '仕事';

  @override
  String get categoryOther => 'その他';

  @override
  String get emptyTaskMessage => 'タスクを追加しましょう';

  @override
  String get emptyTodayMessage => '今日のタスクはありません';

  @override
  String get emptyWeekMessage => '今週のタスクはありません';

  @override
  String get emptyOverdueMessage => '期限切れのタスクはありません';

  @override
  String get emptyCompletedMessage => '完了済みのタスクはありません';

  @override
  String get tomorrow => '明日';

  @override
  String get yesterday => '昨日';

  @override
  String daysLater(int count) {
    return '$count日後';
  }

  @override
  String daysAgo(int count) {
    return '$count日前';
  }

  @override
  String get markComplete => '完了';

  @override
  String get markIncomplete => '未完了に戻す';

  @override
  String get taskNameRequired => 'タスク名を入力してください';

  @override
  String get selectDate => '日付を選択';

  @override
  String get noCategory => 'なし';

  @override
  String get recurrence => '定期設定';

  @override
  String get recurrenceNone => 'なし';

  @override
  String get recurrenceWeekly => '毎週';

  @override
  String get recurrenceMonthly => '毎月';

  @override
  String get recurrenceYearly => '毎年';

  @override
  String get recurrenceCustom => 'カスタム';

  @override
  String recurrenceEveryNDays(int count) {
    return '$count日ごと';
  }

  @override
  String get recurrenceInterval => '間隔（日数）';

  @override
  String get notifySettings => '通知設定';

  @override
  String get notifyOnDue => '期限日';

  @override
  String get notifyOneDayBefore => '1日前';

  @override
  String get notifyThreeDaysBefore => '3日前';

  @override
  String get notifyOneWeekBefore => '1週間前';

  @override
  String get premiumOnly => 'プレミアム限定';

  @override
  String recurringTaskCreated(String date) {
    return '次回タスクを作成しました: $date';
  }

  @override
  String get aiResultTitle => 'AIが整理しました';

  @override
  String aiResultSortedAt(String dateTime) {
    return '整理日時: $dateTime';
  }

  @override
  String get aiPriorityUrgent => '今日やる';

  @override
  String get aiPriorityWarning => '今週中';

  @override
  String get aiPriorityNormal => '来週以降';

  @override
  String get aiPriorityRelaxed => 'あとで';

  @override
  String get backToHome => 'ホームに戻る';

  @override
  String aiSortRemaining(int count) {
    return '残り$count回';
  }

  @override
  String get aiSortLimitReached => '今月の無料分を使い切りました';

  @override
  String get aiSortDailyLimitReached => '本日の利用回数の上限に達しました';

  @override
  String get aiSortUpgradeToPremium => 'プレミアムに登録';

  @override
  String get aiSortWatchAd => '動画を見て使う';

  @override
  String get aiSortNoTasks => '整理するタスクがありません';

  @override
  String get aiErrorNetwork => '接続に失敗しました。ネットワークを確認してください';

  @override
  String get aiErrorParse => 'AIの応答を処理できませんでした。期限日ベースで整理しました';

  @override
  String get aiErrorRateLimit => 'しばらく時間をおいてお試しください';

  @override
  String get aiSorting => '整理中…';

  @override
  String get notificationTitle => 'やるナビ';

  @override
  String notifyDueToday(String taskName) {
    return '$taskName の期限は今日です';
  }

  @override
  String notifyDueInDays(String taskName, int count) {
    return '$taskName の期限まであと$count日です';
  }

  @override
  String notifyRecurring(String taskName) {
    return '$taskName の時期です';
  }

  @override
  String get addToCalendar => 'カレンダーに追加';

  @override
  String get calendarPermissionDenied => 'カレンダーへのアクセスが許可されていません';

  @override
  String get calendarAddFailed => 'カレンダーへの追加に失敗しました';

  @override
  String get storePremiumTitle => 'プレミアムプラン';

  @override
  String get storeFeatureAiUnlimited => 'AI整理 月30回（無料は2回）';

  @override
  String get storeFeatureTaskUnlimited => 'タスク登録 無制限';

  @override
  String get storeFeatureRecurringUnlimited => '定期タスク 無制限';

  @override
  String get storeFeatureCategoryUnlimited => 'カテゴリ 無制限';

  @override
  String get storeFeatureCalendar => 'カレンダー書き出し';

  @override
  String get storeFeatureNotification => '通知の自動設定';

  @override
  String get storeFeatureNoAds => '広告非表示';

  @override
  String get storeMonthlyPrice => '¥580/月';

  @override
  String get storeYearlyPrice => '¥4,200/年';

  @override
  String get storeYearlySub => '¥350/月相当・40%おトク';

  @override
  String get storeMonthlyPlanTitle => '月額プラン';

  @override
  String get storeYearlyPlanTitle => '年額プラン';

  @override
  String get storeMonthlyTrial => '7日間無料トライアル';

  @override
  String get storeYearlyTrial => '7日間無料トライアル';

  @override
  String get storeAutoRenewWarning1 => '無料体験終了後、自動的に課金されます';

  @override
  String get storeAutoRenewWarning2 => 'いつでもキャンセル可能。無料体験中のキャンセルで課金されません';

  @override
  String get storeRestore => '購入を復元';

  @override
  String get storePurchaseSuccess => 'プレミアムプランに登録しました';

  @override
  String get storePurchaseFailed => '購入に失敗しました。もう一度お試しください';

  @override
  String get storeRestoreSuccess => '購入を復元しました';

  @override
  String get storeRestoreNone => '復元可能な購入が見つかりません';

  @override
  String get storeAlreadyPremium => 'プレミアム登録済み';

  @override
  String get storeStoreUnavailable => 'ストアに接続できません';

  @override
  String get onboardingSkip => 'スキップ';

  @override
  String get onboardingNext => '次へ';

  @override
  String get onboardingStart => 'はじめる';

  @override
  String get ob1Title => 'やることを入れるだけ';

  @override
  String get ob1Desc => 'タスク名と期限を入れるだけ。\nメモも追加できます。';

  @override
  String get ob1Sub => '頭の中のやることを全部ここに';

  @override
  String get ob1Task1 => '家賃振込';

  @override
  String get ob1Task2 => '免許更新';

  @override
  String get ob1Task3 => '日用品買い出し';

  @override
  String get ob1Task4 => '確定申告の書類準備...';

  @override
  String get ob2Title => 'AIが整理してくれる';

  @override
  String get ob2Desc => 'AIが優先順位を判断し、具体的なアドバイス付きで整理';

  @override
  String get ob2ArrowLabel => 'AIで整理';

  @override
  String get ob2BeforeLabel => '整理前';

  @override
  String get ob2BeforeTask1 => '本を読む';

  @override
  String get ob2BeforeDate1 => '5/1';

  @override
  String get ob2BeforeTask2 => '家賃振込';

  @override
  String get ob2BeforeDate2 => '5/15';

  @override
  String get ob2BeforeTask3 => 'パスポート更新';

  @override
  String get ob2BeforeDate3 => '5/20';

  @override
  String get ob2BeforeTask4 => '週報提出';

  @override
  String get ob2BeforeDate4 => '今日';

  @override
  String get ob2BeforeTask5 => '日用品買い出し';

  @override
  String get ob2BeforeDate5 => '5/20';

  @override
  String get ob2AfterUrgent => '今すぐやるべき';

  @override
  String get ob2AfterWarning => '今週中に';

  @override
  String get ob2AfterNormal => '来週以降';

  @override
  String get ob2AfterRelaxed => '急がない';

  @override
  String get ob2AfterTask1 => '週報提出';

  @override
  String get ob2AfterComment1 => '今日中に提出。午前中がおすすめ';

  @override
  String get ob2AfterTask2 => '家賃振込';

  @override
  String get ob2AfterComment2 => '5/13までに済ませよう。ネットバンキングが便利';

  @override
  String get ob2AfterTask3 => '日用品買い出し';

  @override
  String get ob2AfterComment3 => '5/17の週末にまとめ買いが効率的';

  @override
  String get ob2AfterTask4 => 'パスポート更新';

  @override
  String get ob2AfterComment4 => '窓口は平日のみ。来週の午前中に';

  @override
  String get ob2AfterTask5 => '本を読む';

  @override
  String get ob2AfterComment5 => '余裕あり。週末のリラックスタイムに';

  @override
  String get ob3Title => 'カレンダーで実行日が見える';

  @override
  String get ob3Desc => 'いつやるかが一目でわかる。\nAIが最適な実行日を提案します';

  @override
  String get ob3LegendUrgent => '緊急';

  @override
  String get ob3LegendWeek => '今週';

  @override
  String get ob3LegendLater => '来週〜';

  @override
  String get ob4Title => '通知で忘れない';

  @override
  String get ob4Desc => 'AIが最適なタイミングで通知。\n必要な日だけお知らせ';

  @override
  String get ob4Sub => 'やることがない日は静かです';

  @override
  String get ob4MockLabel => 'こんな通知が届きます';

  @override
  String get ob4Time1 => '今日 9:00';

  @override
  String get ob4Notify1 => '家賃振込 — ネットバンキングで今日中に';

  @override
  String get ob4Time2 => '明日 9:00';

  @override
  String get ob4Notify2 => '日用品買い出し — 買い物リストを確認';

  @override
  String get ob5Title => 'プレミアムでもっと便利に';

  @override
  String get ob5Free => '無料';

  @override
  String get ob5AiSort => 'AI整理';

  @override
  String get ob5Tasks => 'タスク';

  @override
  String get ob5Notify => '通知';

  @override
  String get ob5Calendar => 'カレンダー';

  @override
  String get ob5AiComment => 'AIコメント';

  @override
  String get ob5Ads => '広告';

  @override
  String get ob5Recurring => '定期タスク';

  @override
  String get ob5FreeAi => '初回2回+動画';

  @override
  String get ob5FreeTasks => '10件まで';

  @override
  String get ob5FreeRecurring => '1件';

  @override
  String get ob5FreeAds => 'あり';

  @override
  String get ob5PremiumAi => '月30回';

  @override
  String get ob5PremiumTasks => '無制限';

  @override
  String get ob5PremiumNotify => '自動設定';

  @override
  String get ob5PremiumCalendar => '連携可';

  @override
  String get ob5PremiumComment => '全表示';

  @override
  String get ob5PremiumRecurring => '無制限';

  @override
  String get ob5PremiumAds => 'なし';

  @override
  String get ob5Price => '月額¥580 / 年額¥4,200（40%おトク）';

  @override
  String get ob5TrialButton => '7日間無料で試す';

  @override
  String get ob5FreeButton => 'まずは無料で始める';

  @override
  String get ob6Title => 'さあ、始めましょう';

  @override
  String get ob6Desc => 'タスクを追加して、AIに整理してもらおう';

  @override
  String get taskLoadError => 'タスクの読み込みに失敗しました';

  @override
  String get aiFallbackNotice => 'AI整理でエラーが発生しました。期限日ベースで整理しました';

  @override
  String get aiRewardedAdPrompt => '無料のAI整理回数を使い切りました';

  @override
  String get aiRewardedAdDesc => '動画を視聴すると、今日1回AI整理を利用できます。プレミアムなら制限なしで利用できます。';

  @override
  String get aiWatchAdButton => '動画を視聴して整理';

  @override
  String get aiRewardedAdNotReady => '広告の準備ができていません。しばらく待ってからお試しください';

  @override
  String get aiRewardedAdUsedToday => '今日の動画視聴によるAI整理は使用済みです';

  @override
  String get aiRewardedAdTomorrow => '明日またご利用いただけます。プレミアムなら制限なしでいつでも利用できます。';

  @override
  String aiRecommendedPeriod(String period) {
    return '$periodに実行がおすすめ';
  }

  @override
  String aiQuestionAnswer(int number, String answer) {
    return '質問$numberの回答: $answer';
  }

  @override
  String get aiPremiumBannerTitle => 'プレミアムならAIコメント・通知・カレンダーが使えます';

  @override
  String get aiPremiumBannerDesc => 'AI整理 月30回、通知の自動設定、カレンダー連携、広告なし';

  @override
  String get aiPremiumBannerButton => '7日間無料で試す →';

  @override
  String get aiLimitUpgradeHint => 'AIの整理をもっと使いたい方へ';

  @override
  String get aiLimitUpgradeDesc => 'プレミアムならAI整理を月30回、通知の自動設定、カレンダー連携が使えます';

  @override
  String get settingsReplayOnboarding => '操作ガイドを再表示';

  @override
  String get coachAddTask => 'ここからタスクを追加';

  @override
  String get coachAiSort => 'AIがタスクの優先順位を整理します';

  @override
  String get coachFilterTabs => 'タブで表示を切り替えられます';

  @override
  String get coachCalendarToggle => 'カレンダー表示にも切り替えられます';

  @override
  String get coachNext => '次へ';

  @override
  String get coachDone => 'OK';

  @override
  String get tabList => 'タスク';

  @override
  String get tabCalendar => 'カレンダー';

  @override
  String get notifyPremiumOnly => 'プレミアムで通知を設定';

  @override
  String get notifyPremiumOnlySnack => '通知設定はプレミアム機能です';

  @override
  String get proBadge => 'PRO';

  @override
  String get aiNotifyPremiumPrompt => 'プレミアムで通知を受け取れます';

  @override
  String get aiSortMonthlyLimitReached => '今月のAI整理上限に達しました。来月リセットされます';

  @override
  String get premiumGateTitle => '通知 / カレンダー連携はプレミアムで';

  @override
  String get premiumGateDesc =>
      'プレミアムに登録すると、AIが最適な通知日を自動設定、タスクをカレンダーに追加、広告非表示、AI整理を月30回まで利用できます。';

  @override
  String get premiumGateUpgrade => 'プレミアムに登録して今すぐ設定する';

  @override
  String get premiumGateLater => 'あとで';

  @override
  String aiNotifyOn(String date) {
    return '$date に通知する';
  }

  @override
  String get aiCalendarAdd => 'カレンダーに追加';

  @override
  String get aiCalendarAdded => 'カレンダーに追加しました';

  @override
  String get notifyScheduled => '通知をセットしました';

  @override
  String get notifyScheduledLabel => '通知予定';

  @override
  String get aiAutoNotifyHint => 'AIが整理時に通知日を決定します';

  @override
  String get calendarAddedBadge => 'カレンダー追加済み';

  @override
  String get aiNotOrganizedHint => 'AIで整理するとアドバイスが表示されます';

  @override
  String get aiCommentLockedHint => 'AIコメントはプレミアム限定';

  @override
  String recommendedDateHint(String date) {
    return '$date にやるのがおすすめ';
  }

  @override
  String get calendarSectionRecommended => 'この日にやるべきタスク';

  @override
  String get calendarSectionDue => 'この日が期限のタスク';

  @override
  String get taskCardEdit => '編集';

  @override
  String get aiAutoNotifyHintFull => 'プレミアムなら通知日もAIが自動設定';

  @override
  String get settingsAccount => 'アカウント';

  @override
  String get settingsPremiumStatus => 'プレミアムステータス';

  @override
  String get settingsPremiumActive => 'プレミアム有効';

  @override
  String get settingsFreeUser => '無料プラン';

  @override
  String get settingsUpgradeToPremium => 'プレミアムに登録';

  @override
  String get settingsDefaultNotify => 'デフォルト通知タイミング';

  @override
  String get settingsLanguage => '言語';

  @override
  String get settingsJapanese => '日本語';

  @override
  String get settingsEnglish => 'English';

  @override
  String get settingsTheme => 'テーマ';

  @override
  String get settingsExportCsv => 'CSVエクスポート';

  @override
  String get settingsExportSuccess => 'CSVをエクスポートしました';

  @override
  String get settingsExportFailed => 'エクスポートに失敗しました';

  @override
  String get settingsDeleteAllData => '全データ削除';

  @override
  String get settingsDeleteAllConfirmTitle => '全データ削除の確認';

  @override
  String get settingsDeleteAllConfirmMessage =>
      'すべてのタスクとデータが削除されます。この操作は取り消せません。本当に削除しますか？';

  @override
  String get settingsDeleteAllSuccess => '全データを削除しました';

  @override
  String get settingsVersion => 'バージョン';

  @override
  String get settingsLicenses => 'ライセンス';

  @override
  String get advancedSettings => '詳細設定';

  @override
  String get estimatedTime => '所要時間';

  @override
  String get estimatedTimeNone => '未設定';

  @override
  String get estimatedTime15min => '15分';

  @override
  String get estimatedTime30min => '30分';

  @override
  String get estimatedTime1hour => '1時間';

  @override
  String get estimatedTime1_5hour => '1.5時間';

  @override
  String get estimatedTime2hour => '2時間';

  @override
  String get estimatedTime3hour => '3時間';

  @override
  String get estimatedTime4hour => '4時間';

  @override
  String get estimatedTimeHalfDay => '半日';

  @override
  String get estimatedTime1day => '1日';

  @override
  String get estimatedTimeSeveralDays => '数日';

  @override
  String get estimatedTime1weekPlus => '1週間以上';

  @override
  String get importance => '重要度';

  @override
  String get importanceLow => '低';

  @override
  String get importanceMedium => '中';

  @override
  String get importanceHigh => '高';

  @override
  String get memoHint => '詳細を入力するとAIの整理精度が上がります（例: 市役所で手続き、平日のみ対応可）';

  @override
  String get notifyAiAuto => 'AIおまかせ';

  @override
  String get notifyManual => '自分で設定';

  @override
  String get aiSubtaskSuggestion => 'タスクを分割しますか?';

  @override
  String get aiSubtaskAdd => 'この分割で追加';

  @override
  String get aiSubtaskAdded => 'サブタスクを追加しました';

  @override
  String get aiCompleteOriginal => '元のタスクを完了にしますか？';

  @override
  String get aiNotifyUpdated => 'AIが通知日を設定しました';

  @override
  String get calendarView => 'カレンダー';

  @override
  String get listView => 'リスト';

  @override
  String get debugSection => 'テストデータ';

  @override
  String get debugSimpleData => 'シンプルデータ投入';

  @override
  String get debugSimpleDataDesc => 'タスク名と期限のみ（5件）';

  @override
  String get debugDetailedData => '詳細データ投入';

  @override
  String get debugDetailedDataDesc => '全フィールド活用（10件）';

  @override
  String get debugEdgeCaseData => 'エッジケースデータ投入';

  @override
  String get debugEdgeCaseDataDesc => '境界値・特殊パターン（8件）';

  @override
  String get debugConfirmInsert => '既存のタスクを全て削除して、テストデータを投入しますか？';

  @override
  String get debugConfirmInsertAction => '投入する';

  @override
  String get debugTestDataInserted => 'テストデータを投入しました';

  @override
  String get aiTodayPlan => '今日のプラン';

  @override
  String aiTodayTasks(int count) {
    return '今日やること: $count件';
  }

  @override
  String aiWeekTasks(int count) {
    return '今週中: $count件';
  }

  @override
  String aiLaterTasks(int count) {
    return '急がない: $count件';
  }

  @override
  String get aiViewSchedule => '整理後のスケジュールを確認';

  @override
  String get aiQuestions => 'AIからの質問';

  @override
  String get aiAnswerAndResort => '回答してもう一度整理';

  @override
  String get aiAnswerHint => '回答を入力...';

  @override
  String get aiNotifySchedule => '通知予定';

  @override
  String get aiLoadingAnalyze => 'タスクを分析しています...';

  @override
  String get aiLoadingPriority => '優先順位を判断しています...';

  @override
  String get aiLoadingNotify => '通知スケジュールを最適化中...';

  @override
  String get aiLoadingAdvice => 'あなたへのアドバイスを作成中...';

  @override
  String get aiLoadingAlmost => 'もう少しで完了します...';

  @override
  String get aiRunBackground => 'バックグラウンドで実行';

  @override
  String get aiCompleteNotify => 'AI整理が完了しました。結果を確認しましょう';

  @override
  String get aiCompleteBanner => 'AI整理完了 — タップで結果を見る';

  @override
  String get aiHistory => 'AI整理の履歴';

  @override
  String get aiHistoryEmpty => 'AI整理の履歴はありません';

  @override
  String aiHistoryCount(int count) {
    return '$count件のタスクを整理';
  }

  @override
  String get storeRecommended => 'おすすめ';

  @override
  String get calendarNoTasks => 'この日のタスクはありません';

  @override
  String get calendarToday => '今日';

  @override
  String get swipeComplete => '完了';

  @override
  String get swipeDelete => '削除';

  @override
  String get swipeUndo => '戻す';

  @override
  String get reorderHint => '長押しでドラッグして並び替え';

  @override
  String get categoryManageTitle => 'カテゴリ管理';

  @override
  String get categoryAdd => 'カテゴリを追加';

  @override
  String get categoryEdit => 'カテゴリを編集';

  @override
  String get categoryDefault => 'デフォルト';

  @override
  String get categoryEmpty => 'カテゴリがありません';

  @override
  String get categoryNameLabel => 'カテゴリ名';

  @override
  String get categoryNameHint => '例: 健康、趣味';

  @override
  String get categoryIconLabel => 'アイコンを選択';

  @override
  String get categoryDeleteTitle => 'カテゴリを削除';

  @override
  String get categoryDeleteMessage => 'このカテゴリに割り当てられたタスクのカテゴリは未設定になります。削除しますか？';

  @override
  String get devModeSection => '開発者モード';

  @override
  String get devModeAiUnlimited => 'AI回数制限を無視';

  @override
  String get devModeAiUnlimitedDesc => 'ONでAI整理の回数制限をスキップ';

  @override
  String get devModePremium => 'プレミアム機能を解放';

  @override
  String get devModePremiumDesc => 'ONで全FeatureGateを解除';

  @override
  String get devModeResetAiUsage => 'AI使用回数リセット';

  @override
  String get devModeResetAiUsageDesc => '当月のAI使用回数をリセットします';

  @override
  String get devModeResetAiUsageDone => 'AI使用回数をリセットしました';

  @override
  String get devModeConfirmResetAiUsage => '当月のAI使用回数をリセットしますか？';

  @override
  String get devModeReviewSection => 'レビュー';

  @override
  String get devModeTestReview => 'レビューダイアログをテスト表示';

  @override
  String get devModeTestReviewDesc => '条件を無視してレビューダイアログを表示します';

  @override
  String get devModeTestReviewTriggered => 'レビューダイアログをリクエストしました';

  @override
  String get devModeResetReview => 'レビューカウンターリセット';

  @override
  String get devModeResetReviewDesc => 'レビュー関連の全カウンターをリセットします';

  @override
  String get devModeResetReviewDone => 'レビューカウンターをリセットしました';

  @override
  String get devModeEnabled => '開発者モードが有効になりました';

  @override
  String devModeRemaining(int count) {
    return 'あと$count回タップで開発者モード';
  }

  @override
  String get allCompleteTitle => 'すべて完了！お疲れさまでした';

  @override
  String get allCompleteSubtitle => '次のタスクを追加しましょう';

  @override
  String get allCompleteAddTask => 'タスクを追加する';

  @override
  String get allCompleteAiSort => 'AIで整理';

  @override
  String get allCompleteNoTaskForAi => 'タスクを追加してから整理しましょう';

  @override
  String get allExpiredBannerTitle => 'すべてのタスクの期限が過ぎています';

  @override
  String get allExpiredAddTask => '新しいタスクを追加';

  @override
  String get allExpiredUpdateDue => '期限を更新';

  @override
  String get allExpiredNotification => 'すべてのタスクの期限が過ぎました。新しいやることを追加しませんか？';

  @override
  String get todaySection => '今日やること';

  @override
  String get todaySectionEmpty => '今日やることはありません';

  @override
  String get otherTasks => 'その他のタスク';

  @override
  String get thisWeekSection => '今週のタスク';

  @override
  String get laterSection => '来週以降';

  @override
  String laterSectionCount(int count) {
    return '来週以降 $count件';
  }

  @override
  String get overdueSection => '期限切れ';

  @override
  String overdueSectionCount(int count) {
    return '期限切れ $count件';
  }

  @override
  String get aiHistoryTooltip => 'AI整理の履歴';

  @override
  String executionDateLabel(String date) {
    return '実行日: $date';
  }

  @override
  String dueDateLabel(String date) {
    return '期限: $date';
  }

  @override
  String dueDateSub(String date) {
    return '(期限: $date)';
  }

  @override
  String get calendarViewRecommended => 'AIのおすすめ日';

  @override
  String get calendarViewDue => '期限の日';

  @override
  String get calendarViewRecommendedTooltip => 'AIが提案した着手日でカレンダーに配置';

  @override
  String get calendarViewDueTooltip => 'タスクの期限日でカレンダーに配置';

  @override
  String taskCount(int count) {
    return '全$count件';
  }

  @override
  String get tabTodo => 'やること';

  @override
  String get aiAutoSettingsComplete => '通知・カレンダーを自動設定しました';

  @override
  String get aiAutoNotifyOnly => '通知を自動設定しました';

  @override
  String get aiAutoCalendarPermission => 'カレンダー連携は設定からオンにできます';

  @override
  String get aiPremiumAutoPrompt => 'プレミアム: 通知とカレンダーも自動';

  @override
  String get aiPremiumAutoTrial => '7日間無料で試す';

  @override
  String get aiChangeSettings => '設定を変更';

  @override
  String get ob1TitleNew => 'タスク名と期限を入れるだけ';

  @override
  String get ob1SubNew => 'それだけでOK。あとはAIにおまかせ';

  @override
  String get ob2TitleNew => 'AIが全部やってくれる';

  @override
  String get ob2SubNew => '優先順位もアドバイスも、通知設定も全部自動';

  @override
  String get ob3TitleNew => 'いつやるかが一目でわかる';

  @override
  String get ob4TitleNew => 'プレミアムなら通知もカレンダーも自動';

  @override
  String get ob4FreeStart => 'まずは無料で始める';

  @override
  String get settingsAiSection => 'AI整理';

  @override
  String get executionTimingLabel => '実行日の傾向';

  @override
  String get executionTimingDeadline => 'ギリギリ';

  @override
  String get executionTimingEarly => '早めに';

  @override
  String get executionTimingDesc0 => '期限直前に実行';

  @override
  String get executionTimingDesc1 => 'やや期限寄り';

  @override
  String get executionTimingDesc2 => 'バランス';

  @override
  String get executionTimingDesc3 => 'やや早めに';

  @override
  String get executionTimingDesc4 => '余裕を持って早めに';

  @override
  String recommendedDateEditHint(String date) {
    return '$date に実行がおすすめ';
  }

  @override
  String get recommendedDateManual => '推奨実行日（手動設定）';

  @override
  String get recommendedDateAiSet => '推奨実行日';

  @override
  String get recommendedDateNotSet => 'AI整理後に設定されます';

  @override
  String get manualDateOverwriteTitle => '手動設定の実行日があります';

  @override
  String manualDateOverwriteMessage(int count) {
    return '手動設定した実行日があるタスクが$count件あります。AIの提案で上書きしますか？';
  }

  @override
  String get manualDateOverwriteAll => '全て上書き';

  @override
  String get manualDateKeep => '手動設定を維持';

  @override
  String get weekTabThisWeek => '今週';

  @override
  String get weekTabNextWeek => '来週';

  @override
  String get weekTabLater => '再来週以降';

  @override
  String weekTabCount(String label, int count) {
    return '$label ($count)';
  }

  @override
  String get noTasksNextWeek => '来週のタスクはありません';

  @override
  String get noTasksLater => '再来週以降のタスクはありません';

  @override
  String get calendarHintBubble => 'カレンダーで実行日を確認 →';

  @override
  String get aiSortExecute => 'AIで整理する';

  @override
  String get aiHistoryLabel => 'AI履歴';

  @override
  String get settingsSound => 'サウンド';

  @override
  String get settingsSoundDesc => '完了時の効果音を再生します';

  @override
  String get aiErrorNetworkTitle => '接続できませんでした';

  @override
  String get aiErrorNetworkBody => 'インターネット接続を確認してもう一度お試しください。';

  @override
  String get aiErrorApiTitle => 'AI整理を実行できませんでした';

  @override
  String get aiErrorApiBody => 'しばらく時間をおいてからお試しください。';

  @override
  String get aiErrorRateLimitTitle => 'リクエスト回数の上限に達しました';

  @override
  String get aiErrorRateLimitBody => 'しばらく時間をおいてからお試しください。';

  @override
  String get aiErrorClose => '閉じる';

  @override
  String get recurringGuideTitle => '定期タスクにしませんか？';

  @override
  String recurringGuideMessage(String taskName) {
    return '「$taskName」は毎月のタスク?';
  }

  @override
  String get recurringGuideDescription => '定期タスクに設定すると、毎月自動的にタスクが作成されます。';

  @override
  String get recurringGuideAccept => '定期タスクに設定する';

  @override
  String get recurringGuideDecline => '今回だけ';

  @override
  String get recurringGuideApplied => '定期タスクに設定しました';

  @override
  String get allCompleteNextPrompt => '次のやることを追加しませんか？';

  @override
  String get devModeAnimationsPreview => '演出プレビュー';

  @override
  String get devModeAnimationsPreviewDesc => 'AI整理・全完了・バースト・紙吹雪を独立に再生';

  @override
  String get calendarLegendUrgent => '緊急';

  @override
  String get calendarLegendWeek => '今週';

  @override
  String get calendarLegendLater => '来週〜';

  @override
  String get calendarLegendUnsorted => '未整理';

  @override
  String get devModeUseNewUi => '新UI(リデザイン版)を有効化';

  @override
  String get devModeUseNewUiDesc => 'ホーム画面など新デザインのプレビューを使用';

  @override
  String get heroTodayMission => '今日の進捗';

  @override
  String get aiSortHeroCta => '今日のタスクをAIで整理';

  @override
  String get statsTitle => '実績';

  @override
  String get statsStreakActive => '連続達成';

  @override
  String statsStreakDays(int n) {
    return '$n日';
  }

  @override
  String get statsLongest => '最長';

  @override
  String get statsDone => '完了';

  @override
  String get statsWeek => '今週';

  @override
  String get statsPast14Days => '過去14日の達成度';

  @override
  String statsLevelXp(int cur, int next) {
    return '$cur / $next XP';
  }

  @override
  String get statsBadges => '獲得バッジ';

  @override
  String get statsHelpTooltip => '仕組みの説明';

  @override
  String get gamificationHelpTitle => 'やるナビの仕組み';

  @override
  String get gamificationHelpSubtitle => '使うほど報われる、シンプルなレベルシステム';

  @override
  String get gamificationHelpXpTitle => 'XPでレベルアップ';

  @override
  String get gamificationHelpXpBody =>
      '完了で +10 XP、AI整理で +5 XP、今日の全完了でさらに +25 XP。';

  @override
  String get gamificationHelpStreakTitle => 'ストリーク (連続日数)';

  @override
  String get gamificationHelpStreakBody =>
      '1日1回でも操作すると連続日数が伸びます。3・7・14・30日でボーナスXPとバッジを獲得。';

  @override
  String get gamificationHelpLevelTitle => '8段階のレベル';

  @override
  String get gamificationHelpLevelBody =>
      'Lv.1 はじめてのナビ → Lv.5 AIの右腕 → Lv.8 伝説のプランナーまで。Lv.9以降も継続可能。';

  @override
  String get gamificationHelpBadgeTitle => '11個のバッジ';

  @override
  String get gamificationHelpBadgeBody =>
      '初タスク完了、累計10/50/100件、AI初体験、ストリーク達成、レベル到達などで獲得。';

  @override
  String statsNextLevelHint(int xp, int level) {
    return 'あと$xp XPでLv.$level';
  }

  @override
  String get levelName1 => 'はじめてのナビ';

  @override
  String get levelName2 => '見習いプランナー';

  @override
  String get levelName3 => '段取り上手';

  @override
  String get levelName4 => 'タスクマスター';

  @override
  String get levelName5 => 'AIの右腕';

  @override
  String get levelName6 => '整理の達人';

  @override
  String get levelName7 => '時間の支配者';

  @override
  String get levelName8 => '伝説のプランナー';

  @override
  String levelNameHigh(int level) {
    return 'Lv.$level';
  }

  @override
  String get badgeName_first_step => 'はじめの一歩';

  @override
  String get badgeDesc_first_step => '最初のタスクを完了';

  @override
  String get badgeName_streak_3 => '三日坊主とは言わせない';

  @override
  String get badgeDesc_streak_3 => '3日連続でアプリを起動';

  @override
  String get badgeName_streak_7 => '一週間の習慣';

  @override
  String get badgeDesc_streak_7 => '7日連続でアプリを起動';

  @override
  String get badgeName_streak_14 => 'フォートナイト達成';

  @override
  String get badgeDesc_streak_14 => '14日連続でアプリを起動';

  @override
  String get badgeName_streak_30 => '月間皆勤賞';

  @override
  String get badgeDesc_streak_30 => '30日連続でアプリを起動';

  @override
  String get badgeName_ai_first => 'AI初体験';

  @override
  String get badgeDesc_ai_first => '初めてAI整理を実行';

  @override
  String get badgeName_task_10 => 'コツコツ職人';

  @override
  String get badgeDesc_task_10 => '累計10件完了';

  @override
  String get badgeName_task_50 => '半世紀の重み';

  @override
  String get badgeDesc_task_50 => '累計50件完了';

  @override
  String get badgeName_task_100 => 'センチュリオン';

  @override
  String get badgeDesc_task_100 => '累計100件完了';

  @override
  String get badgeName_level_5 => '駆け出しプランナー';

  @override
  String get badgeDesc_level_5 => 'Lv.5到達';

  @override
  String get badgeName_level_10 => '一人前の整理人';

  @override
  String get badgeDesc_level_10 => 'Lv.10到達';

  @override
  String get greetingMorning => 'おはよう';

  @override
  String get greetingAfternoon => 'こんにちは';

  @override
  String get greetingEvening => 'こんばんは';

  @override
  String get navHome => 'ホーム';

  @override
  String get navCalendar => 'カレンダー';

  @override
  String get navStats => '実績';

  @override
  String get navSettings => '設定';

  @override
  String xpEarned(int xp) {
    return '+$xp XP';
  }

  @override
  String get levelUpTitle => 'レベルアップ!';

  @override
  String levelUpMessage(int level, String name) {
    return 'Lv.$level $name';
  }

  @override
  String get badgeUnlocked => '新しいバッジ!';

  @override
  String get sectionNow => '今日';

  @override
  String get sectionUpcoming => '今週・来週';

  @override
  String get sectionThisWeek => '今週';

  @override
  String get sectionLater => '来週以降';

  @override
  String get sectionEmptyNow => '今日の予定はありません';

  @override
  String get sectionEmptyThisWeek => '今週の予定はありません';

  @override
  String get sectionEmptyLater => '来週以降の予定はありません';

  @override
  String get taskDetailCountdown => '期限まで';

  @override
  String get taskCompleteAction => '完了にする';

  @override
  String get aiResultStartCta => 'この順番で進める';

  @override
  String get aiResultRetryCta => 'もう一度';

  @override
  String get aiResultNowLabel => '今日';

  @override
  String get aiResultWeekLabel => '今週';

  @override
  String get aiResultLaterLabel => '来週以降';

  @override
  String get aiResultOptimized => '整理完了';

  @override
  String get premiumYearlyCta => '年額プランで始める';

  @override
  String get premiumMonthlyCta => '月額プランで始める';

  @override
  String get premiumTrialCopy => '7日間無料トライアル · いつでも解約可';

  @override
  String get calendarExecutionDate => '実行日';

  @override
  String get calendarDueDate => '期限日';

  @override
  String get onbV2WelcomeBadge => 'AIナビゲーション';

  @override
  String get onbV2WelcomeTitlePart1 => '今日、何から ';

  @override
  String get onbV2WelcomeTitleAccent => 'やる？';

  @override
  String get onbV2WelcomeTitlePart2 => '';

  @override
  String get onbV2WelcomeBody =>
      '「やること」を入れるだけ。\nあとはAIナビが優先順位を整え、\nあなたの“次の一手”を教えます。';

  @override
  String get onbV2BeforeAfterTitle => '頭の中の“やること”を、整理';

  @override
  String get onbV2BeforeAfterSub => 'ただ並べ替えるだけじゃない。\n“今すぐやるべきこと”を選び抜きます';

  @override
  String get onbV2BeforeLabel => '整理する前';

  @override
  String get onbV2BeforeCaption => 'どれから手を付ければ…';

  @override
  String get onbV2BeforeTask1 => '週報を提出';

  @override
  String get onbV2BeforeTask2 => '家賃を振り込む';

  @override
  String get onbV2BeforeTask3 => '日用品の買い出し';

  @override
  String get onbV2BeforeDate1 => '今日まで';

  @override
  String get onbV2BeforeDate2 => '5/15まで';

  @override
  String get onbV2BeforeDate3 => '5/20まで';

  @override
  String get onbV2NaviArrow => 'AIで仕分け';

  @override
  String get onbV2AfterLabel => '整理したあと';

  @override
  String get onbV2AfterCaption => '“今やるべき1件”が明確';

  @override
  String get onbV2AfterBadgeUrgent => '今すぐ';

  @override
  String get onbV2AfterBadgeWeek => '今週中';

  @override
  String get onbV2AfterBadgeLater => 'あとで';

  @override
  String get onbV2AfterTask1 => '週報を提出';

  @override
  String get onbV2AfterTask2 => '家賃を振り込む';

  @override
  String get onbV2AfterTask3 => '日用品の買い出し';

  @override
  String get onbV2AfterComment1 => '午前中に集中して片付けよう';

  @override
  String get onbV2AfterComment2 => '金曜までにネットバンキングで';

  @override
  String get onbV2AfterComment3 => '週末にまとめ買いが効率的';

  @override
  String get onbV2GameTitle => '続けるほど、好きになる';

  @override
  String get onbV2GameSub => '達成感がそのまま“やる気”に変わる仕組み';

  @override
  String get onbV2GameXpTitle => '完了するたび、経験値+10';

  @override
  String get onbV2GameXpSub => '今日のタスク全制覇でボーナス+25';

  @override
  String get onbV2GameStreakTitle => '連続日数で、炎が育つ';

  @override
  String get onbV2GameStreakSub => '3日・7日・30日で限定バッジ獲得';

  @override
  String get onbV2GameLevelTitle => 'Lv.1→Lv.8で“肩書き”が変わる';

  @override
  String get onbV2GameLevelSub => 'ナビ見習いから、伝説のプランナーへ';

  @override
  String get onbV2GameFooter => '完璧じゃなくていい。\n小さな一歩を、毎日刻んでいこう。';

  @override
  String get onbV2CtaTitle => 'さあ、最初の一歩を。';

  @override
  String get onbV2CtaBody => '気になっている“やること”を、\nひとつだけ入れてみてください。\nあとはナビにまかせて大丈夫。';

  @override
  String get onbV2CtaButton => 'やることを追加する';

  @override
  String get homeQuickTotalLabel => '全タスク';

  @override
  String get homeQuickTotalUnit => '件';

  @override
  String homeNextHint(String date, int count) {
    return '次は $date に $count件';
  }

  @override
  String get homeNoUpcoming => '未完了タスクはありません';

  @override
  String get homeJumpAll => 'すべて見る';

  @override
  String homeOverdueChip(int count) {
    return '期限切れ $count';
  }

  @override
  String get calendarMonthListMode => 'リスト';

  @override
  String get calendarGridMode => '月';

  @override
  String get calendarMonthAllTasks => '今月のタスク';

  @override
  String calendarNoTasksNextHint(String date, int count) {
    return '予定なし。次は $date に $count件';
  }

  @override
  String get calendarJumpToNext => '次の予定日を表示';

  @override
  String get calendarMonthEmpty => '今月の予定はまだありません';

  @override
  String get aiResultOptimizedBadge => 'AIで整理済み';

  @override
  String get aiNaviNoteLabel => 'ナビからひとこと';

  @override
  String get aiNaviAdviceLabel => 'ナビからのアドバイス';

  @override
  String get aiNaviAdviceBadge => 'AIアドバイス';

  @override
  String aiSortQuotaFree(int remaining, int total) {
    return '無料 残り $remaining/$total回';
  }

  @override
  String aiSortQuotaPremium(int remaining, int total) {
    return '今月 残り $remaining/$total回';
  }

  @override
  String archiveOpenButton(int count) {
    return '過去のタスクを見る($count)';
  }

  @override
  String get archiveTitle => '過去の完了タスク';

  @override
  String get archiveEmpty => '過去の完了タスクはありません';

  @override
  String get archiveRecentLabel => '過去7日';

  @override
  String streakMilestoneTitle(int days) {
    return '$days日連続達成!';
  }

  @override
  String get streakMilestoneBody => 'すごい!明日も小さな一歩を積み重ねよう。';

  @override
  String taskCompletedOn(String date) {
    return '$dateに完了';
  }

  @override
  String get calendarLegendDone => '完了';

  @override
  String get executionTimingHint =>
      'AIが着手日を提案するときの基準です。「ギリギリ」寄りなら期限近くに、「早めに」寄りなら余裕を持って提案します。';

  @override
  String get archiveEmptyHint => '7日より前に完了したタスクがここにたまります';

  @override
  String get archiveEmptyCta => 'ホームに戻る';

  @override
  String get uncompleteTask => '未完了に戻す';

  @override
  String get taskUncompletedSnack => 'タスクを未完了に戻しました';

  @override
  String get undo => '取り消し';

  @override
  String get deleteHistory => '履歴を削除';

  @override
  String get deleteHistoryConfirmTitle => 'この履歴を削除しますか?';

  @override
  String get deleteHistoryConfirmBody => '選択した完了済みタスクを削除します。 この操作は取り消せません。';

  @override
  String get deleteAllHistoryConfirmTitle => '完了済みタスクをすべて削除しますか?';

  @override
  String get deleteAllHistoryConfirmBody =>
      '完了済みタスクの履歴をすべて削除します。 この操作は取り消せません。';

  @override
  String get deleteAllAction => 'すべて削除';

  @override
  String historyDeletedSnack(int count) {
    return '$count件の履歴を削除しました';
  }

  @override
  String get scheduleSection => 'タスクのスケジュール';

  @override
  String get scheduleBusynessLabel => '曜日ごとの忙しさ (1=暇〜5=多忙)';

  @override
  String get blockedDatesLabel => 'タスク実行不可日';

  @override
  String get blockedDatesAdd => '日付を追加';

  @override
  String get blockedDatesEmpty => '登録されていません';

  @override
  String get weekdayMonShort => '月';

  @override
  String get weekdayTueShort => '火';

  @override
  String get weekdayWedShort => '水';

  @override
  String get weekdayThuShort => '木';

  @override
  String get weekdayFriShort => '金';

  @override
  String get weekdaySatShort => '土';

  @override
  String get weekdaySunShort => '日';

  @override
  String get levelName9 => 'タスク仙人';

  @override
  String get levelName10 => '究極のオーガナイザー';

  @override
  String get levelName15 => 'タスクの求道者';

  @override
  String get levelName20 => '整理の哲学者';

  @override
  String get levelName30 => '効率化の帝王';

  @override
  String get levelName50 => 'タスク界の生ける伝説';

  @override
  String get levelName70 => '時空を超えし者';

  @override
  String get levelName100 => '∞ 無限のプランナー';

  @override
  String get badgeName_task_25 => 'やりくり上手';

  @override
  String get badgeDesc_task_25 => '累計25件完了';

  @override
  String get badgeName_task_250 => 'タスクハンター';

  @override
  String get badgeDesc_task_250 => '累計250件完了';

  @override
  String get badgeName_task_500 => '500の頂';

  @override
  String get badgeDesc_task_500 => '累計500件完了';

  @override
  String get badgeName_task_1000 => '千の証';

  @override
  String get badgeDesc_task_1000 => '累計1000件完了';

  @override
  String get badgeName_streak_60 => '鉄の意志';

  @override
  String get badgeDesc_streak_60 => '60日連続でアプリを起動';

  @override
  String get badgeName_streak_100 => 'もはや生活の一部';

  @override
  String get badgeDesc_streak_100 => '100日連続でアプリを起動';

  @override
  String get badgeName_ai_10 => 'AIの常連';

  @override
  String get badgeDesc_ai_10 => 'AI整理10回';

  @override
  String get badgeName_ai_50 => 'AI整理マニア';

  @override
  String get badgeDesc_ai_50 => 'AI整理50回';

  @override
  String get badgeName_level_20 => '効率化の求道者';

  @override
  String get badgeDesc_level_20 => 'Lv.20到達';

  @override
  String get badgeName_level_30 => '伝説のオーガナイザー';

  @override
  String get badgeDesc_level_30 => 'Lv.30到達';

  @override
  String get badgeName_early_bird => '早起きは三文の徳';

  @override
  String get badgeDesc_early_bird => '朝6時前にタスクを完了';

  @override
  String get badgeName_night_owl => '真夜中のタスクランナー';

  @override
  String get badgeDesc_night_owl => '深夜0時〜3時にタスクを完了';

  @override
  String get badgeName_busy_day_5 => '夏休みの宿題はまとめてやるタイプ';

  @override
  String get badgeDesc_busy_day_5 => '1日に5件以上のタスクを完了';

  @override
  String get badgeName_busy_day_10 => '嵐のような一日';

  @override
  String get badgeDesc_busy_day_10 => '1日に10件以上のタスクを完了';

  @override
  String get badgeName_busy_month_30 => '月間マラソンランナー';

  @override
  String get badgeDesc_busy_month_30 => '1ヶ月に30件以上完了';

  @override
  String get badgeName_back_from_hibernation => '冬眠からの目覚め';

  @override
  String get badgeDesc_back_from_hibernation => '60日以上ぶりにタスクを完了';

  @override
  String get badgeName_long_time_no_see => 'お久しぶりです';

  @override
  String get badgeDesc_long_time_no_see => '30日以上ぶりにアプリを起動';

  @override
  String get badgeName_category_master => '整理整頓の達人';

  @override
  String get badgeDesc_category_master => 'カテゴリを5つ以上作成';

  @override
  String get badgeName_habit_demon => '習慣の鬼';

  @override
  String get badgeDesc_habit_demon => '定期タスクを5件以上登録';

  @override
  String get badgeName_schedule_master => 'スケジュールマスター';

  @override
  String get badgeDesc_schedule_master => '曜日空き設定を初めて変更';

  @override
  String get badgeName_zero_overdue => 'ゼロの境地';

  @override
  String get badgeDesc_zero_overdue => '期限切れタスクを0にした';

  @override
  String get badgeName_multi_tasker => 'マルチタスカー';

  @override
  String get badgeDesc_multi_tasker => '3つ以上のカテゴリでタスク完了';

  @override
  String get badgeName_ticket_buyer => 'AI整理チケット購入者';

  @override
  String get badgeDesc_ticket_buyer => 'AI整理チケットを初めて購入';

  @override
  String get badgeName_weekend_warrior => '週末の戦士';

  @override
  String get badgeDesc_weekend_warrior => '土日に合計5件以上のタスクを完了';

  @override
  String get badgeName_perfect_week => 'パーフェクトウィーク';

  @override
  String get badgeDesc_perfect_week => '1週間毎日タスクを1件以上完了';

  @override
  String get badgeName_level_50 => 'タスク界の生ける伝説';

  @override
  String get badgeDesc_level_50 => 'Lv.50到達';

  @override
  String get badgeName_level_70 => '時空を超えし者';

  @override
  String get badgeDesc_level_70 => 'Lv.70到達';

  @override
  String get badgeName_level_100 => '∞ 到達不可能を可能にした者';

  @override
  String get badgeDesc_level_100 => 'Lv.100到達';

  @override
  String get badgeHidden => '???';

  @override
  String get badgeHiddenLabel => 'Hidden';

  @override
  String get aiReminderToggle => '整理リマインド';

  @override
  String get aiReminderToggleDesc => '未完了が溜まったら夕方に通知 (1 日 1 回)';

  @override
  String get aiPurchaseSheetTitle => 'AI 整理の回数が不足しています';

  @override
  String get aiPurchaseSheetBody => '以下のいずれかの方法で AI 整理を利用できます。';

  @override
  String get aiPurchasePremiumTitle => 'プレミアムプラン ¥580/月';

  @override
  String get aiPurchasePremiumLabel => 'プレミアムプラン';

  @override
  String get aiPurchaseTicketLabel => 'AI 整理チケット';

  @override
  String get labelOverdue => '期限切れ';

  @override
  String get labelDue => '期限';

  @override
  String get labelDueToday => '今日が期限';

  @override
  String get labelRepeat => '定期';

  @override
  String get labelEst => '推定';

  @override
  String get labelUrgent => '緊急';

  @override
  String get labelAiAdvice => 'AIアドバイス';

  @override
  String get labelNow => '今すぐ';

  @override
  String get labelThisWeek => '今週';

  @override
  String get labelLater => '来週以降';

  @override
  String get labelNormal => '通常';

  @override
  String statsBadgesEarnedCount(int earned, int total) {
    return '$earned / $total 達成';
  }

  @override
  String get statsTutorialTitle => '実績をアンロックしよう!';

  @override
  String get statsTutorialBody =>
      'タスクを完了して XP を獲得し、レベルアップを目指しましょう。隠しバッジも多数用意されています — どんな条件で獲得できるかはお楽しみ!';

  @override
  String get statsTutorialCta => 'さっそく始める';

  @override
  String get naviHintTitle => 'ナビからのひとこと';

  @override
  String naviHintLastSort(String timestamp) {
    return '最終整理: $timestamp';
  }

  @override
  String get naviHintDetail => '詳細';

  @override
  String get labelExecutionDay => '実行日';

  @override
  String get pickExecutionDayTooltip =>
      '実行日を選択 (手動で変更した実行日は、次回 AI 整理で再提案される場合があります)';

  @override
  String get executionDayUpdated => '実行日を更新しました';

  @override
  String get aiResultChangeDate => '変更';

  @override
  String get calendarSectionTasks => 'タスク';

  @override
  String get calendarSectionEvents => '予定';

  @override
  String get eventDeleted => '予定を削除しました';

  @override
  String calendarSyncDone(int count) {
    return '$count件の予定を取り込みました';
  }

  @override
  String get calendarSyncFailed => 'カレンダーの取り込みに失敗しました';

  @override
  String get eventAdd => '予定を追加';

  @override
  String get eventEdit => '予定を編集';

  @override
  String get eventTitleLabel => 'タイトル';

  @override
  String get eventDateLabel => '日付';

  @override
  String get eventAllDayLabel => '終日';

  @override
  String get eventStartTime => '開始時刻';

  @override
  String get eventEndTime => '終了時刻';

  @override
  String get eventMemoLabel => 'メモ';

  @override
  String get eventSaved => '予定を保存しました';

  @override
  String get eventReadOnlyNote => 'iOS カレンダーから取り込んだ予定は編集できません';

  @override
  String get eventSectionLabel => '予定';

  @override
  String get fabAddTask => 'タスクを追加';

  @override
  String get fabAddEvent => '予定を追加';

  @override
  String get fabSyncCalendar => 'カレンダーから取り込む';

  @override
  String get avoidEventDaysToggle => '予定がある日のタスク割り当て';

  @override
  String get avoidEventDaysDesc => '予定がある日にはタスクを入れない (AI 整理に反映)';

  @override
  String get tipsHeader => 'Tips';

  @override
  String get tip0 => '曜日ごとの空き具合を設定すると、AI がもっと賢く実行日を提案します。';

  @override
  String get tip1 => 'タスク実行不可の日を設定すると、その日にはタスクが割り当てられません。';

  @override
  String get tip2 => 'カレンダーから予定を取り込むと、予定のある日を避けてタスクを配置できます。';

  @override
  String get tip3 => 'AI が提案した実行日は、自分で変更することもできます。';

  @override
  String get tip4 => '定期的に発生するタスクは、定期タスクに設定すると毎月自動で作成されます。';

  @override
  String get tip5 => '完了したタスクは履歴として保存されます。 いつでも確認できます。';

  @override
  String get tip6 => 'AI 整理の回数が足りない時は、リワード動画を視聴すると 1 回分追加されます。';

  @override
  String get tip7 => 'カテゴリを設定すると、タスクの分類がわかりやすくなります。';

  @override
  String get tip8 => 'カレンダーは「AI のおすすめ日」 と「期限の日」 を切り替えて確認できます。';

  @override
  String get tip9 => 'タスク詳細画面では、期限までのカウントダウンがリアルタイム表示されます。';

  @override
  String get tip10 => 'タスクを完了すると XP が貯まり、レベルアップできます。';

  @override
  String get tip11 => 'アプリを毎日開くだけでストリーク (連続記録) が伸びていきます。';

  @override
  String get tip12 => '隠しバッジが複数あります。 どんな条件で獲得できるかはお楽しみ!';

  @override
  String get tip13 => 'レベルは 100 まで。 最高レベルに到達するには約 10 年かかります。';

  @override
  String get tip14 => '早朝や深夜にタスクを完了すると、特別なバッジがもらえるかも?';

  @override
  String get tip15 => 'タスク名に「振込」 「家賃」 などを含めると、定期タスク化がおすすめされます。';

  @override
  String get tip16 => '1 日に 5 件以上タスクを完了すると… 何かが起きるかも?';

  @override
  String get tip17 => 'AI 整理は一度に多くのタスクを登録してから実行すると、より効果的です。';

  @override
  String get tip18 => '期限切れのタスクをゼロにすると、実績が解除されます。';

  @override
  String get tip19 => '週末にまとめてタスクを片付ける派ですか? それも実績になるかもしれません。';

  @override
  String get aiPurchasePremiumSubtitle => 'AI 整理 月 30 回 + 全機能解放';

  @override
  String get aiPurchaseTicketTitle => 'AI 整理チケット ¥120';

  @override
  String aiPurchaseTicketSubtitle(int remaining, int max) {
    return '1 回分を追加 (残り $remaining/$max 回購入可能)';
  }

  @override
  String get aiPurchaseTicketDisabled => 'チケット購入は上限に達しています';

  @override
  String get aiPurchaseRewardedTitle => '動画を視聴';

  @override
  String get aiPurchaseRewardedSubtitle => '短い動画を見て AI 整理を 1 回回復';

  @override
  String aiRewardedRemaining(int remaining, int max) {
    return '残り $remaining/$max 回利用可能';
  }

  @override
  String get aiRewardedExhausted => '動画での回復は上限に達しました';

  @override
  String get aiPremiumRequiredNote => 'AI 整理を継続するにはプレミアムプランへの登録が必要です';

  @override
  String get aiSortQuotaVip => 'VIP 無制限';

  @override
  String aiSortQuotaFreeShort(int remaining) {
    return '残り $remaining回';
  }
}
