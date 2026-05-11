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
}

/// 達成感の演出に使うサウンド + ハプティクス
///
/// 外部パッケージは使わず、Flutter組み込みの `SystemSound.play` と
/// `HapticFeedback` を組み合わせる。
/// - サウンドON時: ハプティクス＋システムサウンド
/// - サウンドOFF時: ハプティクスのみ（達成感の最低限を残す）
class SoundService {
  bool enabled = true;

  /// イベントに合わせたサウンド+ハプティクスを再生
  Future<void> play(SoundEvent event) async {
    await _hapticPattern(event);
    if (enabled) {
      await _systemSound(event);
    }
  }

  Future<void> _hapticPattern(SoundEvent event) async {
    try {
      switch (event) {
        case SoundEvent.aiSortComplete:
          HapticFeedback.heavyImpact();
          await Future.delayed(const Duration(milliseconds: 50));
          HapticFeedback.mediumImpact();
          await Future.delayed(const Duration(milliseconds: 50));
          HapticFeedback.lightImpact();
        case SoundEvent.allTasksComplete:
          HapticFeedback.heavyImpact();
          await Future.delayed(const Duration(milliseconds: 80));
          HapticFeedback.mediumImpact();
          await Future.delayed(const Duration(milliseconds: 80));
          HapticFeedback.heavyImpact();
        case SoundEvent.taskComplete:
          HapticFeedback.selectionClick();
      }
    } catch (e) {
      debugPrint('[Sound] haptic error: $e');
    }
  }

  Future<void> _systemSound(SoundEvent event) async {
    try {
      final type = switch (event) {
        SoundEvent.aiSortComplete => SystemSoundType.alert,
        SoundEvent.allTasksComplete => SystemSoundType.alert,
        SoundEvent.taskComplete => SystemSoundType.click,
      };
      await SystemSound.play(type);
    } catch (e) {
      debugPrint('[Sound] system sound error: $e');
    }
  }
}
