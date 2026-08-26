import 'dart:io';

import 'package:flutter/foundation.dart';

import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

/// Invokes the Google Play inline-install half sheet
/// (https://developer.android.com/distribute/marketing-tools/inline-installs)
/// for a target package, falling back to the plain Play Store listing when
/// the overlay is unavailable (non-Android platforms, old Play versions,
/// or channel errors).
class InlineInstallService {
  InlineInstallService({
    MethodChannel? channel,
    bool Function()? platformIsAndroid,
    Future<void> Function(Uri uri)? launchFallback,
  }) : _channel = channel ?? const MethodChannel('org.sparcs.otlplus'),
       _platformIsAndroid = platformIsAndroid ?? (() => Platform.isAndroid),
       _launchFallback = launchFallback ?? _defaultLaunchFallback;

  final MethodChannel _channel;
  final bool Function() _platformIsAndroid;
  final Future<void> Function(Uri uri) _launchFallback;

  static const String _playStoreListingUrl =
      'https://play.google.com/store/apps/details?id=';

  /// Launches the Play inline-install overlay for [packageName].
  ///
  /// Returns true when the overlay intent resolved and launched. Returns
  /// false (after opening the regular Play Store listing) whenever the
  /// overlay path is unavailable.
  ///
  /// [referrer] is an optional install-referrer tracking string; [listing]
  /// optionally targets a custom Play store listing.
  Future<bool> startInlineInstall(
    String packageName, {
    String? referrer,
    String? listing,
  }) async {
    if (packageName.trim().isEmpty) {
      throw ArgumentError.value(
        packageName,
        'packageName',
        'must not be empty',
      );
    }

    if (!_platformIsAndroid()) {
      await _openStoreListing(packageName);
      return false;
    }

    try {
      final overlayLaunched = await _channel.invokeMethod<bool>(
        'startInlineInstall',
        <String, dynamic>{
          'packageName': packageName,
          'referrer': referrer,
          'listing': listing,
        },
      );
      if (overlayLaunched == true) {
        return true;
      }
    } on PlatformException catch (error) {
      debugPrint('Inline install overlay failed: $error');
    } on MissingPluginException {
      debugPrint('Inline install channel unavailable');
    }

    await _openStoreListing(packageName);
    return false;
  }

  Future<void> _openStoreListing(String packageName) async {
    await _launchFallback(Uri.parse('$_playStoreListingUrl$packageName'));
  }

  static Future<void> _defaultLaunchFallback(Uri uri) async {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
