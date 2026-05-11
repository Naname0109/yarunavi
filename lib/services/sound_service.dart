import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// 完了/達成サウンドのトリガー
enum SoundEvent {
  /// AI整理の完了
  aiSortComplete,
  /// 全タスク完了
  allTasksComplete,
  /// 個別タスク完了
  taskComplete,
  /// AI整理失敗 (エラー)
  aiSortError,
}

/// 達成感の演出に使うサウンド + ハプティクス
///
/// 外部パッケージは使わず、Flutter組み込みの `SystemSound.play` と
/// `HapticFeedback` を組み合わせる。
/// - 通常 `play(event)` でサウンド (ON時) + ハプティクスパターンを再生
/// - 視覚演出と合わせたい場合は `playSystemSound` と `playHaptic` を
///   個別に呼び分けて、タイミングを細かく揃えられる
class SoundService {
  /// 設定 ON/OFF。OFF でもハプティクスは残す（達成感の最低限を保証）
  bool enabled = true;

  /// イベントに合わせたサウンド + ハプティクスを順次再生
  Future<void> play(SoundEvent event) async {
    // ハプティクスは非同期で先行、サウンドは並行で発火
    final hapticFuture = playHaptic(event);
    if (enabled) await playSystemSound(event);
    await hapticFuture;
  }

  /// サウンドだけ再生 (ハプティクスは別タイミングで叩きたいケース用)
  Future<void> playSystemSound(SoundEvent event) async {
    if (!enabled) return;
    try {
      final type = switch (event) {
        SoundEvent.aiSortComplete => SystemSoundType.alert,
        SoundEvent.allTasksComplete => SystemSoundType.alert,
        SoundEvent.taskComplete => SystemSoundType.click,
        SoundEvent.aiSortError => SystemSoundType.click,
      };
      await SystemSound.play(type);
    } catch (e) {
      debugPrint('[Sound] system sound error: $e');
    }
  }

  /// ハプティクスパターンだけ再生
  Future<void> playHaptic(SoundEvent event) async {
    try {
      switch (event) {
        case SoundEvent.aiSortComplete:
          // 3段階パターン: heavy(キメ) → medium(発散) → light(着地)
          HapticFeedback.heavyImpact();
          await Future.delayed(const Duration(milliseconds: 120));
          HapticFeedback.mediumImpact();
          await Future.delayed(const Duration(milliseconds: 230));
          HapticFeedback.lightImpact();
        case SoundEvent.allTasksComplete:
          // ファンファーレ感: heavy → medium → heavy (盛り上がり)
          HapticFeedback.heavyImpact();
          await Future.delayed(const Duration(milliseconds: 100));
          HapticFeedback.mediumImpact();
          await Future.delayed(const Duration(milliseconds: 120));
          HapticFeedback.heavyImpact();
        case SoundEvent.taskComplete:
          HapticFeedback.selectionClick();
        case SoundEvent.aiSortError:
          // notificationError相当: heavy → medium (短く強めの否定パターン)
          HapticFeedback.heavyImpact();
          await Future.delayed(const Duration(milliseconds: 80));
          HapticFeedback.mediumImpact();
      }
    } catch (e) {
      debugPrint('[Sound] haptic error: $e');
    }
  }
}
