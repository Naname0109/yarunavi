import 'package:flutter/foundation.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'secure_storage_service.dart';

/// アプリレビュー依頼を管理するサービス
class ReviewService {
  final SecureStorageService _secureStorage;
  final InAppReview _inAppReview = InAppReview.instance;

  /// セッション内で既にレビューダイアログを表示したか
  bool _sessionShown = false;

  // SharedPreferencesキー
  static const _keyAiSortCount = 'review_ai_sort_count';
  static const _keyCompletedTaskCount = 'review_completed_task_count';
  static const _keyLastRequested = 'review_last_requested';
  static const _keyRequestCount = 'review_request_count';
  static const _keyCompleted = 'review_completed';

  // 条件の閾値
  static const _minDaysAfterInstall = 3;
  static const _minAiSortCount = 2;
  static const _minCompletedTaskCount = 3;
  static const _minDaysBetweenRequests = 14;
  static const _maxRequestCount = 3;

  ReviewService(this._secureStorage);

  /// 全条件を満たしているか判定
  Future<bool> shouldRequestReview() async {
    if (_sessionShown) return false;

    final prefs = await SharedPreferences.getInstance();

    // 条件5: レビュー済みフラグ or 最大回数到達
    if (prefs.getBool(_keyCompleted) == true) return false;
    if ((prefs.getInt(_keyRequestCount) ?? 0) >= _maxRequestCount) return false;

    // 条件1: インストールから3日以上
    final installDate = await _secureStorage.getInstallDate();
    final daysSinceInstall =
        DateTime.now().difference(installDate).inDays;
    if (daysSinceInstall < _minDaysAfterInstall) return false;

    // 条件2: AI整理2回以上
    final aiSortCount = prefs.getInt(_keyAiSortCount) ?? 0;
    if (aiSortCount < _minAiSortCount) return false;

    // 条件3: タスク完了3件以上
    final completedCount = prefs.getInt(_keyCompletedTaskCount) ?? 0;
    if (completedCount < _minCompletedTaskCount) return false;

    // 条件4: 前回依頼から14日以上
    final lastRequested = prefs.getString(_keyLastRequested);
    if (lastRequested != null) {
      final lastDate = DateTime.tryParse(lastRequested);
      if (lastDate != null) {
        final daysSinceLast =
            DateTime.now().difference(lastDate).inDays;
        if (daysSinceLast < _minDaysBetweenRequests) return false;
      }
    }

    return true;
  }

  /// レビューダイアログを表示
  Future<void> requestReview() async {
    try {
      final isAvailable = await _inAppReview.isAvailable();
      if (!isAvailable) {
        debugPrint('[ReviewService] In-app review not available');
        return;
      }

      await _inAppReview.requestReview();
      debugPrint('[ReviewService] Review requested');

      _sessionShown = true;
      await markReviewRequested();
    } catch (e) {
      debugPrint('[ReviewService] Error requesting review: $e');
    }
  }

  /// 条件を満たしていればレビューを依頼
  Future<void> requestReviewIfEligible() async {
    if (await shouldRequestReview()) {
      await requestReview();
    }
  }

  /// AI整理回数をインクリメント
  Future<void> incrementAiSortCount() async {
    final prefs = await SharedPreferences.getInstance();
    final count = (prefs.getInt(_keyAiSortCount) ?? 0) + 1;
    await prefs.setInt(_keyAiSortCount, count);
    debugPrint('[ReviewService] AI sort count: $count');
  }

  /// タスク完了回数をインクリメント
  Future<void> incrementCompletedTaskCount() async {
    final prefs = await SharedPreferences.getInstance();
    final count = (prefs.getInt(_keyCompletedTaskCount) ?? 0) + 1;
    await prefs.setInt(_keyCompletedTaskCount, count);
    debugPrint('[ReviewService] Completed task count: $count');
  }

  /// 最終依頼日を記録 + リクエスト回数をインクリメント
  Future<void> markReviewRequested() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _keyLastRequested, DateTime.now().toIso8601String());

    final requestCount = (prefs.getInt(_keyRequestCount) ?? 0) + 1;
    await prefs.setInt(_keyRequestCount, requestCount);

    // 3回依頼したらレビュー済みとみなす
    if (requestCount >= _maxRequestCount) {
      await prefs.setBool(_keyCompleted, true);
      debugPrint('[ReviewService] Marked as review completed '
          '(request count: $requestCount)');
    }
  }

  /// 全カウンターをリセット（開発者モード用）
  Future<void> resetCounters() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyAiSortCount);
    await prefs.remove(_keyCompletedTaskCount);
    await prefs.remove(_keyLastRequested);
    await prefs.remove(_keyRequestCount);
    await prefs.remove(_keyCompleted);
    _sessionShown = false;
    debugPrint('[ReviewService] Counters reset');
  }
}
