import 'dart:convert';
import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

Future<void> main() async {
  final output = Directory(
    Platform.environment['DOKOSHADO_CHECK_OUTPUT'] ?? 'build/device-check',
  );
  await output.create(recursive: true);
  await integrationDriver(
    onScreenshot: (name, bytes, [args]) async {
      await File('${output.path}/$name.png').writeAsBytes(bytes);
      return true;
    },
    responseDataCallback: (data) async {
      if (data == null) return;
      final png = data.remove('sharePng') as String?;
      if (png != null)
        await File('${output.path}/07-shared-image.png')
            .writeAsBytes(base64Decode(png));
      await File('${output.path}/device-results.json')
          .writeAsString(jsonEncode(data));
    },
  );
}
