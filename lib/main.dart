import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:otlplus/app/app_bootstrap.dart';
import 'package:otlplus/app/app_theme.dart';
import 'package:otlplus/app/app_update_checker.dart';
import 'package:otlplus/app/deep_link_handler.dart';
import 'package:otlplus/home.dart';
import 'package:otlplus/pages/course_detail_page.dart';
import 'package:otlplus/pages/lecture_detail_page.dart';
import 'package:otlplus/pages/liked_review_page.dart';
import 'package:otlplus/pages/login_page.dart';
import 'package:otlplus/pages/my_review_page.dart';
import 'package:otlplus/providers/auth_model.dart';
import 'package:otlplus/services/storage_service.dart';
import 'package:provider/provider.dart';

void main() {
  bootstrapApp(() => OTLApp());
}

class OTLApp extends StatefulWidget {
  OTLApp({
    super.key,
    @visibleForTesting this.uriLinkStreamOverride,
    @visibleForTesting this.storageServiceOverride,
    @visibleForTesting this.initializeAppOverride,
    @visibleForTesting this.recordNonFatalOverride,
    @visibleForTesting this.homeOverride,
  });

  final Stream<Uri>? uriLinkStreamOverride;
  final StorageService? storageServiceOverride;
  final Future<void> Function()? initializeAppOverride;
  final Future<void> Function(Object error, StackTrace stack)?
  recordNonFatalOverride;
  final Widget? homeOverride;

  @override
  _OTLAppState createState() => _OTLAppState();
}

class _OTLAppState extends State<OTLApp> {
  late final AppUpdateChecker _appUpdateChecker;
  late final DeepLinkHandler _deepLinkHandler;
  late final StorageService _storageService;
  bool _isLoading = true;
  bool _isCheckingMinimumVersion = true;
  bool _isMinimumVersionRequired = false;
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  @override
  void initState() {
    super.initState();
    _storageService = widget.storageServiceOverride ?? StorageService();
    _appUpdateChecker = AppUpdateChecker(_scaffoldMessengerKey);
    _deepLinkHandler = DeepLinkHandler(
      storageService: _storageService,
      authModel: () => Provider.of<AuthModel>(context, listen: false),
      isMounted: () => mounted,
      isLoading: () => _isLoading,
      onLoaded: () => setState(() => _isLoading = false),
      telemetryCoordinator: telemetryCoordinator,
      uriLinkStreamOverride: widget.uriLinkStreamOverride,
      recordNonFatalOverride: widget.recordNonFatalOverride,
    );
    if (widget.initializeAppOverride case final initializeApp?) {
      initializeApp();
    } else {
      initializeAppSession(
        authModel: Provider.of<AuthModel>(context, listen: false),
        storageService: _storageService,
        isMounted: () => mounted,
        onLoaded: () => setState(() => _isLoading = false),
      );
    }
    _deepLinkHandler.initialize();
    _checkAppVersion();
  }

  Future<void> _checkAppVersion() async {
    final isRequired = await _appUpdateChecker.isMinimumVersionRequired();
    if (!mounted) return;

    setState(() {
      _isMinimumVersionRequired = isRequired;
      _isCheckingMinimumVersion = false;
    });
    if (!isRequired) {
      unawaited(_appUpdateChecker.checkForAndroidInAppUpdate());
    }
  }

  @override
  void dispose() {
    _deepLinkHandler.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authModel = context.watch<AuthModel>();
    final Widget home;
    if (_isLoading || _isCheckingMinimumVersion) {
      home = const Scaffold(body: Center(child: CircularProgressIndicator()));
    } else if (_isMinimumVersionRequired) {
      home = ForceUpdatePage(onUpdate: _appUpdateChecker.openStore);
    } else {
      home =
          widget.homeOverride ??
          (authModel.isLogined ? const OTLHome() : LoginPage());
    }

    return MaterialApp(
      scaffoldMessengerKey: _scaffoldMessengerKey,
      builder: (context, child) => ScrollConfiguration(
        behavior: NoEndOfScrollBehavior(),
        child: child ?? Container(),
      ),
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      title: "OTL",
      home: home,
      routes: {
        LikedReviewPage.route: (_) => LikedReviewPage(),
        MyReviewPage.route: (_) => MyReviewPage(),
        LectureDetailPage.route: (_) => LectureDetailPage(),
        CourseDetailPage.route: (_) => CourseDetailPage(),
        LoginPage.route: (_) => LoginPage(),
      },
      theme: buildAppTheme(),
    );
  }
}

class ForceUpdatePage extends StatefulWidget {
  const ForceUpdatePage({required this.onUpdate, super.key});

  final Future<bool> Function() onUpdate;

  @override
  State<ForceUpdatePage> createState() => _ForceUpdatePageState();
}

class _ForceUpdatePageState extends State<ForceUpdatePage> {
  bool _isOpeningStore = false;

  Future<void> _openStore() async {
    if (_isOpeningStore) return;
    setState(() => _isOpeningStore = true);

    var didOpen = false;
    try {
      didOpen = await widget.onUpdate();
    } catch (error) {
      debugPrint('Store launch error: $error');
    } finally {
      if (mounted) setState(() => _isOpeningStore = false);
    }
    if (!didOpen && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('update.store_open_failed'.tr())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.system_update, size: 64),
                  const SizedBox(height: 24),
                  Text(
                    'update.required_title'.tr(),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'update.required_description'.tr(),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isOpeningStore ? null : _openStore,
                      child: Text('update.open_store'.tr()),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
