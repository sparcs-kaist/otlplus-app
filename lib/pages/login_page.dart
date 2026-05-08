import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:otlplus/constants/url.dart';
import 'package:otlplus/providers/auth_model.dart';
import 'package:otlplus/services/storage_service.dart';
import 'package:otlplus/theme/context_ext.dart';
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
  final String _loginUrl = Uri.https(
    BASE_AUTHORITY,
    'session/login/',
  ).toString();
  final String _redirectScheme = "org.sparcs.otl";
  final String _redirectHost = "login";

  final GlobalKey _webViewKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _initializeWebView();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
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
    });
  }

  void _initializeWebView() async {
    if (_isWebViewInitialized) return;

    try {
      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setUserAgent("otl-app")
        ..setNavigationDelegate(
          NavigationDelegate(
            onProgress: (int progress) {},
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
                      'login.webviewError'.tr() + ' (${error.errorCode})',
                    ),
                  ),
                );
              }
            },
            onNavigationRequest: (NavigationRequest request) {
              final uri = Uri.parse(request.url);
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
      final storageService = Provider.of<StorageService>(
        context,
        listen: false,
      );
      final authModel = Provider.of<AuthModel>(context, listen: false);

      try {
        await storageService.saveTokens(
          accessToken: accessToken,
          refreshToken: refreshToken,
        );
        if (!_isDisposed && mounted) {
          authModel.setLoggedIn(true);
        }
      } catch (e) {
        // Keep error print for actual errors
        print("Error saving tokens: $e");
        if (!_isDisposed && mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('login.tokenSaveError'.tr())));
        }
      }
    } else {
      if (!_isDisposed && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('login.tokenMissingError'.tr())));
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
    final colors = context.colors;
    final texts = context.texts;

    return OTLScaffold(
      backgroundColor: colors.backgroundPageDefault,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colors.gradientSunset[0],
              colors.backgroundPageDefault,
              colors.gradientPeach[1],
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: colors.backgroundSectionTransparent,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: colors.lineDivider),
                  ),
                  child: Text(
                    'OTL+',
                    style: texts.smallBold.copyWith(
                      color: colors.highlightDark,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'OTL login',
                  style: texts.biggerBold.copyWith(color: colors.textDark),
                ),
                const SizedBox(height: 8),
                Text(
                  'Continue with the KAIST OTL account portal.',
                  style: texts.normal.copyWith(color: colors.textLight),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: colors.backgroundSectionDefault,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: colors.lineDivider),
                      boxShadow: [
                        BoxShadow(
                          color: colors.highlightDark.withValues(alpha: 0.08),
                          blurRadius: 32,
                          offset: const Offset(0, 20),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: Stack(
                        children: [
                          if (_isWebViewInitialized && !_isDisposed)
                            Positioned.fill(
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: colors.backgroundSectionDefault,
                                ),
                                child: WebViewWidget(
                                  key: _webViewKey,
                                  controller: _controller,
                                ),
                              ),
                            ),
                          if (_isLoadingPage && !_isDisposed)
                            Positioned.fill(
                              child: ColoredBox(
                                color: colors.backgroundSectionTransparent,
                                child: Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      CircularProgressIndicator(
                                        color: colors.highlightDefault,
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'Loading sign-in…',
                                        style: texts.normalMedium.copyWith(
                                          color: colors.textDefault,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
