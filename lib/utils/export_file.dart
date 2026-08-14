import 'dart:io';
import 'dart:ui';

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:otlplus/constants/url.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:open_app_file/open_app_file.dart';

const MethodChannel _channel = const MethodChannel("org.sparcs.otlplus");

Future<void> exportImage(RenderRepaintBoundary boundary) async {
  final image = await boundary.toImage(pixelRatio: 3.0);
  final byteData = await image.toByteData(format: ImageByteFormat.png);

  writeFile(ShareType.image, byteData?.buffer.asUint8List());
}

Future<void> writeFile(ShareType type, Uint8List? bytes) async {
  final fileName =
      "OTL-${DateTime.now().millisecondsSinceEpoch}.${type == ShareType.image ? 'png' : 'ics'}";

  if (Platform.isAndroid) {
    if (type == ShareType.image) {
      final int? sdkInt = await _channel.invokeMethod<int>('getAndroidVersion');
      if (sdkInt != null && sdkInt <= 28) {
        if (!(await Permission.storage.request().isGranted)) {
          return;
        }
      }
      _channel.invokeMethod("writeImageAsBytes", <String, dynamic>{
        "fileName": fileName,
        "bytes": bytes,
      });
    } else if (type == ShareType.ical) {
      final directory = await getExternalStorageDirectory();
      final path =
          "${directory?.path ?? '/storage/emulated/0/Android/data/org.sparcs.otlplus/files'}/$fileName";
      File(path).writeAsBytesSync(bytes as List<int>);
      OpenAppFile.open(path);
    }
  } else {
    final directory = await getApplicationDocumentsDirectory();
    final path = "${directory.path}/$fileName";
    File(path).writeAsBytesSync(bytes as List<int>);
    OpenAppFile.open(path);
  }
}
