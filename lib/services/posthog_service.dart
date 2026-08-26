import 'package:flutter/foundation.dart';
import 'package:posthog_flutter/posthog_flutter.dart';

abstract interface class AnalyticsClient {
  Future<void> capture(String eventName);
  Future<void> identify(String distinctId);
  Future<void> initialize();
  Future<void> enable();
  Future<void> disable();
  Future<void> reset();
}

class PostHogConfiguration {
  const PostHogConfiguration({
    required this.apiKey,
    required this.host,
    this.region = '',
    this.projectId = '',
  });

  const PostHogConfiguration.fromEnvironment()
    : apiKey = const String.fromEnvironment('POSTHOG_API_KEY'),
      host = const String.fromEnvironment('POSTHOG_HOST'),
      region = const String.fromEnvironment('POSTHOG_REGION'),
      projectId = const String.fromEnvironment('POSTHOG_PROJECT_ID');

  final String apiKey;
  final String host;
  final String region;

  /// Project reference for tooling (e.g. symbolication); unused by the SDK.
  final String projectId;

  bool get isConfigured => apiKey.isNotEmpty;

  /// Explicit host wins; otherwise the region picks the ingestion endpoint.
  String get resolvedHost {
    if (host.isNotEmpty) return host;
    if (region.toLowerCase() == 'eu') return 'https://eu.i.posthog.com';
    return 'https://us.i.posthog.com';
  }
}

/// Privacy-safe adapter around the PostHog Flutter SDK.
///
/// PostHog starts disabled and may only be enabled by an explicit analytics
/// preference. Error tracking and identity attach only under that same
/// consent. Session replay keeps text and platform views (including login
/// WebViews) masked; images are visible for context.
class PostHogService implements AnalyticsClient {
  PostHogService({
    PostHogConfiguration configuration =
        const PostHogConfiguration.fromEnvironment(),
  }) : _configuration = configuration;

  static const Set<String> _sensitivePropertyNames = <String>{
    'authorization',
    'access_token',
    'cookie',
    'email',
    'name',
    'password',
    'refresh_token',
    'student_id',
    'studentid',
    'token',
    'user_id',
    'userid',
  };

  final PostHogConfiguration _configuration;
  bool _initialized = false;

  bool get isConfigured => _configuration.isConfigured;

  @override
  Future<void> initialize() async {
    if (!isConfigured || _initialized) return;

    try {
      final config = PostHogConfig(_configuration.apiKey);
      config.host = _configuration.resolvedHost;
      config.optOut = true;
      config.captureApplicationLifecycleEvents = true;
      config.preloadFeatureFlags = true;
      config.sendFeatureFlagEvents = true;
      config.sessionReplay = true;
      config.sessionReplayConfig.maskAllTexts = true;
      config.sessionReplayConfig.maskAllImages = false;
      config.sessionReplayConfig.maskAllPlatformViews = true;
      config.sessionReplayConfig.throttleDelay = const Duration(seconds: 1);
      config.surveys = true;
      config.capturePushNotificationSubscriptions = false;
      config.capturePushNotificationOpened = false;
      config.errorTrackingConfig.captureFlutterErrors = true;
      config.errorTrackingConfig.capturePlatformDispatcherErrors = true;
      config.errorTrackingConfig.captureNativeExceptions = true;
      config.errorTrackingConfig.captureIsolateErrors = true;
      config.beforeSend = <BeforeSendCallback>[_redactEvent];

      await Posthog().setup(config);
      _initialized = true;
    } catch (_) {}
  }

  @override
  Future<void> enable() async {
    if (!_initialized) return;
    await Posthog().enable();
  }

  @override
  Future<void> disable() async {
    if (!_initialized) return;
    await Posthog().disable();
  }

  @override
  Future<void> identify(String distinctId) async {
    if (!_initialized || distinctId.isEmpty) return;
    await Posthog().identify(userId: distinctId);
  }

  @visibleForTesting
  PostHogEvent? redactEventForTesting(PostHogEvent event) =>
      _redactEvent(event);

  @override
  Future<void> reset() async {
    if (!_initialized) return;
    await Posthog().reset();
  }

  @override
  Future<void> capture(String eventName) async {
    if (!_initialized) return;
    await Posthog().capture(eventName: eventName);
  }

  PostHogEvent? _redactEvent(PostHogEvent event) {
    final properties = event.properties;
    if (properties != null) _redactProperties(properties);
    return event;
  }

  void _redactProperties(Map<String, Object> properties) {
    properties.removeWhere(
      (key, _) => _sensitivePropertyNames.contains(key.toLowerCase()),
    );
    for (final value in properties.values) {
      if (value is Map<String, Object>) _redactProperties(value);
    }
  }
}
