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
    _appUpdateChecker.checkForUpdate();
  }

  @override
  void dispose() {
    _deepLinkHandler.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return MaterialApp(
        scaffoldMessengerKey: _scaffoldMessengerKey,
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

    final authModel = context.watch<AuthModel>();
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
      home:
          widget.homeOverride ??
          (authModel.isLogined ? const OTLHome() : LoginPage()),
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
