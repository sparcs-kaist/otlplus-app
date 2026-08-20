import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:otlplus/constants/url.dart';
import 'package:otlplus/utils/export_file.dart';

void main() {
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
