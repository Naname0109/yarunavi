import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// AI使用回数とインストール日を OS のセキュアストレージに保存する。
///
/// iOS: Keychain (アプリ削除後も永続化される)
/// Android: EncryptedSharedPreferences (再インストールでリセットされる)
/// TODO: 将来 Firebase Anonymous Auth + Firestore で完全永続化に改善
class SecureStorageService {
  SecureStorageService()
      : _storage = const FlutterSecureStorage(
          aOptions: AndroidOptions(encryptedSharedPreferences: true),
        );

  final FlutterSecureStorage _storage;

  static const _installDateKey = 'yarunavi_install_date';
  static String _usageKey(String monthKey) => 'yarunavi_ai_usage_$monthKey';

  /// 'YYYY_MM' 形式の月キーを返す
  static String currentMonthKey(DateTime now) {
    final y = now.year.toString().padLeft(4, '0');
    final m = now.month.toString().padLeft(2, '0');
    return '${y}_$m';
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
}
