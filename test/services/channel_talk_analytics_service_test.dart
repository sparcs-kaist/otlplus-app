import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:otlplus/services/channel_talk_analytics_service.dart';

void main() {
  test('does not track before analytics consent is enabled', () async {
    final trackedEvents = <String>[];
    final service = ChannelTalkAnalyticsService(
      isReady: () async => true,
      track: ({required eventName, properties}) async {
        trackedEvents.add(eventName);
        return true;
      },
    );

    await service.initialize();
    await service.capture('analytics_enabled');

    expect(trackedEvents, isEmpty);
  });

  test('tracks only after ChannelTalk is ready', () async {
    final readiness = Completer<bool>();
    final trackedEvents = <String>[];
    final trackedProperties = <Map<String, dynamic>?>[];
    final service = ChannelTalkAnalyticsService(
      isReady: () => readiness.future,
      track: ({required eventName, properties}) async {
        trackedEvents.add(eventName);
        trackedProperties.add(properties);
        return true;
      },
    );
    await service.enable();

    final capture = service.capture('analytics_enabled');
    await Future<void>.delayed(Duration.zero);
    expect(trackedEvents, isEmpty);

    readiness.complete(true);
    await capture;

    expect(trackedEvents, <String>['analytics_enabled']);
    expect(trackedProperties, <Map<String, dynamic>?>[<String, dynamic>{}]);
  });

  test('does not track when ChannelTalk is unavailable', () async {
    final trackedEvents = <String>[];
    final service = ChannelTalkAnalyticsService(
      isReady: () async => false,
      track: ({required eventName, properties}) async {
        trackedEvents.add(eventName);
        return true;
      },
    );
    await service.enable();

    await service.capture('analytics_enabled');

    expect(trackedEvents, isEmpty);
  });

  test(
    'does not track if consent is withdrawn while readiness is pending',
    () async {
      final readiness = Completer<bool>();
      final trackedEvents = <String>[];
      final service = ChannelTalkAnalyticsService(
        isReady: () => readiness.future,
        track: ({required eventName, properties}) async {
          trackedEvents.add(eventName);
          return true;
        },
      );
      await service.enable();

      final capture = service.capture('analytics_enabled');
      await service.disable();
      readiness.complete(true);
      await capture;

      expect(trackedEvents, isEmpty);
    },
  );
}
