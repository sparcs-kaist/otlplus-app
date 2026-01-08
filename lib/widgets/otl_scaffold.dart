import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:otlplus/constants/color.dart';
import 'package:otlplus/utils/navigator.dart';
import 'package:otlplus/widgets/responsive_button.dart';

class OTLScaffold extends StatelessWidget {
  // final Widget body;
  // final Widget? leading;
  // final Widget? middle;
  // final Widget? trailing;
  // final Widget? bottomNavigationBar;
  // final Function()? onBack;
  // final Color sheetBackgroundColor;
  // final bool resizeToAvoidBottomInset;
  // final bool disableBackButton;

  OTLScaffold({
    Key? key,
    required this.child,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.floatingActionButtonAnimator,
    this.persistentFooterButtons,
    this.persistentFooterAlignment = AlignmentDirectional.centerEnd,
    this.drawer,
    this.onDrawerChanged,
    this.endDrawer,
    this.onEndDrawerChanged,
    this.bottomNavigationBar,
    this.bottomSheet,
    this.backgroundColor = OTLColor.pinksLight,
    this.resizeToAvoidBottomInset = false,
    this.primary = true,
    this.drawerDragStartBehavior = DragStartBehavior.start,
    this.extendBody = false,
    this.drawerScrimColor,
    this.drawerEdgeDragWidth,
    this.drawerEnableOpenDragGesture = true,
    this.endDrawerEnableOpenDragGesture = true,
    this.restorationId,
  }) : super(key: key) {
    if (backgroundColor != null && backgroundColor!.computeLuminance() < 0.5)
      SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
    else
      SystemChrome.setSystemUIOverlayStyle(
        SystemUiOverlayStyle.dark.copyWith(
          systemNavigationBarColor: OTLColor.grayF,
          statusBarColor: Colors.transparent,
        ),
      );
  }
  final Widget child;
  final bool extendBody;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final FloatingActionButtonAnimator? floatingActionButtonAnimator;
  final List<Widget>? persistentFooterButtons;
  final AlignmentDirectional persistentFooterAlignment;
  final Widget? drawer;
  final DrawerCallback? onDrawerChanged;
  final Widget? endDrawer;
  final DrawerCallback? onEndDrawerChanged;
  final Color? drawerScrimColor;
  final Color? backgroundColor;
  final Widget? bottomNavigationBar;
  final Widget? bottomSheet;
  final bool? resizeToAvoidBottomInset;
  final bool primary;
  final DragStartBehavior drawerDragStartBehavior;
  final double? drawerEdgeDragWidth;
  final bool drawerEnableOpenDragGesture;
  final bool endDrawerEnableOpenDragGesture;
  final String? restorationId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(5.0),
        child: SafeArea(
          top: true,
          bottom: false,
          left: false,
          right: false,
          child: SizedBox(
            height: 5,
            child: ColoredBox(color: OTLColor.pinksMain),
          ),
        ),
      ),
      body: child,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      floatingActionButtonAnimator: floatingActionButtonAnimator,
      persistentFooterButtons: persistentFooterButtons,
      persistentFooterAlignment: persistentFooterAlignment,
      drawer: drawer,
      onDrawerChanged: onDrawerChanged,
      endDrawer: endDrawer,
      onEndDrawerChanged: onEndDrawerChanged,
      bottomNavigationBar: bottomNavigationBar,
      bottomSheet: bottomSheet,
      backgroundColor: backgroundColor,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      primary: primary,
      drawerDragStartBehavior: drawerDragStartBehavior,
      extendBody: extendBody,
      drawerScrimColor: drawerScrimColor,
      drawerEdgeDragWidth: drawerEdgeDragWidth,
      drawerEnableOpenDragGesture: drawerEnableOpenDragGesture,
      endDrawerEnableOpenDragGesture: endDrawerEnableOpenDragGesture,
      restorationId: restorationId,
    );
  }
}

class OTLLayout extends StatefulWidget {
  const OTLLayout({
    Key? key,
    this.middle,
    this.leading,
    this.trailing,
    this.extendBodyBehindAppBar = false,
    required this.body,
  }) : super(key: key);
  final Widget? middle;
  final Widget? leading;
  final Widget? trailing;
  final bool extendBodyBehindAppBar;
  final Widget body;

  @override
  State<OTLLayout> createState() => _OTLLayoutState();
}

class _OTLLayoutState extends State<OTLLayout> {
  final bool canPopRightLeft = OTLNavigator.canPopRightLeft;
  final bool canPopDownUp = OTLNavigator.canPopDownUp;

  @override
  Widget build(BuildContext context) {
    final ScaffoldState? scaffold = Scaffold.maybeOf(context);
    final bool hasDrawer = scaffold?.hasDrawer ?? false;
    final bool hasEndDrawer = scaffold?.hasEndDrawer ?? false;

    return Stack(
      fit: StackFit.expand,
      alignment: Alignment.topCenter,
      children: [
        Positioned.fill(
          top: widget.extendBodyBehindAppBar ? 0 : kToolbarHeight,
          child: widget.body,
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SizedBox(
            height: kToolbarHeight,
            child: NavigationToolbar(
              leading: (widget.leading != null || canPopRightLeft || hasDrawer)
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (canPopRightLeft)
                          IconTextButton(
                            icon: Icons.navigate_before,
                            onTap: () => OTLNavigator.pop(
                              context,
                              until: OTLNavigatorTransition.rightLeft,
                            ),
                            padding: EdgeInsets.all(16),
                          ),
                        if (hasDrawer)
                          IconTextButton(
                            icon: Icons.menu,
                            onTap: () => Scaffold.of(context).openDrawer(),
                            padding: EdgeInsets.all(16),
                          ),
                        if (widget.leading != null) widget.leading!,
                      ],
                    )
                  : null,
              middle: widget.middle,
              trailing:
                  (widget.trailing != null || canPopDownUp || hasEndDrawer)
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.trailing != null) widget.trailing!,
                        if (hasEndDrawer)
                          IconTextButton(
                            icon: Icons.menu,
                            onTap: () => Scaffold.of(context).openEndDrawer(),
                            padding: EdgeInsets.all(16),
                          ),
                        if (canPopDownUp)
                          IconTextButton(
                            icon: Icons.close,
                            onTap: () => OTLNavigator.pop(
                              context,
                              until: OTLNavigatorTransition.downUp,
                            ),
                            padding: EdgeInsets.all(16),
                          ),
                      ],
                    )
                  : null,
              middleSpacing: 0,
            ),
          ),
        ),
      ],
    );
  }
}
