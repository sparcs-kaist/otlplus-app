import 'dart:async';

import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otlplus/models/lecture.dart';
import 'package:otlplus/models/semester.dart';
import 'package:otlplus/pages/lecture_search_page.dart';
import 'package:otlplus/providers/lecture_search_model.dart';
import 'package:otlplus/providers/timetable_model.dart';
import 'package:otlplus/repositories/department_repository.dart';
import 'package:otlplus/repositories/lecture_repository.dart';
import 'package:otlplus/repositories/timetable_repository.dart';
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
    final scenario = await _pumpLectureSearchPage(tester);

    await tester.tap(find.byType(FilledButton).last);
    expect(scenario.callOrder, ['setTempLecture:null', 'lectureSearch']);
    scenario.searchModel.searchCompleter.complete(true);
    await tester.pumpAndSettle();

    expect(scenario.navigatorObserver.popCount, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('search completing after disposal does not pop or throw', (
    tester,
  ) async {
    final scenario = await _pumpLectureSearchPage(tester);

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
      final scenario = await _pumpLectureSearchPage(tester);

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
    final scenario = await _pumpLectureSearchPage(tester);
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

Future<_LectureSearchScenario> _pumpLectureSearchPage(
  WidgetTester tester,
) async {
  final callOrder = <String>[];
  final searchModel = _FakeLectureSearchModel(callOrder);
  final timetableModel = _FakeTimetableModel(callOrder);
  final navigatorObserver = _RecordingNavigatorObserver();
  final appKey = GlobalKey<_LectureSearchAppHarnessState>();
  addTearDown(searchModel.dispose);
  addTearDown(timetableModel.dispose);
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
        ChangeNotifierProvider<LectureSearchModel>.value(value: searchModel),
        ChangeNotifierProvider<TimetableModel>.value(value: timetableModel),
      ],
      child: EasyLocalization(
        supportedLocales: const [Locale('ko')],
        path: 'assets/translations',
        child: MaterialApp(
          navigatorObservers: [navigatorObserver],
          home: _LectureSearchAppHarness(key: appKey),
        ),
      ),
    ),
  );
  await tester.pump();

  appKey.currentState!.openSearchPage();
  await tester.pumpAndSettle();

  return _LectureSearchScenario(
    searchModel: searchModel,
    navigatorObserver: navigatorObserver,
    appKey: appKey,
    callOrder: callOrder,
  );
}

class _LectureSearchScenario {
  const _LectureSearchScenario({
    required this.searchModel,
    required this.navigatorObserver,
    required this.appKey,
    required this.callOrder,
  });

  final _FakeLectureSearchModel searchModel;
  final _RecordingNavigatorObserver navigatorObserver;
  final GlobalKey<_LectureSearchAppHarnessState> appKey;
  final List<String> callOrder;
}

class _FakeLectureSearchModel extends LectureSearchModel {
  _FakeLectureSearchModel(this.callOrder)
    : super(LectureRepository(Dio()), DepartmentRepository(Dio()));

  final List<String> callOrder;
  final Completer<bool> searchCompleter = Completer<bool>();

  @override
  Future<bool> lectureSearch(Semester semester) {
    callOrder.add('lectureSearch');
    return searchCompleter.future;
  }
}

class _FakeTimetableModel extends TimetableModel {
  _FakeTimetableModel(this.callOrder)
    : super(repository: TimetableRepository(Dio()), forTest: true);

  final List<String> callOrder;

  @override
  void setTempLecture(Lecture? lecture) {
    callOrder.add('setTempLecture:${lecture == null ? 'null' : 'lecture'}');
  }
}

class _RecordingNavigatorObserver extends NavigatorObserver {
  int popCount = 0;

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    popCount++;
    super.didPop(route, previousRoute);
  }
}

class _LectureSearchAppHarness extends StatefulWidget {
  const _LectureSearchAppHarness({super.key});

  @override
  State<_LectureSearchAppHarness> createState() =>
      _LectureSearchAppHarnessState();
}

class _LectureSearchAppHarnessState extends State<_LectureSearchAppHarness> {
  final pageKey = GlobalKey<_LectureSearchPageHarnessState>();
  bool _searchPageOpen = false;
  bool get searchPageOpen => _searchPageOpen;

  void openSearchPage() {
    _searchPageOpen = true;
    unawaited(
      OTLNavigator.push<void>(
        context,
        _LectureSearchPageHarness(key: pageKey),
        transition: OTLNavigatorTransition.immediate,
      ).whenComplete(() => _searchPageOpen = false),
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

class _LectureSearchPageHarness extends StatefulWidget {
  const _LectureSearchPageHarness({super.key});

  @override
  State<_LectureSearchPageHarness> createState() =>
      _LectureSearchPageHarnessState();
}

class _LectureSearchPageHarnessState extends State<_LectureSearchPageHarness> {
  bool _showSearchPage = true;

  void hideSearchPage() {
    setState(() => _showSearchPage = false);
  }

  @override
  Widget build(BuildContext context) {
    return _showSearchPage
        ? const LectureSearchPage(openKeyboard: false)
        : const SizedBox.shrink();
  }
}
