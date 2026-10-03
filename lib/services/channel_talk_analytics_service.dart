import 'package:channel_talk_flutter/channel_talk_flutter.dart';
import 'package:otlplus/services/channel_talk_readiness.dart';

typedef ChannelTalkReady = Future<bool> Function();
typedef ChannelTalkTrack =
    Future<bool?> Function({
      required String eventName,
      Map<String, dynamic>? properties,
    });

abstract interface class AnalyticsClient {
  Future<void> capture(String eventName);
  Future<void> initialize();
  Future<void> enable();
  Future<void> disable();
  Future<void> reset();
}

/// Consent gate for explicit ChannelTalk analytics events.
///
/// ChannelTalk boot and user synchronization are managed separately so
/// disabling analytics does not disconnect customer support features.
class ChannelTalkAnalyticsService implements AnalyticsClient {
  ChannelTalkAnalyticsService({
    ChannelTalkReady? isReady,
    ChannelTalkTrack? track,
  }) : _isReady = isReady ?? _sharedReadiness,
       _track = track ?? ChannelTalk.track;

  final ChannelTalkReady _isReady;
  final ChannelTalkTrack _track;
  bool _enabled = false;

  @override
  Future<void> initialize() async {}

  @override
  Future<void> enable() async {
    _enabled = true;
  }

  @override
  Future<void> disable() async {
    _enabled = false;
  }

  @override
  Future<void> reset() async {}

  @override
  Future<void> capture(String eventName) async {
    if (!_enabled) return;

    final ready = await _isReady();
    if (!_enabled || !ready) return;

    await _track(eventName: eventName, properties: const <String, dynamic>{});
  }

  static Future<bool> _sharedReadiness() => sharedChannelTalkReadiness.isReady;
}
