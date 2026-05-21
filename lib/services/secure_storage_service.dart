import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// AI使用回数とインストール日を OS のセキュアストレージに保存する。
///
/// iOS: Keychain (アプリ削除後も永続化される)
/// Android: EncryptedSharedPreferences (再インストールでリセットされる)
class SecureStorageService {
  SecureStorageService()
      : _storage = const FlutterSecureStorage(
          aOptions: AndroidOptions(encryptedSharedPreferences: true),
        );

  final FlutterSecureStorage _storage;

  static const _installDateKey = 'yarunavi_install_date';
  static const _lifetimeFreeUsageKey = 'yarunavi_ai_lifetime_free';
  static const _lastRewardedDateKey = 'yarunavi_ai_last_rewarded';
  static String _usageKey(String monthKey) => 'yarunavi_ai_usage_$monthKey';

  /// 'YYYY_MM' 形式の月キーを返す
  static String currentMonthKey(DateTime now) {
    final y = now.year.toString().padLeft(4, '0');
    final m = now.month.toString().padLeft(2, '0');
    return '${y}_$m';
  }

  /// 'YYYY-MM-DD' 形式の日付キーを返す
  static String currentDateKey(DateTime now) {
    final y = now.year.toString().padLeft(4, '0');
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  /// インストール日を取得 (なければ今日を保存して返す)
  Future<DateTime> getInstallDate() async {
    final stored = await _storage.read(key: _installDateKey);
    if (stored != null) {
      final parsed = DateTime.tryParse(stored);
      if (parsed != null) return parsed;
    }
    final now = DateTime.now();
    await _storage.write(key: _installDateKey, value: now.toIso8601String());
    return now;
  }

  // ─── 永続的な無料AI使用回数（再インストールでも復活しない） ───

  /// 永続無料AI使用回数を取得
  Future<int> getLifetimeFreeUsage() async {
    final s = await _storage.read(key: _lifetimeFreeUsageKey);
    return int.tryParse(s ?? '') ?? 0;
  }

  /// 永続無料AI使用回数をインクリメント
  Future<void> incrementLifetimeFreeUsage() async {
    final current = await getLifetimeFreeUsage();
    await _storage.write(
      key: _lifetimeFreeUsageKey,
      value: '${current + 1}',
    );
  }

  /// 永続無料AI使用回数をリセット（開発者モード用）
  Future<void> resetLifetimeFreeUsage() async {
    await _storage.delete(key: _lifetimeFreeUsageKey);
  }

  // ─── リワード広告の日次制限 ───

  /// 今日リワード広告でAI整理を使用済みか
  Future<bool> hasUsedRewardedToday() async {
    final stored = await _storage.read(key: _lastRewardedDateKey);
    return stored == currentDateKey(DateTime.now());
  }

  /// リワード広告使用を記録（今日の日付を保存）
  Future<void> recordRewardedUsage() async {
    await _storage.write(
      key: _lastRewardedDateKey,
      value: currentDateKey(DateTime.now()),
    );
  }

  /// リワード広告使用をリセット（開発者モード用）
  Future<void> resetRewardedUsage() async {
    await _storage.delete(key: _lastRewardedDateKey);
  }

  // ─── 月別AI使用回数（プレミアム用） ───

  /// 月別AI使用回数を取得
  Future<int> getMonthlyAiUsage(String monthKey) async {
    final s = await _storage.read(key: _usageKey(monthKey));
    return int.tryParse(s ?? '') ?? 0;
  }

  /// 月別AI使用回数をインクリメント
  Future<void> incrementAiUsage(String monthKey) async {
    final current = await getMonthlyAiUsage(monthKey);
    await _storage.write(
      key: _usageKey(monthKey),
      value: '${current + 1}',
    );
  }

  /// 月別AI使用回数をリセット (開発者モード用)
  Future<void> resetAiUsage(String monthKey) async {
    await _storage.delete(key: _usageKey(monthKey));
  }

  // ====== #2-D: total XP バックアップ (再 install 対策) ======
  // Keychain は端末紐付けで再 install しても残るため、 DB がクリアされても
  // total_xp の最大値を復元できる。

  static const String _kTotalXpBackupKey = 'total_xp_backup';

  /// Keychain に保存された累計 XP のバックアップ値 (なければ 0)。
  Future<int> getTotalXpBackup() async {
    final v = await _storage.read(key: _kTotalXpBackupKey);
    return v == null ? 0 : int.tryParse(v) ?? 0;
  }

  /// DB の最新 total_xp を Keychain に書き戻す (`>=` 現在値のときだけ更新)。
  Future<void> updateTotalXpBackup(int totalXp) async {
    final current = await getTotalXpBackup();
    if (totalXp > current) {
      await _storage.write(
        key: _kTotalXpBackupKey,
        value: totalXp.toString(),
      );
    }
  }

  // ====== Raw read/write (VIP 等の汎用) ======

  /// 任意のキーに対する read/write。 caller が key を直接管理する。
  Future<String?> readRaw(String key) => _storage.read(key: key);
  Future<void> writeRaw(String key, String value) =>
      _storage.write(key: key, value: value);

  // ====== #8: AI 整理チケット (消費型 IAP) ======
  // - 累計購入数 (lifetime) で 3 回までの上限を管理
  // - 残チケット数 (available) を消費していく

  static const String _kAiTicketLifetimeKey = 'ai_ticket_lifetime_purchases';
  static const String _kAiTicketAvailableKey = 'ai_ticket_available';

  /// これまで購入した累計 (1 ユーザーあたり 3 まで)。
  Future<int> getAiTicketLifetimePurchases() async {
    final v = await _storage.read(key: _kAiTicketLifetimeKey);
    return v == null ? 0 : int.tryParse(v) ?? 0;
  }

  /// 残っている消費可能なチケット枚数。
  Future<int> getAiTicketsAvailable() async {
    final v = await _storage.read(key: _kAiTicketAvailableKey);
    return v == null ? 0 : int.tryParse(v) ?? 0;
  }

  /// 購入完了時: lifetime++ / available++
  Future<void> recordAiTicketPurchase() async {
    final lifetime = await getAiTicketLifetimePurchases();
    final available = await getAiTicketsAvailable();
    await _storage.write(
      key: _kAiTicketLifetimeKey,
      value: (lifetime + 1).toString(),
    );
    await _storage.write(
      key: _kAiTicketAvailableKey,
      value: (available + 1).toString(),
    );
  }

  /// AI 整理使用時: available > 0 ならデクリメントして true、 0 なら false。
  Future<bool> consumeAiTicket() async {
    final available = await getAiTicketsAvailable();
    if (available <= 0) return false;
    await _storage.write(
      key: _kAiTicketAvailableKey,
      value: (available - 1).toString(),
    );
    return true;
  }
}
