import 'package:flutter_test/flutter_test.dart';
import 'package:otlplus/constants/url.dart';

void main() {
  test('pins session login and external URLs', () {
    expect(SESSION_LOGIN_URL, 'session/login/');
    expect(ExternalUrls.sparcsRecruiting, 'https://apply.sparcs.org/');
    expect(
      ExternalUrls.appEvent,
      'https://docs.google.com/forms/d/e/1FAIpQLSfZbU_TFUPN53De_ihtS4ZK5Tb_nRDazRS7EYQgp3QWAYvyhQ/viewform',
    );
  });
}
