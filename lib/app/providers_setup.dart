import 'dart:async';

import 'package:flutter/material.dart';
import 'package:otlplus/dio_provider.dart';
import 'package:otlplus/providers/auth_model.dart';
import 'package:otlplus/providers/course_detail_model.dart';
import 'package:otlplus/providers/course_search_model.dart';
import 'package:otlplus/providers/hall_of_fame_model.dart';
import 'package:otlplus/providers/info_model.dart';
import 'package:otlplus/providers/latest_reviews_model.dart';
import 'package:otlplus/providers/lecture_detail_model.dart';
import 'package:otlplus/providers/lecture_search_model.dart';
import 'package:otlplus/providers/liked_review_model.dart';
import 'package:otlplus/providers/settings_model.dart';
import 'package:otlplus/providers/timetable_model.dart';
import 'package:otlplus/repositories/review_repository.dart';
import 'package:otlplus/services/sentry_consent_gate.dart';
import 'package:otlplus/services/storage_service.dart';
import 'package:otlplus/services/telemetry_coordinator.dart';
import 'package:otlplus/widgets/telemetry_synchronizer.dart';
import 'package:provider/provider.dart';

Widget buildAppProviders({
  required Widget child,
  required TelemetryCoordinator telemetryCoordinator,
  required SentryConsentGate sentryConsentGate,
}) {
  return MultiProvider(
    providers: [
      Provider(create: (_) => StorageService()),
      Provider(create: (_) => ReviewRepository(DioProvider().dio)),
      ChangeNotifierProvider(
        create: (context) => AuthModel(
          context.read<StorageService>(),
          telemetry: telemetryCoordinator,
        ),
      ),
      ChangeNotifierProxyProvider<AuthModel, InfoModel>(
        create: (context) => InfoModel(telemetry: telemetryCoordinator),
        update: (context, authModel, infoModel) {
          final model = infoModel ?? InfoModel(telemetry: telemetryCoordinator);
          if (authModel.isLogined) {
            // Failures set InfoModel.hasError for retry UI; session
            // expiry is handled by the Dio interceptor.
            unawaited(model.getInfo());
          } else {
            model.clearData();
          }
          return model;
        },
      ),
      ChangeNotifierProxyProvider<InfoModel, TimetableModel>(
        create: (context) => TimetableModel(),
        update: (context, infoModel, timetableModel) {
          final model = timetableModel ?? TimetableModel();
          if (infoModel.hasData) {
            model.loadSemesters(
              user: infoModel.user,
              semesters: infoModel.semesters,
            );
          }
          return model;
        },
      ),
      ChangeNotifierProvider(create: (_) => LectureSearchModel()),
      ChangeNotifierProvider(create: (_) => CourseSearchModel()),
      ChangeNotifierProvider(
        create: (context) =>
            LatestReviewsModel(context.read<ReviewRepository>()),
      ),
      ChangeNotifierProvider(
        create: (context) => LikedReviewModel(context.read<ReviewRepository>()),
      ),
      ChangeNotifierProvider(
        create: (context) => HallOfFameModel(context.read<ReviewRepository>()),
      ),
      ChangeNotifierProvider(create: (_) => CourseDetailModel()),
      ChangeNotifierProvider(create: (_) => LectureDetailModel()),
      ChangeNotifierProvider(
        create: (_) => SettingsModel(
          telemetry: telemetryCoordinator,
          onCrashReportingChanged: (enabled) {
            unawaited(sentryConsentGate.setEnabled(enabled));
          },
        ),
      ),
    ],
    child: TelemetrySynchronizer(telemetry: telemetryCoordinator, child: child),
  );
}
