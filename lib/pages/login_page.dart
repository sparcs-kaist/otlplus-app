import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:otlplus/constants/color.dart';
import 'package:otlplus/constants/url.dart';
import 'package:otlplus/providers/auth_model.dart';
import 'package:otlplus/services/storage_service.dart';
import 'package:otlplus/utils/navigator.dart';
import 'package:otlplus/widgets/otl_dialog.dart';
import 'package:otlplus/widgets/otl_scaffold.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:webview_flutter/webview_flutter.dart';

class LoginPage extends StatefulWidget {
  static String route = 'login_page';

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  late final WebViewController _controller;
  bool _isLoadingPage = true;
  bool _isDisposed = false;
  final String _loginUrl =
      Uri.https(BASE_AUTHORITY, 'session/login/').toString();
  final String _redirectScheme = "org.sparcs.otl";
  final String _redirectHost = "login";

  @override
  void initState() {
    super.initState();

    try {
      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setUserAgent("otl-app")
        ..setNavigationDelegate(
          NavigationDelegate(
            onProgress: (int progress) {
              // Update loading bar progress (optional)
            },
            onPageStarted: (String url) {
              if (!_isDisposed && mounted) {
                setState(() {
                  _isLoadingPage = true;
                });
              }
            },
            onPageFinished: (String url) {
              if (!_isDisposed && mounted) {
                setState(() {
                  _isLoadingPage = false;
                });
              }
            },
            onWebResourceError: (WebResourceError error) {
              // Keep error print for actual errors
              print('WebView Error: ${error.description}');
              if (!_isDisposed && mounted) {
                setState(() {
                  _isLoadingPage = false; // Stop loading on error
                });
                // Show error message to user if needed
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(
                          'login.webviewError'.tr() + ' (${error.errorCode})')),
                );
              }
            },
            onNavigationRequest: (NavigationRequest request) {
              final uri = Uri.parse(request.url);

              // Check if the URL is the custom redirect scheme
              if (uri.scheme == _redirectScheme && uri.host == _redirectHost) {
                // Handle the token extraction
                _handleTokenRedirect(uri);
                // Prevent the WebView from navigating to this pseudo-URL
                return NavigationDecision.prevent;
              }
              // Allow navigation for all other URLs
              return NavigationDecision.navigate;
            },
          ),
        )
        ..loadRequest(Uri.parse(_loginUrl)); // Load initial login URL
    } catch (e) {
      print('Error initializing WebViewController: $e');
      // Handle initialization error gracefully
      if (mounted) {
        setState(() {
          _isLoadingPage = false;
        });
      }
    }

    WidgetsBinding.instance.addPostFrameCallback(
      (_) async {
        if (!((await SharedPreferences.getInstance()).getBool('hasAccount') ??
            true)) {
          OTLNavigator.pushDialog(
            context: context,
            builder: (_) => OTLDialog(
              type: OTLDialogType.accountDeleted,
              onTapNeg: () => SystemNavigator.pop(),
            ),
          );
        }
      },
    );
  }

  Future<void> _handleTokenRedirect(Uri uri) async {
    if (_isDisposed || !mounted) return;
    
    final accessToken = uri.queryParameters['accessToken'];
    final refreshToken = uri.queryParameters['refreshToken'];

    if (accessToken != null && refreshToken != null) {
      // print('Tokens received from WebView redirect. Saving...'); // Remove print
      final storageService =
          Provider.of<StorageService>(context, listen: false);
      final authModel = Provider.of<AuthModel>(context, listen: false);

      try {
        await storageService.saveTokens(
            accessToken: accessToken, refreshToken: refreshToken);
        // Update AuthModel state - this should trigger navigation in main.dart
        if (!_isDisposed && mounted) {
          authModel.setLoggedIn(true);
        }
        // print("Tokens saved and login state updated."); // Remove print
      } catch (e) {
        // Keep error print for actual errors
        print("Error saving tokens: $e");
        if (!_isDisposed && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('login.tokenSaveError'.tr())),
          );
        }
      }
    } else {
      // print('Missing tokens in redirect URL.'); // Remove print
      if (!_isDisposed && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('login.tokenMissingError'.tr())),
        );
      }
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return OTLScaffold(
      child: Stack(
        children: [
          if (!_isDisposed)
            WebViewWidget(controller: _controller),
          if (_isLoadingPage && !_isDisposed)
            const Center(
              child: CircularProgressIndicator(color: OTLColor.pinksMain),
            ),
        ],
      ),
    );
  }
}
