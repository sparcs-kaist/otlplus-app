import 'package:flutter/material.dart';
import 'package:otlplus/constants/color.dart';

enum OTLNavigatorTransition { rightLeft, downUp, immediate }

enum _TransitionHistory { rightLeft, downUp, immediate, dialog }

class OTLNavigator {
  static List<Route> _rightleftTransitionHistory = [];
  static List<Route> _downupTransitionHistory = [];
  static List<_TransitionHistory> _history = [];

  static void _removeLastHistory() {
    if (_history.isEmpty) return;

    switch (_history.removeLast()) {
      case _TransitionHistory.rightLeft:
        if (_rightleftTransitionHistory.isNotEmpty) {
          _rightleftTransitionHistory.removeLast();
        }
        break;
      case _TransitionHistory.downUp:
      case _TransitionHistory.immediate:
        if (_downupTransitionHistory.isNotEmpty) {
          _downupTransitionHistory.removeLast();
        }
        break;
      case _TransitionHistory.dialog:
        break;
    }
  }

  static void _removeLastUntil(
    bool Function(_TransitionHistory mode) predicate,
  ) {
    while (_history.isNotEmpty && !predicate(_history.last)) {
      _removeLastHistory();
    }
    if (_history.isNotEmpty) _removeLastHistory();
  }

  static Future<T?> push<T extends Object?>(
    BuildContext context,
    Widget page, {
    OTLNavigatorTransition transition = OTLNavigatorTransition.rightLeft,
  }) {
    Route<T> _route;
    switch (transition) {
      case OTLNavigatorTransition.rightLeft:
        _route = buildRightLeftPageRoute<T>(page);
        _rightleftTransitionHistory.add(_route);
        _history.add(_TransitionHistory.rightLeft);
        break;
      case OTLNavigatorTransition.downUp:
        _route = buildDownUpPageRoute<T>(page);
        _downupTransitionHistory.add(_route);
        _history.add(_TransitionHistory.downUp);
        break;
      case OTLNavigatorTransition.immediate:
        _route = buildImmediatePageRoute<T>(page);
        _downupTransitionHistory.add(_route);
        _history.add(_TransitionHistory.immediate);
        break;
    }
    return Navigator.of(context).push(_route);
  }

  static Future<T?> pushRoot<T extends Object?>(
    BuildContext context,
    Widget page, {
    OTLNavigatorTransition transition = OTLNavigatorTransition.immediate,
  }) {
    _rightleftTransitionHistory.clear();
    _downupTransitionHistory.clear();
    _history.clear();
    Route<T> _route;
    switch (transition) {
      case OTLNavigatorTransition.rightLeft:
        _route = buildRightLeftPageRoute<T>(page);
        break;
      case OTLNavigatorTransition.downUp:
        _route = buildDownUpPageRoute<T>(page);
        break;
      case OTLNavigatorTransition.immediate:
        _route = buildImmediatePageRoute<T>(page);
        break;
    }
    return Navigator.of(
      context,
    ).pushAndRemoveUntil(_route, (Route<dynamic> route) => false);
  }

  static void pop<T extends Object?>(
    BuildContext context, {
    OTLNavigatorTransition? until,
    T? result,
  }) {
    if (_history.isEmpty) return;

    NavigatorState navigator = Navigator.of(context);
    if (until == null) {
      _removeLastHistory();
      return navigator.pop(result);
    } else if (until == OTLNavigatorTransition.rightLeft) {
      if (_rightleftTransitionHistory.isEmpty) return;
      navigator.popUntil(
        (Route<dynamic> route) =>
            (_rightleftTransitionHistory.isNotEmpty &&
                _rightleftTransitionHistory.last == route) ||
            route.isFirst,
      );
      _removeLastUntil((mode) => mode == _TransitionHistory.rightLeft);
      return navigator.pop(result);
    } else {
      if (_downupTransitionHistory.isEmpty) return;
      navigator.popUntil(
        (Route<dynamic> route) =>
            (_downupTransitionHistory.isNotEmpty &&
                _downupTransitionHistory.last == route) ||
            route.isFirst,
      );
      _removeLastUntil(
        (mode) =>
            (mode == _TransitionHistory.downUp ||
            mode == _TransitionHistory.immediate),
      );
      return navigator.pop(result);
    }
  }

  static bool get canPop => _history.isNotEmpty;

  static bool get canPopRightLeft => _rightleftTransitionHistory.isNotEmpty;
  static bool get canPopDownUp => _downupTransitionHistory.isNotEmpty;

  static Future<T?> pushDialog<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    bool barrierDismissible = true,
    Color? barrierColor = OTLColor.barrier,
    String? barrierLabel,
    bool useSafeArea = false,
    bool useRootNavigator = true,
    RouteSettings? routeSettings,
    Offset? anchorPoint,
    TraversalEdgeBehavior? traversalEdgeBehavior,
  }) {
    _history.add(_TransitionHistory.dialog);
    return showDialog(
      context: context,
      builder: builder,
      barrierDismissible: barrierDismissible,
      barrierColor: barrierColor,
      barrierLabel: barrierLabel,
      useSafeArea: useSafeArea,
      useRootNavigator: useRootNavigator,
      routeSettings: routeSettings,
      anchorPoint: anchorPoint,
      traversalEdgeBehavior: traversalEdgeBehavior,
    );
  }
}

Route<T> buildRightLeftPageRoute<T extends Object?>(Widget page) {
  return PageRouteBuilder(
    pageBuilder: (_, animation, __) => page,
    transitionsBuilder: (_, animation, __, child) {
      const begin = Offset(1.0, 0.0);
      const end = Offset.zero;
      final curveTween = CurveTween(curve: Curves.ease);
      final tween = Tween(begin: begin, end: end).chain(curveTween);
      final offsetAnimation = animation.drive(tween);

      return SlideTransition(position: offsetAnimation, child: child);
    },
  );
}

Route<T> buildDownUpPageRoute<T extends Object?>(Widget page) {
  return PageRouteBuilder(
    pageBuilder: (_, animation, __) => page,
    transitionsBuilder: (_, animation, __, child) {
      const begin = Offset(0.0, 1.0);
      const end = Offset.zero;
      final curveTween = CurveTween(curve: Curves.ease);
      final tween = Tween(begin: begin, end: end).chain(curveTween);
      final offsetAnimation = animation.drive(tween);

      return SlideTransition(
        position: offsetAnimation,
        child: SafeArea(
          top: animation.value != 1,
          right: false,
          left: false,
          bottom: false,
          child: Align(alignment: Alignment.bottomCenter, child: child),
        ),
      );
    },
  );
}

Route<T> buildImmediatePageRoute<T extends Object?>(Widget page) {
  return PageRouteBuilder(
    pageBuilder: (_, animation, __) => page,
    transitionDuration: Duration.zero,
    reverseTransitionDuration: Duration.zero,
  );
}
