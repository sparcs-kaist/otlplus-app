import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otlplus/services/optional_bootstrap.dart';

void main() {
  test(
    'boots channeltalk and registers push token when messaging succeeds',
    () async {
      final bootMemberHashes = <String?>[];
      final pushTokens = <String>[];
      var channelButtonCalls = 0;
      final recordedErrors = <Object>[];

      final bootstrap = OptionalBootstrap(
        requestPermission: () async {},
        getAPNSToken: () async => 'apns',
        getToken: () => Future<String?>.value('tok'),
        channelTalkBoot: ({String? memberHash}) async {
          bootMemberHashes.add(memberHash);
          return true;
        },
        initPushToken: (token) async {
          pushTokens.add(token);
        },
        showChannelButton: () async {
          channelButtonCalls += 1;
        },
        recordNonFatal: (error, stack) async {
          recordedErrors.add(error);
        },
        isIOS: false,
      );

      await bootstrap.run();

      expect(bootMemberHashes, ['tok']);
      expect(pushTokens, ['tok']);
      expect(channelButtonCalls, 1);
      expect(recordedErrors, isEmpty);
    },
  );

  test(
    'skips fcm token when ios apns token is missing and still boots channeltalk',
    () async {
      var getTokenCalls = 0;
      final bootMemberHashes = <String?>[];
      final pushTokens = <String>[];
      var channelButtonCalls = 0;

      final bootstrap = OptionalBootstrap(
        requestPermission: () async {},
        getAPNSToken: () async => null,
        getToken: () {
          getTokenCalls += 1;
          return Future<String?>.value('unexpected-token');
        },
        channelTalkBoot: ({String? memberHash}) async {
          bootMemberHashes.add(memberHash);
          return true;
        },
        initPushToken: (token) async {
          pushTokens.add(token);
        },
        showChannelButton: () async {
          channelButtonCalls += 1;
        },
        recordNonFatal: (error, stack) async {},
        isIOS: true,
      );

      await bootstrap.run();

      expect(getTokenCalls, 0);
      expect(bootMemberHashes, [null]);
      expect(pushTokens, isEmpty);
      expect(channelButtonCalls, 1);
    },
  );

  test(
    'records non-fatal and still boots channeltalk when getToken throws',
    () async {
      final recordedErrors = <Object>[];
      final bootMemberHashes = <String?>[];

      final bootstrap = OptionalBootstrap(
        requestPermission: () async {},
        getAPNSToken: () async => 'apns',
        getToken: () => Future<String?>.error(
          FirebaseException(
            plugin: 'firebase_messaging',
            code: 'TOO_MANY_REGISTRATIONS',
          ),
        ),
        channelTalkBoot: ({String? memberHash}) async {
          bootMemberHashes.add(memberHash);
          return true;
        },
        initPushToken: (token) async {},
        showChannelButton: () async {},
        recordNonFatal: (error, stack) async {
          recordedErrors.add(error);
        },
        isIOS: false,
      );

      await bootstrap.run();

      expect(recordedErrors, hasLength(1));
      expect(bootMemberHashes, [null]);
    },
  );

  test(
    'skips init push token and channel button when boot returns false',
    () async {
      final pushTokens = <String>[];
      var channelButtonCalls = 0;

      final bootstrap = OptionalBootstrap(
        requestPermission: () async {},
        getAPNSToken: () async => 'apns',
        getToken: () => Future<String?>.value('tok'),
        channelTalkBoot: ({String? memberHash}) async => false,
        initPushToken: (token) async {
          pushTokens.add(token);
        },
        showChannelButton: () async {
          channelButtonCalls += 1;
        },
        recordNonFatal: (error, stack) async {},
        isIOS: false,
      );

      await bootstrap.run();

      expect(pushTokens, isEmpty);
      expect(channelButtonCalls, 0);
    },
  );

  test('does not call init push token when token is empty', () async {
    final bootMemberHashes = <String?>[];
    final pushTokens = <String>[];
    var channelButtonCalls = 0;

    final bootstrap = OptionalBootstrap(
      requestPermission: () async {},
      getAPNSToken: () async => 'apns',
      getToken: () => Future<String?>.value(''),
      channelTalkBoot: ({String? memberHash}) async {
        bootMemberHashes.add(memberHash);
        return true;
      },
      initPushToken: (token) async {
        pushTokens.add(token);
      },
      showChannelButton: () async {
        channelButtonCalls += 1;
      },
      recordNonFatal: (error, stack) async {},
      isIOS: false,
    );

    await bootstrap.run();

    expect(bootMemberHashes, ['']);
    expect(pushTokens, isEmpty);
    expect(channelButtonCalls, 1);
  });

  test('records non-fatal when channeltalk boot times out', () async {
    final recordedErrors = <Object>[];
    final neverCompletes = Completer<bool?>();

    final bootstrap = OptionalBootstrap(
      requestPermission: () async {},
      getAPNSToken: () async => 'apns',
      getToken: () => Future<String?>.value('tok'),
      channelTalkBoot: ({String? memberHash}) => neverCompletes.future,
      initPushToken: (token) async {},
      showChannelButton: () async {},
      recordNonFatal: (error, stack) async {
        recordedErrors.add(error);
      },
      isIOS: false,
      bootTimeout: const Duration(milliseconds: 10),
    );

    await bootstrap.run();

    expect(recordedErrors, hasLength(1));
    expect(recordedErrors.single, isA<TimeoutException>());
  });

  test(
    'never completes with error even when every dependency throws',
    () async {
      var recordNonFatalCalls = 0;

      final bootstrap = OptionalBootstrap(
        requestPermission: () async {
          throw StateError('request permission failed');
        },
        getAPNSToken: () async {
          throw StateError('get APNS token failed');
        },
        getToken: () => Future<String?>.error(StateError('get token failed')),
        channelTalkBoot: ({String? memberHash}) async {
          throw StateError('boot failed');
        },
        initPushToken: (token) async {
          throw StateError('init push token failed');
        },
        showChannelButton: () async {
          throw StateError('show channel button failed');
        },
        recordNonFatal: (error, stack) async {
          recordNonFatalCalls += 1;
          throw StateError('record non-fatal failed');
        },
        isIOS: true,
      );

      await expectLater(bootstrap.run(), completes);
      expect(recordNonFatalCalls, 2);
    },
  );
}
