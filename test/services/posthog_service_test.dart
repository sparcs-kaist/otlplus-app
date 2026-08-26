import 'package:flutter_test/flutter_test.dart';
import 'package:posthog_flutter/posthog_flutter.dart';
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
      await service.capture('test_event');
      await service.reset();
      await service.disable();
    });
  });
  group('PostHogConfiguration host resolution', () {
    test('explicit host wins over region', () {
      const config = PostHogConfiguration(
        apiKey: 'k',
        host: 'https://ph.example.com',
        region: 'eu',
      );
      expect(config.resolvedHost, 'https://ph.example.com');
    });

    test('eu region maps to the eu ingestion host', () {
      const config = PostHogConfiguration(apiKey: 'k', host: '', region: 'eu');
      expect(config.resolvedHost, 'https://eu.i.posthog.com');
    });

    test('unknown or empty region falls back to us', () {
      const config = PostHogConfiguration(apiKey: 'k', host: '', region: '');
      expect(config.resolvedHost, 'https://us.i.posthog.com');
    });
  });

  group('event redaction', () {
    test('exception events pass through with sensitive values redacted', () {
      final service = PostHogService(
        configuration: const PostHogConfiguration(
          apiKey: 'k',
          host: '',
          region: '',
        ),
      );
      final event = PostHogEvent(
        event: r'$exception',
        properties: <String, Object>{
          'exception_message': 'boom',
          'email': 'user@example.com',
        },
      );

      final redacted = service.redactEventForTesting(event);

      expect(
        redacted,
        isNotNull,
        reason: 'error tracking is enabled; exception events must flow',
      );
      expect(redacted!.properties!['exception_message'], 'boom');
      expect(redacted.properties, isNot(contains('email')));
    });
  });
}
