/// Compile-time SSO credentials for the authenticated integration test.
///
/// Values arrive via `--dart-define=TEST_SSO_EMAIL=...` and
/// `--dart-define=TEST_SSO_PASSWORD=...` (CI injects them from Doppler).
/// `Platform.environment` is deliberately NOT used: the CI shell environment
/// is not visible inside the app process on a device or simulator.
///
/// NEVER log these values anywhere — they are baked into the compiled test
/// binary, which is acceptable only for a dedicated, artifact-free CI job.
class TestCredentials {
  const TestCredentials._();

  static const email = String.fromEnvironment('TEST_SSO_EMAIL');
  static const password = String.fromEnvironment('TEST_SSO_PASSWORD');

  static bool get available => credentialsAvailable(email, password);
}

/// Pure function so the availability rule stays unit-testable despite
/// `String.fromEnvironment` being compile-time only.
bool credentialsAvailable(String email, String password) =>
    email.isNotEmpty && password.isNotEmpty;
