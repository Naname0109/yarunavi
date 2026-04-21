class AppConstants {
  AppConstants._();

  static const String appName = 'YaruNavi';
  static const String bundleId = 'com.naname0109.yarunavi';

  // IAP Product IDs
  static const String monthlyProductId = 'yarunavi_premium_monthly';
  static const String yearlyProductId = 'yarunavi_premium_yearly';

  // Free tier limits
  static const int freeTaskLimit = 20;
  static const int freeRecurringTaskLimit = 2;
  /// 永続的な無料AI整理回数（再インストールでも復活しない）
  static const int freeAiSortLifetimeLimit = 2;

  // Premium limits
  static const int premiumAiSortMonthlyLimit = 30;

  // Anthropic API
  static const String anthropicModel = 'claude-haiku-4-5-20251001';
  static const String anthropicVersion = '2023-06-01';
  static const String anthropicApiUrl =
      'https://api.anthropic.com/v1/messages';

  // プロキシサーバー設定（本番用）
  static const String aiProxyUrl = String.fromEnvironment(
    'AI_PROXY_URL',
    defaultValue: '',
  );
  static const String aiAppToken = String.fromEnvironment(
    'AI_APP_TOKEN',
    defaultValue: '',
  );

  // 直接APIキー（開発時のみ使用、リリースビルドでは使わない）
  static const String anthropicApiKey = String.fromEnvironment(
    'ANTHROPIC_API_KEY',
    defaultValue: '',
  );

  // Notifications
  static const String notificationChannelId = 'yarunavi_task_reminders';
  static const String notificationChannelName = 'タスクリマインダー';
  static const int notificationHour = 9; // 朝9時

  /// 通知設定キー → 通知IDオフセットのマッピング
  static const Map<String, int> notifyOffsets = {
    'on_due': 0,
    '1_day_before': 1,
    '3_days_before': 2,
    '1_week_before': 3,
  };

  /// 通知設定キー → 期限日からの日数オフセット
  static const Map<String, int> notifyDaysBefore = {
    'on_due': 0,
    '1_day_before': 1,
    '3_days_before': 3,
    '1_week_before': 7,
  };

  // 全タスク期限切れ通知用の固定ID（タスクIDベースのIDと衝突しない）
  static const int allExpiredNotificationId = 999999;
  // SharedPreferencesキー
  static const String allExpiredNotifiedKey = 'all_expired_notified';

  // URLs
  static const String termsOfUseUrl =
      'https://www.apple.com/legal/internet-services/itunes/dev/stdeula/';
  static const String privacyPolicyUrl =
      'https://naname0109.github.io/yarunavi/';
}
