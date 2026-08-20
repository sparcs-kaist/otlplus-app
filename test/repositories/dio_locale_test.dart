import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otlplus/dio_provider.dart';

import '../utils/fake_http.dart';

class CapturingHttpAdapter extends FakeHttpAdapter {
  final receivedLocales = <String?>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    receivedLocales.add(options.headers["Accept-Language"] as String?);
    return super.fetch(options, requestStream, cancelFuture);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DioProvider provider;
  late CapturingHttpAdapter adapter;
  late String locale;

  setUp(() {
    locale = "en";
    DioProvider.configureLocaleSupplier(() => locale);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel("plugins.it_nomads.com/flutter_secure_storage"),
          (call) async => null,
        );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel("org.sparcs.otlplus/token_vault"),
          (call) async => null,
        );
    provider = DioProvider();
    adapter = CapturingHttpAdapter();
    adapter.register("GET", "/locale", null, statusCode: 204);
    provider.dio
      ..httpClientAdapter = adapter
      ..options.baseUrl = "http://test/";
  });

  tearDown(() {
    DioProvider.configureLocaleSupplier(() => "en");
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel("plugins.it_nomads.com/flutter_secure_storage"),
          null,
        );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel("org.sparcs.otlplus/token_vault"),
          null,
        );
  });

  test("uses the current locale supplier for every request", () async {
    await provider.dio.get("locale");
    locale = "ko";
    await provider.dio.get("locale");

    expect(adapter.receivedLocales, ["en", "ko"]);
  });
}
