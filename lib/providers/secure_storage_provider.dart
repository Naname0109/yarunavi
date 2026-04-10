import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/secure_storage_service.dart';

/// SecureStorageService の Provider (main.dart で override される)
final secureStorageServiceProvider = Provider<SecureStorageService>((ref) {
  throw UnimplementedError('secureStorageServiceProvider must be overridden');
});
