import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/sound_service.dart';
import 'settings_provider.dart';

/// SoundServiceのProvider
/// soundEnabledProviderの変更に応じて enabled フラグを同期する
final soundServiceProvider = Provider<SoundService>((ref) {
  final service = SoundService();
  service.enabled = ref.watch(soundEnabledProvider);
  return service;
});
