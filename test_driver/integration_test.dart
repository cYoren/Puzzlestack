// Driver for the screenshot integration test.
// Receives screenshot bytes from the device and writes them to screenshots/raw/.

import 'dart:io';
import 'package:integration_test/integration_test_driver_extended.dart';

Future<void> main() async {
  await integrationDriver(
    onScreenshot: (
      String name,
      List<int> bytes, [
      Map<String, Object?>? args,
    ]) async {
      final dir = Directory('screenshots/raw');
      if (!dir.existsSync()) {
        dir.createSync(recursive: true);
      }
      final file = File('screenshots/raw/$name.png');
      await file.writeAsBytes(bytes);
      // ignore: avoid_print
      print('Saved screenshots/raw/$name.png (${bytes.length} bytes)');
      return true;
    },
  );
}
