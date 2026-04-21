import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

Future<void> main() => integrationDriver(
      onScreenshot: (String name, List<int> bytes,
          [Map<String, Object?>? args]) async {
        final outDir = Directory('screenshots/raw');
        if (!outDir.existsSync()) outDir.createSync(recursive: true);

        final path = '${outDir.path}/$name.png';

        File(path).writeAsBytesSync(bytes);
        final kb = (bytes.length / 1024).toStringAsFixed(1);
        print('[SCREENSHOT] Saved: $path (${kb}KB)');
        return true;
      },
    );
