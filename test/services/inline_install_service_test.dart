import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otlplus/services/inline_install_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channelName = 'org.sparcs.otlplus';

  group('InlineInstallService', () {
    late List<MethodCall> calls;
    late List<Uri> launchedUrls;
    Object? Function(MethodCall call)? handler;

    setUp(() {
      calls = <MethodCall>[];
      launchedUrls = <Uri>[];
      handler = null;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(const MethodChannel(channelName), (
            call,
          ) async {
            calls.add(call);
            return handler?.call(call);
          });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(const MethodChannel(channelName), null);
    });

    InlineInstallService buildService({bool isAndroid = true}) {
      return InlineInstallService(
        channel: const MethodChannel(channelName),
        platformIsAndroid: () => isAndroid,
        launchFallback: (uri) async {
          launchedUrls.add(uri);
        },
      );
    }

    test(
      'android overlay success sends documented intent parameters',
      () async {
        handler = (call) => true;

        final overlayLaunched = await buildService().startInlineInstall(
          'com.example.target',
          referrer: 'utm_source%3Dotlplus',
          listing: 'promo-listing',
        );

        expect(overlayLaunched, isTrue);
        expect(launchedUrls, isEmpty);
        expect(calls, hasLength(1));
        expect(calls.single.method, 'startInlineInstall');
        expect(calls.single.arguments, <String, dynamic>{
          'packageName': 'com.example.target',
          'referrer': 'utm_source%3Dotlplus',
          'listing': 'promo-listing',
        });
      },
    );

    test('optional parameters are omitted when absent', () async {
      handler = (call) => true;

      await buildService().startInlineInstall('com.example.target');

      expect(calls.single.arguments, <String, dynamic>{
        'packageName': 'com.example.target',
        'referrer': null,
        'listing': null,
      });
    });

    test(
      'falls back to the play store listing when overlay is unsupported',
      () async {
        handler = (call) => false;

        final overlayLaunched = await buildService().startInlineInstall(
          'com.example.target',
        );

        expect(overlayLaunched, isFalse);
        expect(
          launchedUrls.single,
          Uri.parse(
            'https://play.google.com/store/apps/details?id=com.example.target',
          ),
        );
      },
    );

    test('falls back to the play store listing on platform errors', () async {
      handler = (call) => throw PlatformException(code: 'BLOCKED');

      final overlayLaunched = await buildService().startInlineInstall(
        'com.example.target',
      );

      expect(overlayLaunched, isFalse);
      expect(
        launchedUrls.single,
        Uri.parse(
          'https://play.google.com/store/apps/details?id=com.example.target',
        ),
      );
    });

    test(
      'non-android platforms go straight to the play store listing',
      () async {
        final service = buildService(isAndroid: false);

        final overlayLaunched = await service.startInlineInstall(
          'com.example.target',
        );

        expect(overlayLaunched, isFalse);
        expect(calls, isEmpty);
        expect(
          launchedUrls.single,
          Uri.parse(
            'https://play.google.com/store/apps/details?id=com.example.target',
          ),
        );
      },
    );

    test('rejects empty package names before touching any channel', () async {
      final service = buildService(isAndroid: false);

      expect(() => service.startInlineInstall(''), throwsArgumentError);
      expect(() => service.startInlineInstall('  '), throwsArgumentError);
      expect(calls, isEmpty);
      expect(launchedUrls, isEmpty);
    });
  });
}
