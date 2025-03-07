import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:otlplus/utils/navigator.dart';
import 'package:otlplus/widgets/otl_dialog.dart';
import 'package:otlplus/widgets/otl_scaffold.dart';
import 'package:provider/provider.dart';
import 'package:otlplus/providers/auth_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_flutter/webview_flutter.dart';

class LoginPage extends StatefulWidget {
  static String route = 'login_page';

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _isVisible = true;
  late final WebViewController controller;

  @override
  void initState() {
    super.initState();

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

    const AUTHORITY = 'otl.sparcs.org';
    Map<String, dynamic> query = {'next': 'https://otl.sparcs.org/'};
    if (Platform.isIOS) {
      query['social_login'] = '0';
    }

    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (url) {
          if (Uri.parse(url).authority == AUTHORITY) {
            setState(() {
              _isVisible = false;
            });
          }
        },
        onPageFinished: (url) async {
          String authority = Uri.parse(url).authority;
          if (authority == AUTHORITY) {
            try {
              context.read<AuthModel>().authenticate('https://$AUTHORITY');
            } catch (e) {
              setState(() {
                _isVisible = true;
              });
              await controller.loadRequest(Uri.https(AUTHORITY, '/session/login/', query));
            }
          } else if (authority == 'sparcssso.kaist.ac.kr') {
            setState(() {
              _isVisible = true;
            });
          } else {
            setState(() {
              _isVisible = true;
            });
          }
        },
        onNavigationRequest: (NavigationRequest request) {
          return NavigationDecision.navigate;
        },
      ))
      ..loadRequest(Uri.https(AUTHORITY, '/session/login/', query));
  }

  @override
  Widget build(BuildContext context) {
    return OTLScaffold(
      child: Material(
        child: Stack(
          children: <Widget>[
            Center(
              child: const CircularProgressIndicator(),
            ),
            _buildBody(context),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    return Visibility(
      maintainSize: true,
      maintainAnimation: true,
      maintainState: true,
      visible: _isVisible,
      child: WebViewWidget(controller: controller),
    );
  }
}
