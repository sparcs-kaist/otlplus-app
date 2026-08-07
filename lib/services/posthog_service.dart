import 'package:posthog_flutter/posthog_flutter.dart';

abstract interface class AnalyticsClient {
  Future<void> capture(String eventName);
  Future<void> initialize();
  Future<void> enable();
  Future<void> disable();
  Future<void> reset();
}

class PostHogConfiguration {
  const PostHogConfiguration({required this.apiKey, required this.host});

  const PostHogConfiguration.fromEnvironment()
    : apiKey = const String.fromEnvironment('POSTHOG_API_KEY'),
      host = const String.fromEnvironment(
        'POSTHOG_HOST',
        defaultValue: 'https://us.i.posthog.com',
      );

  final String apiKey;
  final String host;

  bool get isConfigured => apiKey.isNotEmpty;
}

/// Privacy-safe adapter around the PostHog Flutter SDK.
///
/// PostHog starts disabled and may only be enabled by an explicit analytics
/// preference. It never sends user identities or exceptions.
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
      config.host = _configuration.host;
      config.optOut = true;
      config.captureApplicationLifecycleEvents = true;
      config.preloadFeatureFlags = false;
      config.sendFeatureFlagEvents = false;
      config.sessionReplay = false;
      config.surveys = false;
      config.capturePushNotificationSubscriptions = false;
      config.capturePushNotificationOpened = false;
      config.errorTrackingConfig.captureFlutterErrors = false;
      config.errorTrackingConfig.capturePlatformDispatcherErrors = false;
      config.errorTrackingConfig.captureNativeExceptions = false;
      config.errorTrackingConfig.captureIsolateErrors = false;
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
  Future<void> reset() async {
    if (!_initialized) return;
    await Posthog().reset();
  }

  Future<void> capture(String eventName) async {
    if (!_initialized) return;
    await Posthog().capture(eventName: eventName);
  }

  PostHogEvent? _redactEvent(PostHogEvent event) {
    if (event.event == r'$exception') return null;

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
