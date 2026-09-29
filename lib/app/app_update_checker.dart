import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/material.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class AppUpdateChecker {
  AppUpdateChecker(this._scaffoldMessengerKey);

  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey;

  static const _minimumIosVersionKey = 'minimum_ios_version';
  static const _minimumAndroidVersionKey = 'minimum_android_version';
  static const _iosStoreUrl = 'https://apps.apple.com/app/otl/id1579878255';
  static const _androidStoreUrl =
      'https://play.google.com/store/apps/details?id=org.sparcs.otlplus';

  /// Uses an activated cached value when fetching fails. A device with no
  /// cached value falls back to 0.0.0 so an outage cannot lock out new users.
  Future<bool> isMinimumVersionRequired() async {
    if (!Platform.isIOS && !Platform.isAndroid) return false;

    try {
      final remoteConfig = FirebaseRemoteConfig.instance;
      await remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 5),
          minimumFetchInterval: const Duration(hours: 1),
        ),
      );
      await remoteConfig.setDefaults(const {
        _minimumIosVersionKey: '0.0.0',
        _minimumAndroidVersionKey: '0.0.0',
      });

      try {
        await remoteConfig.fetchAndActivate();
      } catch (error) {
        debugPrint('Remote Config fetch error: $error');
      }

      final packageInfo = await PackageInfo.fromPlatform();
      final key = Platform.isIOS
          ? _minimumIosVersionKey
          : _minimumAndroidVersionKey;
      return isVersionBelowMinimum(
        packageInfo.version,
        remoteConfig.getString(key),
      );
    } catch (error) {
      debugPrint('Minimum app version check error: $error');
      return false;
    }
  }

  @visibleForTesting
  static bool isVersionBelowMinimum(String current, String minimum) {
    final currentParts = _parseVersion(current);
    final minimumParts = _parseVersion(minimum);
    if (currentParts == null || minimumParts == null) return false;

    final length = currentParts.length > minimumParts.length
        ? currentParts.length
        : minimumParts.length;
    for (var index = 0; index < length; index += 1) {
      final currentPart = index < currentParts.length ? currentParts[index] : 0;
      final minimumPart = index < minimumParts.length ? minimumParts[index] : 0;
      if (currentPart != minimumPart) return currentPart < minimumPart;
    }
    return false;
  }

  static List<int>? _parseVersion(String version) {
    final normalized = version.trim();
    if (normalized.isEmpty) return null;

    final parts = normalized.split('.');
    final parsed = <int>[];
    for (final part in parts) {
      final value = int.tryParse(part);
      if (value == null || value < 0) return null;
      parsed.add(value);
    }
    return parsed;
  }

  Future<bool> openStore() async {
    if (!Platform.isIOS && !Platform.isAndroid) return false;
    final uri = Uri.parse(Platform.isIOS ? _iosStoreUrl : _androidStoreUrl);
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> checkForAndroidInAppUpdate() async {
    if (!Platform.isAndroid) return;

    try {
      final info = await InAppUpdate.checkForUpdate();
      if (info.updateAvailability == UpdateAvailability.updateAvailable) {
        if (info.immediateUpdateAllowed && info.updatePriority >= 4) {
          final result = await InAppUpdate.performImmediateUpdate();
          if (result == AppUpdateResult.userDeniedUpdate) {
            exit(0);
          }
        } else if (info.flexibleUpdateAllowed) {
          await InAppUpdate.startFlexibleUpdate();
          _showUpdateSnackbar();
        }
      } else if (info.updateAvailability ==
          UpdateAvailability.developerTriggeredUpdateInProgress) {
        await InAppUpdate.performImmediateUpdate();
      }
    } catch (error) {
      debugPrint('In-app update error: $error');
    }
  }

  void _showUpdateSnackbar() {
    _scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text("popup.inapp_flexible_download_complete".tr()),
        duration: const Duration(days: 1),
        action: SnackBarAction(
          label: "popup.inapp_flexible_restart".tr(),
          onPressed: () async {
            await InAppUpdate.completeFlexibleUpdate();
          },
        ),
      ),
    );
  }
}
