import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:in_app_update/in_app_update.dart';

class AppUpdateChecker {
  AppUpdateChecker(this._scaffoldMessengerKey);

  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey;

  Future<void> checkForUpdate() async {
    if (Platform.isAndroid) {
      try {
        final info = await InAppUpdate.checkForUpdate();
        if (info.updateAvailability == UpdateAvailability.updateAvailable) {
          if (info.immediateUpdateAllowed && info.updatePriority >= 4) {
            final result = await InAppUpdate.performImmediateUpdate();
            if (result == AppUpdateResult.userDeniedUpdate) {
              exit(0);
            }
          } else if (info.flexibleUpdateAllowed) {
            await InAppUpdate.startFlexibleUpdate().then((_) {
              _showUpdateSnackbar();
            });
          }
        } else if (info.updateAvailability ==
            UpdateAvailability.developerTriggeredUpdateInProgress) {
          await InAppUpdate.performImmediateUpdate();
        }
      } catch (e) {
        debugPrint("In-app update error: $e");
      }
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
