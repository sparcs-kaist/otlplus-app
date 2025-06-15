import 'dart:io';
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
  bool _isWebViewInitialized = false;
  final String _loginUrl =
      Uri.https(BASE_AUTHORITY, 'session/login/').toString();
  final String _redirectScheme = "org.sparcs.otl";
  final String _redirectHost = "login";
  
  final GlobalKey _webViewKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _initializeWebView();
    
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

  void _initializeWebView() async {
    if (_isWebViewInitialized) return;

    try {
      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setUserAgent("otl-app")
        ..setNavigationDelegate(
          NavigationDelegate(
            onProgress: (int progress) {
            },
            onPageStarted: (String url) {
              if (!_isDisposed && mounted) {
                setState(() {
                  _isLoadingPage = true;
                });
              }
            },
            onPageFinished: (String url) async {
              if (!_isDisposed && mounted) {
                setState(() {
                  _isLoadingPage = false;
                });
              }
            },
            onWebResourceError: (WebResourceError error) {
              print('WebView Error: ${error.description}');
              if (!_isDisposed && mounted) {
                setState(() {
                  _isLoadingPage = false;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(
                          'login.webviewError'.tr() + ' (${error.errorCode})')),
                );
              }
            },
            onNavigationRequest: (NavigationRequest request) {
              final uri = Uri.parse(request.url);
              print(uri);

              if (uri.scheme == _redirectScheme && uri.host == _redirectHost) {
                _handleTokenRedirect(uri);
                return NavigationDecision.prevent;
              }
              return NavigationDecision.navigate;
            },
          ),
        )
        ..loadRequest(Uri.parse(_loginUrl));

      if (mounted) {
        setState(() {
          _isWebViewInitialized = true;
        });
      }
    } catch (e) {
      print('Error initializing WebViewController: $e');
      
      if (mounted) {
        setState(() {
          _isLoadingPage = false;
          _isWebViewInitialized = true;
        });
      }
    }
  }

  Future<void> _handleTokenRedirect(Uri uri) async {
    if (_isDisposed || !mounted) return;
    
    final accessToken = uri.queryParameters['accessToken'];
    final refreshToken = uri.queryParameters['refreshToken'];

    if (accessToken != null && refreshToken != null) {
      final storageService =
          Provider.of<StorageService>(context, listen: false);
      final authModel = Provider.of<AuthModel>(context, listen: false);

      try {
        await storageService.saveTokens(
            accessToken: accessToken, refreshToken: refreshToken);
        if (!_isDisposed && mounted) {
          authModel.setLoggedIn(true);
        }
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
          if (_isWebViewInitialized && !_isDisposed)
            WebViewWidget(
              key: _webViewKey,
              controller: _controller,
            ),
          if (_isLoadingPage && !_isDisposed)
            const Center(
              child: CircularProgressIndicator(color: OTLColor.pinksMain),
            ),
        ],
      ),
    );
  }
}
