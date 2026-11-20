import 'dart:convert';
import 'dart:async';
import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

Future<void> main() async {
  final output = Directory(
    Platform.environment['DOKOSHADO_CHECK_OUTPUT'] ?? 'build/device-check',
  );
  await output.create(recursive: true);
  final adb = '${Platform.environment['ANDROID_HOME']}/platform-tools/adb.exe';
  var checking = false;
  var dismissed = false;
  final watcher = Timer.periodic(const Duration(seconds: 1), (_) async {
    if (checking || dismissed) return;
    checking = true;
    try {
      final window = await Process.run(adb, ['shell', 'dumpsys', 'window']);
      final focus = (window.stdout as String)
          .split('\n')
          .where((line) => line.contains('mCurrentFocus'))
          .join();
      if (RegExp('ChooserActivity|ResolverActivity|intentresolver')
          .hasMatch(focus)) {
        await Process.run(adb, ['shell', 'input', 'keyevent', '4']);
        dismissed = true;
        await File('${output.path}/native-share-check.txt').writeAsString(
          'PASS: Android native share sheet opened and was cancelled without sending.',
        );
      }
    } finally {
      checking = false;
    }
  });
  try {
    await integrationDriver(
      onScreenshot: (name, bytes, [args]) async {
        await File('${output.path}/$name.png').writeAsBytes(bytes);
        return true;
      },
      responseDataCallback: (data) async {
        if (data == null) return;
        final png = data.remove('sharePng') as String?;
        final images = data.remove('images') as Map<String, dynamic>?;
        if (images != null) {
          for (final entry in images.entries) {
            await File('${output.path}/${entry.key}.png')
                .writeAsBytes(base64Decode(entry.value as String));
          }
        }
        if (png != null)
          await File('${output.path}/07-shared-image.png')
              .writeAsBytes(base64Decode(png));
        await File('${output.path}/device-results.json')
            .writeAsString(jsonEncode(data));
      },
    );
  } finally {
    watcher.cancel();
  }
}
