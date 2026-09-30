import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:otlplus/constants/color.dart';

enum OTLNavigatorTransition { rightLeft, downUp, immediate }

class _NavigationEntry {
  _NavigationEntry(this.route, this.transition);

  final Route<dynamic> route;
  final OTLNavigatorTransition? transition;
}

class OTLNavigator {
  static final List<_NavigationEntry> _history = [];

  static Future<T?> _push<T>(
    NavigatorState navigator,
    Route<T> route,
    OTLNavigatorTransition? transition,
  ) {
    final entry = _NavigationEntry(route, transition);
    _history.add(entry);
    return navigator.push(route).then((result) {
      _history.remove(entry);
      return result;
    });
  }

  // Only entries at or below this layout's own route may supply its buttons.
  // Covered routes can rebuild (for example when the locale changes).
  static Iterable<_NavigationEntry> _entriesFor(BuildContext context) {
    final route = ModalRoute.of(context);
    if (route == null || route.isFirst) return const [];
    final index = _history.indexWhere((entry) => entry.route == route);
    if (index < 0) return const [];
    return _history
        .take(index + 1)
        .where(
          (entry) =>
              entry.route.isActive && entry.route.navigator == route.navigator,
        );
  }

  static bool canPopRightLeftOf(BuildContext context) => _entriesFor(
    context,
  ).any((entry) => entry.transition == OTLNavigatorTransition.rightLeft);

  static bool canPopDownUpOf(BuildContext context) => _entriesFor(context).any(
    (entry) =>
        entry.transition == OTLNavigatorTransition.downUp ||
        entry.transition == OTLNavigatorTransition.immediate,
  );

  static Future<T?> push<T extends Object?>(
    BuildContext context,
    Widget page, {
    OTLNavigatorTransition transition = OTLNavigatorTransition.rightLeft,
  }) => _push(
    Navigator.of(context),
    _buildRoute<T>(context, page, transition),
    transition,
  );

  static Route<T> _buildRoute<T extends Object?>(
    BuildContext context,
    Widget page,
    OTLNavigatorTransition transition,
  ) {
    // Use native horizontal transitions for iOS pages so interactive edge-back
    // works for both detail pages and settings. Root replacements stay instant.
    if (Theme.of(context).platform == TargetPlatform.iOS &&
        transition != OTLNavigatorTransition.immediate) {
      return CupertinoPageRoute<T>(builder: (_) => page);
    }
    return switch (transition) {
      OTLNavigatorTransition.rightLeft => buildRightLeftPageRoute<T>(page),
      OTLNavigatorTransition.downUp => buildDownUpPageRoute<T>(page),
      OTLNavigatorTransition.immediate => buildImmediatePageRoute<T>(page),
    };
  }

  static Future<T?> pushRoot<T extends Object?>(
    BuildContext context,
    Widget page, {
    OTLNavigatorTransition transition = OTLNavigatorTransition.immediate,
  }) {
    final navigator = Navigator.of(context);
    _history.removeWhere((entry) => entry.route.navigator == navigator);
    return navigator.pushAndRemoveUntil(
      _buildRoute<T>(context, page, transition),
      (route) => false,
    );
  }

  static void pop<T extends Object?>(
    BuildContext context, {
    OTLNavigatorTransition? until,
    T? result,
  }) {
    final navigator = Navigator.of(context);
    final entries = _entriesFor(context).toList();
    if (entries.isEmpty || !navigator.canPop()) return;
    if (until == null) {
      navigator.pop(result);
      return;
    }
    final targets = entries.where(
      (entry) => until == OTLNavigatorTransition.rightLeft
          ? entry.transition == OTLNavigatorTransition.rightLeft
          : entry.transition == OTLNavigatorTransition.downUp ||
                entry.transition == OTLNavigatorTransition.immediate,
    );
    if (targets.isEmpty) return;
    final target = targets.last.route;
    navigator.popUntil((route) => route == target || route.isFirst);
    // Never pop the root if the target has already been removed.
    if (target.isCurrent && !target.isFirst && navigator.canPop()) {
      navigator.pop(result);
    }
  }

  static bool get canPop => _history.any((entry) => entry.route.isActive);
  static bool get canPopRightLeft => _history.any(
    (entry) =>
        entry.route.isActive &&
        entry.transition == OTLNavigatorTransition.rightLeft,
  );
  static bool get canPopDownUp => _history.any(
    (entry) =>
        entry.route.isActive &&
        (entry.transition == OTLNavigatorTransition.downUp ||
            entry.transition == OTLNavigatorTransition.immediate),
  );

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
    final navigator = Navigator.of(context, rootNavigator: useRootNavigator);
    return _push(
      navigator,
      DialogRoute<T>(
        context: context,
        builder: builder,
        themes: InheritedTheme.capture(from: context, to: navigator.context),
        barrierDismissible: barrierDismissible,
        barrierColor: barrierColor,
        barrierLabel: barrierLabel,
        useSafeArea: useSafeArea,
        settings: routeSettings,
        anchorPoint: anchorPoint,
        traversalEdgeBehavior: traversalEdgeBehavior,
      ),
      null,
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
