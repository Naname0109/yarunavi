import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/task.dart';
import '../models/user_badge.dart';
import '../models/user_stats.dart';
import '../services/gamification_service.dart';
import 'secure_storage_provider.dart';
import 'task_provider.dart';

/// GamificationService の提供。 SecureStorage 経由で XP バックアップを統合 (#2-D)。
final gamificationServiceProvider = Provider<GamificationService>((ref) {
  final db = ref.watch(databaseServiceProvider);
  final secure = ref.watch(secureStorageServiceProvider);
  return GamificationService(db, secureStorage: secure);
});

// ========== Main State ==========

class UserStatsNotifier extends AsyncNotifier<UserStats> {
  GamificationService get _service => ref.read(gamificationServiceProvider);

  @override
  Future<UserStats> build() => _service.getStats();

  /// タスク完了を記録（XP・ストリーク・バッジ・レベル判定を一括処理）。
  /// UI 演出のための [xpFloatingProvider] / [levelUpProvider] / [newBadgesProvider]
  /// もここで発火する。
  ///
  /// [task] は XP 不正取得防止 (#2-B: 作成 1 分以内完了で XP なし) の判定用。
  Future<void> recordTaskCompletion({
    required bool isAllTodayDone,
    required Task task,
  }) async {
    final result = await _service.onTaskCompleted(
      isAllTodayDone: isAllTodayDone,
      task: task,
    );
    state = AsyncValue.data(result.finalStats);
    _broadcastEvents(
      xpAwarded: result.totalXpAwarded,
      leveledUp: result.leveledUp,
      newLevel: result.finalStats.currentLevel,
      newBadges: result.newlyEarnedBadges,
    );
    ref.invalidate(badgesProvider);
    ref.invalidate(activityHeatmapProvider);
  }

  /// AI整理実行を記録。
  Future<void> recordAiSort({required int taskCount}) async {
    final result = await _service.onAiSorted(taskCount: taskCount);
    state = AsyncValue.data(result.finalStats);
    _broadcastEvents(
      xpAwarded: result.totalXpAwarded,
      leveledUp: result.leveledUp,
      newLevel: result.finalStats.currentLevel,
      newBadges: result.newlyEarnedBadges,
    );
    ref.invalidate(badgesProvider);
    ref.invalidate(activityHeatmapProvider);
  }

  /// XPを伴わない操作（タスク追加・編集等）でストリーク維持。
  Future<void> touchActivity() async {
    await _service.touchActivity();
    final fresh = await _service.getStats();
    state = AsyncValue.data(fresh);
  }

  void _broadcastEvents({
    required int xpAwarded,
    required bool leveledUp,
    required int newLevel,
    required List<UserBadge> newBadges,
  }) {
    if (xpAwarded > 0) {
      ref.read(xpFloatingProvider.notifier).state = XpFloatingState(
        amount: xpAwarded,
        id: DateTime.now().microsecondsSinceEpoch,
      );
    }
    if (leveledUp) {
      ref.read(levelUpProvider.notifier).state = LevelUpEvent(
        newLevel: newLevel,
        id: DateTime.now().microsecondsSinceEpoch,
      );
    }
    if (newBadges.isNotEmpty) {
      final current = ref.read(newBadgesProvider);
      ref.read(newBadgesProvider.notifier).state = [...current, ...newBadges];
    }
  }
}

final userStatsProvider =
    AsyncNotifierProvider<UserStatsNotifier, UserStats>(UserStatsNotifier.new);

// ========== Badges ==========

class BadgesNotifier extends AsyncNotifier<List<UserBadge>> {
  GamificationService get _service => ref.read(gamificationServiceProvider);

  @override
  Future<List<UserBadge>> build() => _service.getBadges();
}

final badgesProvider =
    AsyncNotifierProvider<BadgesNotifier, List<UserBadge>>(BadgesNotifier.new);

// ========== Heatmap ==========

/// 過去14日のアクティビティ件数（'YYYY-MM-DD' → 件数）。
final activityHeatmapProvider = FutureProvider<Map<String, int>>((ref) async {
  ref.watch(userStatsProvider);
  return ref.read(gamificationServiceProvider).getActivityHeatmap(days: 14);
});

// ========== UI Event Triggers ==========

/// "+XP" フローティング表示用。
class XpFloatingState {
  XpFloatingState({required this.amount, required this.id});
  final int amount;

  /// 同じ amount でも再発火させるための一意ID
  final int id;
}

final xpFloatingProvider = StateProvider<XpFloatingState?>((_) => null);

/// レベルアップ全画面演出用。
class LevelUpEvent {
  LevelUpEvent({required this.newLevel, required this.id});
  final int newLevel;
  final int id;
}

final levelUpProvider = StateProvider<LevelUpEvent?>((_) => null);

/// 新規バッジ獲得キュー（順次表示用）。
final newBadgesProvider = StateProvider<List<UserBadge>>((_) => const []);
