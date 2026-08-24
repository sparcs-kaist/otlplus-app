import 'package:flutter_test/flutter_test.dart';

import '../../integration_test/support/credentials.dart';

void main() {
  test('credentials are unavailable without dart-defines', () {
    expect(TestCredentials.email, '');
    expect(TestCredentials.password, '');
    expect(TestCredentials.available, isFalse);
  });

  test('availability requires both email and password', () {
    expect(credentialsAvailable('', ''), isFalse);
    expect(credentialsAvailable('someone@example.com', ''), isFalse);
    expect(credentialsAvailable('', 'secret'), isFalse);
    expect(credentialsAvailable('someone@example.com', 'secret'), isTrue);
  });
}
