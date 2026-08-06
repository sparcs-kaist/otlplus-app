import 'package:flutter_test/flutter_test.dart';
import 'package:otlplus/services/posthog_service.dart';

void main() {
  group('PostHogConfiguration', () {
    test('is disabled when no project token is supplied', () {
      const configuration = PostHogConfiguration(
        apiKey: '',
        host: 'https://us.i.posthog.com',
      );

      expect(configuration.isConfigured, isFalse);
    });

    test('is enabled when a project token is supplied', () {
      const configuration = PostHogConfiguration(
        apiKey: 'phc_test',
        host: 'https://us.i.posthog.com',
      );

      expect(configuration.isConfigured, isTrue);
    });
  });

  group('PostHogService', () {
    test('is a safe no-op without a project token', () async {
      final service = PostHogService(
        configuration: const PostHogConfiguration(
          apiKey: '',
          host: 'https://us.i.posthog.com',
        ),
      );

      await service.initialize();
      await service.enable();
      await service.capture('test_event', properties: <String, Object>{});
      await service.reset();
      await service.disable();
    });
  });
}
