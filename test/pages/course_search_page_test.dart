import 'dart:async';

import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otlplus/pages/course_search_page.dart';
import 'package:otlplus/providers/course_search_model.dart';
import 'package:otlplus/repositories/course_repository.dart';
import 'package:otlplus/repositories/department_repository.dart';
import 'package:otlplus/utils/navigator.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    WidgetsFlutterBinding.ensureInitialized();
    await EasyLocalization.ensureInitialized();
  });

  testWidgets('pops with result when search succeeds while mounted', (
    tester,
  ) async {
    final scenario = await _pumpCourseSearchPage(tester);

    await tester.tap(find.byType(FilledButton).last);
    scenario.searchModel.searchCompleter.complete(true);
    await tester.pumpAndSettle();

    expect(scenario.navigatorObserver.popCount, 1);
    expect(scenario.appKey.currentState!.searchResult, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('search completing after disposal does not pop or throw', (
    tester,
  ) async {
    final scenario = await _pumpCourseSearchPage(tester);

    await tester.tap(find.byType(FilledButton).last);
    scenario.appKey.currentState!.pageKey.currentState!.hideSearchPage();
    await tester.pump();
    scenario.searchModel.searchCompleter.complete(true);
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(scenario.navigatorObserver.popCount, 0);

    scenario.appKey.currentState!.closeSearchPage();
    await tester.pumpAndSettle();
  });

  testWidgets(
    'search failure after disposal does not touch disposed focus node',
    (tester) async {
      final scenario = await _pumpCourseSearchPage(tester);

      await tester.tap(find.byType(TextField));
      await tester.pump();
      await tester.tap(find.byType(FilledButton).last);
      scenario.appKey.currentState!.pageKey.currentState!.hideSearchPage();
      await tester.pump();
      scenario.searchModel.searchCompleter.complete(false);
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(scenario.navigatorObserver.popCount, 0);

      scenario.appKey.currentState!.closeSearchPage();
      await tester.pumpAndSettle();
    },
  );

  testWidgets('search failure while mounted refocuses the field', (
    tester,
  ) async {
    final scenario = await _pumpCourseSearchPage(tester);
    final focusNode = tester
        .widget<TextField>(find.byType(TextField))
        .focusNode!;

    expect(focusNode.hasFocus, isFalse);
    await tester.tap(find.byType(FilledButton).last);
    scenario.searchModel.searchCompleter.complete(false);
    await tester.pump();

    expect(focusNode.hasFocus, isTrue);
    expect(tester.takeException(), isNull);

    scenario.appKey.currentState!.closeSearchPage();
    await tester.pumpAndSettle();
  });
}

Future<_CourseSearchScenario> _pumpCourseSearchPage(WidgetTester tester) async {
  final searchModel = _FakeCourseSearchModel();
  final navigatorObserver = _RecordingNavigatorObserver();
  final appKey = GlobalKey<_CourseSearchAppHarnessState>();
  addTearDown(searchModel.dispose);
  addTearDown(() async {
    final appState = appKey.currentState;
    if (appState != null && appState.searchPageOpen) {
      appState.closeSearchPage();
      await tester.pumpAndSettle();
    }
  });

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<CourseSearchModel>.value(value: searchModel),
      ],
      child: EasyLocalization(
        supportedLocales: const [Locale('ko')],
        path: 'assets/translations',
        child: MaterialApp(
          navigatorObservers: [navigatorObserver],
          home: _CourseSearchAppHarness(key: appKey),
        ),
      ),
    ),
  );
  await tester.pump();

  appKey.currentState!.openSearchPage();
  await tester.pumpAndSettle();

  return _CourseSearchScenario(
    searchModel: searchModel,
    navigatorObserver: navigatorObserver,
    appKey: appKey,
  );
}

class _CourseSearchScenario {
  const _CourseSearchScenario({
    required this.searchModel,
    required this.navigatorObserver,
    required this.appKey,
  });

  final _FakeCourseSearchModel searchModel;
  final _RecordingNavigatorObserver navigatorObserver;
  final GlobalKey<_CourseSearchAppHarnessState> appKey;
}

class _FakeCourseSearchModel extends CourseSearchModel {
  _FakeCourseSearchModel()
    : super(CourseRepository(Dio()), DepartmentRepository(Dio()));

  final Completer<bool> searchCompleter = Completer<bool>();

  @override
  Future<bool> courseSearch({String order = 'DEF'}) => searchCompleter.future;
}

class _RecordingNavigatorObserver extends NavigatorObserver {
  int popCount = 0;

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    popCount++;
    super.didPop(route, previousRoute);
  }
}

class _CourseSearchAppHarness extends StatefulWidget {
  const _CourseSearchAppHarness({super.key});

  @override
  State<_CourseSearchAppHarness> createState() =>
      _CourseSearchAppHarnessState();
}

class _CourseSearchAppHarnessState extends State<_CourseSearchAppHarness> {
  final pageKey = GlobalKey<_CourseSearchPageHarnessState>();
  bool _searchPageOpen = false;
  bool get searchPageOpen => _searchPageOpen;
  bool? searchResult;

  void openSearchPage() {
    _searchPageOpen = true;
    unawaited(
      OTLNavigator.push<bool>(
        context,
        _CourseSearchPageHarness(key: pageKey),
        transition: OTLNavigatorTransition.immediate,
      ).then((result) {
        _searchPageOpen = false;
        searchResult = result;
      }),
    );
  }

  void closeSearchPage() {
    OTLNavigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: SizedBox.shrink());
  }
}

class _CourseSearchPageHarness extends StatefulWidget {
  const _CourseSearchPageHarness({super.key});

  @override
  State<_CourseSearchPageHarness> createState() =>
      _CourseSearchPageHarnessState();
}

class _CourseSearchPageHarnessState extends State<_CourseSearchPageHarness> {
  bool _showSearchPage = true;

  void hideSearchPage() {
    setState(() => _showSearchPage = false);
  }

  @override
  Widget build(BuildContext context) {
    return _showSearchPage
        ? const CourseSearchPage(openKeyboard: false)
        : const SizedBox.shrink();
  }
}
