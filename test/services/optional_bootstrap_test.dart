import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otlplus/services/channel_talk_readiness.dart';
import 'package:otlplus/services/optional_bootstrap.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

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
        onTokenRefresh: () => const Stream<String>.empty(),
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

  test('shows channel button even when init push token fails', () async {
    var channelButtonCalls = 0;
    final recordedErrors = <Object>[];

    final bootstrap = OptionalBootstrap(
      requestPermission: () async {},
      getAPNSToken: () async => 'apns',
      getToken: () => Future<String?>.value('tok'),
      onTokenRefresh: () => const Stream<String>.empty(),
      channelTalkBoot: ({String? memberHash}) async => true,
      initPushToken: (token) async {
        throw StateError('init push token failed');
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

    expect(channelButtonCalls, 1);
    expect(recordedErrors, hasLength(1));
  });

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
        onTokenRefresh: () => const Stream<String>.empty(),
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
        apnsMaxAttempts: 1,
      );

      await bootstrap.run();

      expect(getTokenCalls, 0);
      expect(bootMemberHashes, [null]);
      expect(pushTokens, isEmpty);
      expect(channelButtonCalls, 1);
    },
  );

  test('retries apns token before giving up on ios', () async {
    var apnsTokenCalls = 0;
    var getTokenCalls = 0;
    final bootMemberHashes = <String?>[];

    final bootstrap = OptionalBootstrap(
      requestPermission: () async {},
      getAPNSToken: () async {
        apnsTokenCalls += 1;
        return apnsTokenCalls < 3 ? null : 'apns';
      },
      getToken: () {
        getTokenCalls += 1;
        return Future<String?>.value('tok');
      },
      onTokenRefresh: () => const Stream<String>.empty(),
      channelTalkBoot: ({String? memberHash}) async {
        bootMemberHashes.add(memberHash);
        return true;
      },
      initPushToken: (token) async {},
      showChannelButton: () async {},
      recordNonFatal: (error, stack) async {},
      delay: (duration) async {},
      isIOS: true,
    );

    await bootstrap.run();

    expect(apnsTokenCalls, 3);
    expect(getTokenCalls, 1);
    expect(bootMemberHashes, ['tok']);
  });

  test(
    'records non-fatal and boots without token when apns never arrives',
    () async {
      var getTokenCalls = 0;
      final recordedErrors = <Object>[];
      final bootMemberHashes = <String?>[];

      final bootstrap = OptionalBootstrap(
        requestPermission: () async {},
        getAPNSToken: () async => null,
        getToken: () {
          getTokenCalls += 1;
          return Future<String?>.value('unexpected-token');
        },
        onTokenRefresh: () => const Stream<String>.empty(),
        channelTalkBoot: ({String? memberHash}) async {
          bootMemberHashes.add(memberHash);
          return true;
        },
        initPushToken: (token) async {},
        showChannelButton: () async {},
        recordNonFatal: (error, stack) async {
          recordedErrors.add(error);
        },
        delay: (duration) async {},
        isIOS: true,
        apnsMaxAttempts: 3,
      );

      await bootstrap.run();

      expect(getTokenCalls, 0);
      expect(recordedErrors, hasLength(1));
      expect(bootMemberHashes, [null]);
    },
  );

  test('records non-fatal when fcm token times out', () async {
    final recordedErrors = <Object>[];
    final bootMemberHashes = <String?>[];
    final neverCompletes = Completer<String?>();

    final bootstrap = OptionalBootstrap(
      requestPermission: () async {},
      getAPNSToken: () async => 'apns',
      getToken: () => neverCompletes.future,
      onTokenRefresh: () => const Stream<String>.empty(),
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
      tokenTimeout: const Duration(milliseconds: 10),
    );

    await bootstrap.run();

    expect(recordedErrors, hasLength(1));
    expect(bootMemberHashes, [null]);
  });

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
        onTokenRefresh: () => const Stream<String>.empty(),
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

  test('marks channeltalk unavailable when boot returns false', () async {
    final readiness = ChannelTalkReadiness();
    final bootstrap = OptionalBootstrap(
      requestPermission: () async {},
      getAPNSToken: () async => 'apns',
      getToken: () async => null,
      onTokenRefresh: () => const Stream<String>.empty(),
      channelTalkBoot: ({String? memberHash}) async => false,
      initPushToken: (token) async {},
      showChannelButton: () async {},
      recordNonFatal: (error, stack) async {},
      channelTalkReadiness: readiness,
      isIOS: false,
    );
    addTearDown(bootstrap.dispose);

    await bootstrap.run();
    final isReady = await readiness.isReady.timeout(
      const Duration(milliseconds: 10),
      onTimeout: () => true,
    );

    expect(isReady, isFalse);
  });

  test('marks channeltalk unavailable when boot throws', () async {
    final readiness = ChannelTalkReadiness();
    final bootstrap = OptionalBootstrap(
      requestPermission: () async {},
      getAPNSToken: () async => 'apns',
      getToken: () async => null,
      onTokenRefresh: () => const Stream<String>.empty(),
      channelTalkBoot: ({String? memberHash}) async {
        throw StateError('boot failed');
      },
      initPushToken: (token) async {},
      showChannelButton: () async {},
      recordNonFatal: (error, stack) async {},
      channelTalkReadiness: readiness,
      isIOS: false,
    );
    addTearDown(bootstrap.dispose);

    await bootstrap.run();
    final isReady = await readiness.isReady.timeout(
      const Duration(milliseconds: 10),
      onTimeout: () => true,
    );

    expect(isReady, isFalse);
  });

  test('records non-fatal when channeltalk boot returns false', () async {
    final recordedErrors = <Object>[];
    final pushTokens = <String>[];
    var channelButtonCalls = 0;

    final bootstrap = OptionalBootstrap(
      requestPermission: () async {},
      getAPNSToken: () async => 'apns',
      getToken: () => Future<String?>.value('tok'),
      onTokenRefresh: () => const Stream<String>.empty(),
      channelTalkBoot: ({String? memberHash}) async => false,
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

    expect(recordedErrors, hasLength(1));
    expect(pushTokens, isEmpty);
    expect(channelButtonCalls, 0);
  });

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
      onTokenRefresh: () => const Stream<String>.empty(),
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
      onTokenRefresh: () => const Stream<String>.empty(),
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

  test('cancels the token refresh subscription when boot fails', () async {
    final tokenRefreshController = StreamController<String>.broadcast();
    final bootstrap = OptionalBootstrap(
      requestPermission: () async {},
      getAPNSToken: () async => 'apns',
      getToken: () async => null,
      onTokenRefresh: () => tokenRefreshController.stream,
      channelTalkBoot: ({String? memberHash}) async => false,
      initPushToken: (token) async {},
      showChannelButton: () async {},
      recordNonFatal: (error, stack) async {},
      isIOS: false,
    );
    addTearDown(() async {
      await bootstrap.dispose();
      await tokenRefreshController.close();
    });

    await bootstrap.run();

    expect(tokenRefreshController.hasListener, isFalse);
  });

  test(
    'records non-fatal and unblocks the queue when push token registration hangs',
    () async {
      final tokenRefreshController = StreamController<String>.broadcast();
      final firstRegistrationStarted = Completer<void>();
      final finishFirstRegistration = Completer<void>();
      final recordedErrors = <Object>[];
      final registeredTokens = <String>[];
      final bootstrap = OptionalBootstrap(
        requestPermission: () async {},
        getAPNSToken: () async => 'apns',
        getToken: () async => null,
        onTokenRefresh: () => tokenRefreshController.stream,
        channelTalkBoot: ({String? memberHash}) async => true,
        initPushToken: (token) async {
          if (token == 'first') {
            firstRegistrationStarted.complete();
            await finishFirstRegistration.future;
          } else {
            registeredTokens.add(token);
          }
        },
        showChannelButton: () async {},
        recordNonFatal: (error, stack) async {
          recordedErrors.add(error);
        },
        isIOS: false,
        pushTokenTimeout: const Duration(milliseconds: 5),
      );
      addTearDown(() async {
        if (!finishFirstRegistration.isCompleted) {
          finishFirstRegistration.complete();
        }
        await Future<void>.delayed(Duration.zero);
        await bootstrap.dispose();
        await tokenRefreshController.close();
      });

      await bootstrap.run();
      tokenRefreshController.add('first');
      await firstRegistrationStarted.future;
      tokenRefreshController.add('second');
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(recordedErrors, hasLength(1));
      expect(registeredTokens, <String>['second']);
    },
  );

  test('forwards refreshed tokens to channeltalk after boot', () async {
    final tokenRefreshController = StreamController<String>.broadcast();
    final pushTokens = <String>[];

    final bootstrap = OptionalBootstrap(
      requestPermission: () async {},
      getAPNSToken: () async => 'apns',
      getToken: () => Future<String?>.value(null),
      onTokenRefresh: () => tokenRefreshController.stream,
      channelTalkBoot: ({String? memberHash}) async => true,
      initPushToken: (token) async {
        pushTokens.add(token);
      },
      showChannelButton: () async {},
      recordNonFatal: (error, stack) async {},
      isIOS: false,
    );
    addTearDown(() async {
      await bootstrap.dispose();
      await tokenRefreshController.close();
    });

    await bootstrap.run();
    tokenRefreshController.add('refreshed-token');
    await Future<void>.delayed(Duration.zero);

    expect(pushTokens, ['refreshed-token']);
  });

  test('does not forward refreshed tokens when boot failed', () async {
    final tokenRefreshController = StreamController<String>.broadcast();
    final pushTokens = <String>[];

    final bootstrap = OptionalBootstrap(
      requestPermission: () async {},
      getAPNSToken: () async => 'apns',
      getToken: () => Future<String?>.value(null),
      onTokenRefresh: () => tokenRefreshController.stream,
      channelTalkBoot: ({String? memberHash}) async => false,
      initPushToken: (token) async {
        pushTokens.add(token);
      },
      showChannelButton: () async {},
      recordNonFatal: (error, stack) async {},
      isIOS: false,
    );
    addTearDown(() async {
      await bootstrap.dispose();
      await tokenRefreshController.close();
    });

    await bootstrap.run();
    tokenRefreshController.add('refreshed-token');
    await Future<void>.delayed(Duration.zero);

    expect(pushTokens, isEmpty);
  });

  test('registers a token that refreshed before channeltalk booted', () async {
    final tokenRefreshController = StreamController<String>.broadcast();
    final bootStarted = Completer<void>();
    final finishBoot = Completer<bool?>();
    final pushTokens = <String>[];

    final bootstrap = OptionalBootstrap(
      requestPermission: () async {},
      getAPNSToken: () async => 'apns',
      getToken: () async => null,
      onTokenRefresh: () => tokenRefreshController.stream,
      channelTalkBoot: ({String? memberHash}) {
        bootStarted.complete();
        return finishBoot.future;
      },
      initPushToken: (token) async {
        pushTokens.add(token);
      },
      showChannelButton: () async {},
      recordNonFatal: (error, stack) async {},
      isIOS: false,
    );
    addTearDown(() async {
      if (!finishBoot.isCompleted) finishBoot.complete(false);
      await bootstrap.dispose();
      await tokenRefreshController.close();
    });

    final runFuture = bootstrap.run();
    await bootStarted.future;
    tokenRefreshController.add('refreshed-before-boot');
    await Future<void>.delayed(Duration.zero);
    finishBoot.complete(true);
    await runFuture;

    expect(pushTokens, ['refreshed-before-boot']);
  });

  test('does not register the same token twice', () async {
    final tokenRefreshController = StreamController<String>.broadcast();
    var registrationCalls = 0;

    final bootstrap = OptionalBootstrap(
      requestPermission: () async {},
      getAPNSToken: () async => 'apns',
      getToken: () async => null,
      onTokenRefresh: () => tokenRefreshController.stream,
      channelTalkBoot: ({String? memberHash}) async => true,
      initPushToken: (token) async {
        registrationCalls += 1;
      },
      showChannelButton: () async {},
      recordNonFatal: (error, stack) async {},
      isIOS: false,
    );
    addTearDown(() async {
      await bootstrap.dispose();
      await tokenRefreshController.close();
    });

    await bootstrap.run();
    tokenRefreshController.add('same-token');
    tokenRefreshController.add('same-token');
    await Future<void>.delayed(const Duration(milliseconds: 1));

    expect(registrationCalls, 1);
  });

  test('serializes overlapping push token registrations', () async {
    final tokenRefreshController = StreamController<String>.broadcast();
    final firstStarted = Completer<void>();
    final secondStarted = Completer<void>();
    final finishFirst = Completer<void>();
    final finishSecond = Completer<void>();
    var activeRegistrations = 0;
    var maxActiveRegistrations = 0;

    final bootstrap = OptionalBootstrap(
      requestPermission: () async {},
      getAPNSToken: () async => 'apns',
      getToken: () async => null,
      onTokenRefresh: () => tokenRefreshController.stream,
      channelTalkBoot: ({String? memberHash}) async => true,
      initPushToken: (token) async {
        activeRegistrations += 1;
        if (activeRegistrations > maxActiveRegistrations) {
          maxActiveRegistrations = activeRegistrations;
        }
        if (token == 'first') {
          firstStarted.complete();
          await finishFirst.future;
        } else {
          secondStarted.complete();
          await finishSecond.future;
        }
        activeRegistrations -= 1;
      },
      showChannelButton: () async {},
      recordNonFatal: (error, stack) async {},
      isIOS: false,
    );
    addTearDown(() async {
      if (!finishFirst.isCompleted) finishFirst.complete();
      if (!finishSecond.isCompleted) finishSecond.complete();
      await bootstrap.dispose();
      await tokenRefreshController.close();
    });

    await bootstrap.run();
    tokenRefreshController.add('first');
    await firstStarted.future;
    tokenRefreshController.add('second');
    await Future<void>.delayed(Duration.zero);

    expect(maxActiveRegistrations, 1);

    finishFirst.complete();
    await secondStarted.future;
    finishSecond.complete();
  });

  test('hides the channel button when the stored preference is off', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'showsChannelTalkButton': false,
    });
    var showChannelButtonCalls = 0;
    var hideChannelButtonCalls = 0;

    final bootstrap = OptionalBootstrap(
      requestPermission: () async {},
      getAPNSToken: () async => 'apns',
      getToken: () async => null,
      onTokenRefresh: () => const Stream<String>.empty(),
      channelTalkBoot: ({String? memberHash}) async => true,
      initPushToken: (token) async {},
      showChannelButton: () async {
        showChannelButtonCalls += 1;
      },
      hideChannelButton: () async {
        hideChannelButtonCalls += 1;
      },
      recordNonFatal: (error, stack) async {},
      isIOS: false,
    );
    addTearDown(bootstrap.dispose);

    await bootstrap.run();

    expect(showChannelButtonCalls, 0);
    expect(hideChannelButtonCalls, 1);
  });

  test('shows the channel button when the stored preference is on', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'showsChannelTalkButton': true,
    });
    var showChannelButtonCalls = 0;
    var hideChannelButtonCalls = 0;

    final bootstrap = OptionalBootstrap(
      requestPermission: () async {},
      getAPNSToken: () async => 'apns',
      getToken: () async => null,
      onTokenRefresh: () => const Stream<String>.empty(),
      channelTalkBoot: ({String? memberHash}) async => true,
      initPushToken: (token) async {},
      showChannelButton: () async {
        showChannelButtonCalls += 1;
      },
      hideChannelButton: () async {
        hideChannelButtonCalls += 1;
      },
      recordNonFatal: (error, stack) async {},
      isIOS: false,
    );
    addTearDown(bootstrap.dispose);

    await bootstrap.run();

    expect(showChannelButtonCalls, 1);
    expect(hideChannelButtonCalls, 0);
  });

  test(
    'never completes with error when refreshed token registration throws',
    () async {
      final tokenRefreshController = StreamController<String>.broadcast();
      final recordedErrors = <Object>[];
      final escapedErrors = <Object>[];
      late OptionalBootstrap bootstrap;

      final zoneFuture = runZonedGuarded<Future<void>>(
        () async {
          bootstrap = OptionalBootstrap(
            requestPermission: () async {},
            getAPNSToken: () async => 'apns',
            getToken: () => Future<String?>.value(null),
            onTokenRefresh: () => tokenRefreshController.stream,
            channelTalkBoot: ({String? memberHash}) async => true,
            initPushToken: (token) async {
              throw StateError('refreshed token registration failed');
            },
            showChannelButton: () async {},
            recordNonFatal: (error, stack) async {
              recordedErrors.add(error);
            },
            isIOS: false,
          );

          await bootstrap.run();
          tokenRefreshController.add('refreshed-token');
          await Future<void>.delayed(Duration.zero);
        },
        (error, stack) {
          escapedErrors.add(error);
        },
      );
      await zoneFuture;
      await bootstrap.dispose();
      await tokenRefreshController.close();

      expect(escapedErrors, isEmpty);
      expect(recordedErrors, hasLength(1));
    },
  );

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
        onTokenRefresh: () => const Stream<String>.empty(),
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
