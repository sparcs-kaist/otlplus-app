import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationPermissionService {
  static Future<bool> checkAndRequestPermission() async {
    final PermissionStatus status = await Permission.notification.status;
    debugPrint('status : ${status}');

    if (status.isGranted) {
      await _savePermissionStatus(true);
      return true;
    } else if (status.isDenied) {
      await _savePermissionStatus(false);
      return false;
    } else if (status.isPermanentlyDenied) {
      await _savePermissionStatus(false);
      return false;
    } else {
      final PermissionStatus requestStatus =
          await Permission.notification.request();
      if (requestStatus.isGranted) {
        await _savePermissionStatus(true);
        return true;
      } else {
        await _savePermissionStatus(false);
        return false;
      }
    }
  }

  static Future<void> _savePermissionStatus(bool isGranted) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('notification_permission', isGranted);
  }

  static Future<bool> getPermissionStatus() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('notification_permission') ?? false;
  }
}
