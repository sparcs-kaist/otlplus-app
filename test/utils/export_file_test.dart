import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:otlplus/constants/url.dart';
import 'package:otlplus/utils/export_file.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('org.sparcs.otlplus/export');
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });
  test(
    'iOS export passes the file to the scene-aware native share channel',
    () async {
      MethodCall? received;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            received = call;
        return null;
          });
      await shareIosExport('/tmp/timetable.ics');
      expect(received?.method, 'shareFile');
      expect(received?.arguments, {'path': '/tmp/timetable.ics'});
    },
  );
  test('iOS export propagates native presentation errors', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (_) async {
          throw PlatformException(code: 'export_no_window');
        });
    await expectLater(
      shareIosExport('/tmp/timetable.png'),
      throwsA(isA<PlatformException>()),
    );
  });

  test('writeBytesToFile awaits and persists all bytes', () async {
    final directory = await Directory.systemTemp.createTemp('otl-export-test-');
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}/export.bin');
    final bytes = Uint8List.fromList(<int>[0, 1, 2, 255]);

    await writeBytesToFile(file, bytes);

    expect(await file.readAsBytes(), orderedEquals(bytes));
  });

  test('writeFile ignores a null byte payload', () async {
    await expectLater(writeFile(ShareType.image, null), completes);
  });
}
