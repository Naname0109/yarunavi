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
  String get aiPriorityUrgent => '🔴 今すぐやるべき';

  @override
  String get aiPriorityWarning => '🟠 今週中に';

  @override
  String get aiPriorityNormal => '🔵 来週以降';

  @override
  String get aiPriorityRelaxed => '⚪ 急がないが忘れずに';

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
}
