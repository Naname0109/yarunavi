// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appTitle => 'YaruNavi';

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
  String get aiPriorityUrgent => '🔴 今日これだけやろう';

  @override
  String get aiPriorityWarning => '🟠 今週のうちに片付けよう';

  @override
  String get aiPriorityNormal => '🔵 来週以降でOK';

  @override
  String get aiPriorityRelaxed => '⚪ 忘れずにキープ';

  @override
  String get backToHome => 'ホームに戻る';

  @override
  String aiSortRemaining(int count) {
    return '残り$count回';
  }

  @override
  String get aiSortLimitReached => '今月の無料回数を使い切りました';

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
  String get aiSorting => 'AIが整理中...';

  @override
  String get notificationTitle => 'YaruNavi';

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
  String get calendarPermissionDenied => 'カレンダーへのアクセスを許可してください';

  @override
  String get calendarAddFailed => 'カレンダーへの追加に失敗しました';

  @override
  String get storePremiumTitle => 'プレミアムプラン';

  @override
  String get storeFeatureAiUnlimited => 'AI整理 無制限（無料は月3回）';

  @override
  String get storeFeatureTaskUnlimited => 'タスク登録 無制限（無料は10件）';

  @override
  String get storeFeatureRecurringUnlimited => '定期タスク 無制限（無料は1件）';

  @override
  String get storeFeatureCategoryUnlimited => 'カテゴリ 無制限（無料は2つ）';

  @override
  String get storeFeatureCalendar => 'カレンダー書き出し';

  @override
  String get storeFeatureNotification => '期限日の通知（無料はアプリ内のみ）';

  @override
  String get storeFeatureNoAds => '広告非表示';

  @override
  String get storeMonthlyPrice => '¥580/月';

  @override
  String get storeYearlyPrice => '¥4,200/年（¥350/月相当・40%おトク）';

  @override
  String get storeMonthlyTrial => '7日間無料 → その後 月額¥580';

  @override
  String get storeYearlyTrial => '7日間無料 → その後 年額¥4,200';

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
  String get onboardingTitle1 => 'タスク名と期限を入れるだけ';

  @override
  String get onboardingDesc1 => '複雑な設定は不要。\nタスク名と期限日を入力するだけで\nすぐに使い始められます。';

  @override
  String get onboardingTitle2 => 'AIが優先順位を整理';

  @override
  String get onboardingDesc2 =>
      '「何から手をつければいい？」を\nAIがあなたに代わって考えます。\n期限やカテゴリから最適な順番を提案。';

  @override
  String get onboardingTitle3 => 'やるべき日に通知でお知らせ';

  @override
  String get onboardingDesc3 =>
      '期限が近づいたらプッシュ通知。\n「忘れてた！」をなくします。\n通知を許可して便利に使いましょう。';

  @override
  String get onboardingSkip => 'スキップ';

  @override
  String get onboardingNext => '次へ';

  @override
  String get onboardingStart => 'はじめる';

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
  String get estimatedTime => '所要時間';

  @override
  String get estimatedTimeNone => '未設定';

  @override
  String get estimatedTime5min => '5分';

  @override
  String get estimatedTime30min => '30分';

  @override
  String get estimatedTime1hour => '1時間';

  @override
  String get estimatedTimeHalfDay => '半日';

  @override
  String get estimatedTime1day => '1日';

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
  String get aiSubtaskSuggestion => '分割して進めませんか？';

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
  String get debugSection => 'デバッグ';

  @override
  String get debugInsertTestData => 'テストデータを投入';

  @override
  String get debugDeleteAndInsertTestData => '全データ削除してテストデータを投入';

  @override
  String get debugTestDataInserted => 'テストデータを投入しました';

  @override
  String get debugConfirmInsert => 'テストデータを投入しますか？';

  @override
  String get debugConfirmDeleteAndInsert => '全データを削除してテストデータを投入しますか？';

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
}
