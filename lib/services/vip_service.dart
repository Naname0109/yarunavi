import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../utils/constants.dart';
import 'secure_storage_service.dart';

/// VIP コード機能 (#1)。
///
/// Cloudflare Worker (`/redeem-code`, `/vip-version`) と連携して
/// 「特定コード入力 → 永続プレミアム扱い」 を実現する。
/// SecureStorage (Keychain) に保存するため、 再 install しても残る。
class VipService {
  VipService(this._secure);
  final SecureStorageService _secure;

  static const _kVipEnabledKey = 'vip_enabled';
  static const _kVipVersionKey = 'vip_version';
  static const _kVipLastCheckKey = 'vip_last_check_iso';

  /// オフライン猶予 (世代チェック失敗時に何日間まで VIP を維持するか)
  static const _offlineGraceDays = 7;

  /// 端末識別子 (適当でよい。 server side ではレート制限キーにのみ使われる)。
  Future<String> _deviceId() async {
    // ある程度安定して取れる ID として、 既存の install_date を流用。
    final installDate = await _secure.getInstallDate();
    return installDate.toIso8601String();
  }

  /// 入力されたコードをサーバーで検証 → 成功なら SecureStorage に保存。
  /// 戻り値: true=成功 / false=不正コード or ネットワーク失敗。
  Future<bool> redeemCode(String code) async {
    final url = AppConstants.aiProxyUrl;
    if (url.isEmpty) return false;
    final token = AppConstants.aiAppToken;

    try {
      final res = await http
          .post(
            Uri.parse('$url/redeem-code'),
            headers: {
              'Content-Type': 'application/json',
              'X-App-Token': token,
            },
            body: jsonEncode({
              'code': code,
              'device_id': await _deviceId(),
            }),
          )
          .timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return false;
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      final valid = json['valid'] == true;
      if (!valid) return false;
      final version = (json['version'] as int?) ?? 0;
      await _secure.writeRaw(_kVipEnabledKey, '1');
      await _secure.writeRaw(_kVipVersionKey, version.toString());
      await _secure.writeRaw(
          _kVipLastCheckKey, DateTime.now().toIso8601String());
      return true;
    } catch (e) {
      debugPrint('[VIP] redeem failed: $e');
      return false;
    }
  }

  /// 現在 VIP 有効か (Keychain で判定)。
  Future<bool> isVipActive() async {
    final v = await _secure.readRaw(_kVipEnabledKey);
    return v == '1';
  }

  /// アプリ起動時に呼ぶ。 サーバーの code_version と照合して、
  /// 世代変更があれば VIP 無効化。 オフラインなら 7 日猶予。
  Future<void> checkVersion() async {
    if (!await isVipActive()) return;
    final url = AppConstants.aiProxyUrl;
    if (url.isEmpty) return;

    try {
      final res = await http
          .get(Uri.parse('$url/vip-version'))
          .timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) {
        await _markCheckedNow();
        return;
      }
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      final serverVersion = (json['version'] as int?) ?? 0;
      final localVersionStr = await _secure.readRaw(_kVipVersionKey);
      final localVersion = int.tryParse(localVersionStr ?? '') ?? 0;
      if (serverVersion != localVersion) {
        // 世代不一致 → 無効化
        await _secure.writeRaw(_kVipEnabledKey, '0');
        debugPrint('[VIP] version mismatch '
            'local=$localVersion server=$serverVersion → disabled');
        return;
      }
      await _markCheckedNow();
    } on SocketException catch (_) {
      await _expireIfOfflineTooLong();
    } catch (e) {
      debugPrint('[VIP] checkVersion failed: $e');
      await _expireIfOfflineTooLong();
    }
  }

  Future<void> _markCheckedNow() async {
    await _secure.writeRaw(
        _kVipLastCheckKey, DateTime.now().toIso8601String());
  }

  Future<void> _expireIfOfflineTooLong() async {
    final lastIso = await _secure.readRaw(_kVipLastCheckKey);
    if (lastIso == null) return;
    final last = DateTime.tryParse(lastIso);
    if (last == null) return;
    final daysSince = DateTime.now().difference(last).inDays;
    if (daysSince > _offlineGraceDays) {
      await _secure.writeRaw(_kVipEnabledKey, '0');
      debugPrint('[VIP] offline grace exceeded ($daysSince days) → disabled');
    }
  }
}
