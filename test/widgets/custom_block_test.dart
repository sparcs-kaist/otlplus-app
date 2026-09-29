import 'dart:async';
import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otlplus/models/custom_block.dart';
import 'package:otlplus/providers/timetable_model.dart';
import 'package:otlplus/repositories/custom_block_repository.dart';
import 'package:otlplus/repositories/timetable_repository.dart';
import 'package:otlplus/widgets/custom_block_dialog.dart';
import 'package:otlplus/widgets/custom_block_tile.dart';
import 'package:otlplus/widgets/timetable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/extensions.dart';

class MemoryBlocks extends CustomBlockRepository {
  MemoryBlocks() : super(Dio());
  bool fails = false;
  int writes = 0;
  Completer<void>? gate;
  @override
  Future<int> create(int timetableId, CustomBlock block) async {
    await gate?.future;
    if (fails) throw StateError('offline');
    return ++writes;
  }

  @override
  Future<CustomBlock> update(int timetableId, CustomBlock block) async {
    if (fails) throw StateError('offline');
    writes++;
    return block;
  }

  @override
  Future<void> delete(int timetableId, int blockId) async {
    if (fails) throw StateError('offline');
    writes++;
  }
}

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });
  late MemoryBlocks repository;
  late TimetableModel model;
  setUp(() {
    repository = MemoryBlocks();
    model = TimetableModel(
      repository: TimetableRepository(Dio(), customBlocks: repository),
      forTest: true,
    )..setIndex(1);
  });
  tearDown(() => model.dispose());

  Future<void> open(WidgetTester tester, {CustomBlock? block}) async {
    await tester.pumpWidget(
      Builder(
        builder: (context) => TextButton(
          onPressed: () => showCustomBlockEditor(context, model, block: block),
          child: const Text('Open'),
        ),
      ).scaffold,
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
  }

  testWidgets('creates edits and confirms deletion of a block', (tester) async {
    await open(tester);
    await tester.enterText(find.byType(TextFormField).at(0), 'Study');
    await tester.enterText(find.byType(TextFormField).at(1), 'Library');
    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();
    expect(find.byType(CustomBlockDialog), findsNothing);
    final block = model.currentTimetable.customBlocks.single;
    expect(block.name, 'Study');
    expect(block.begin, 540);
    await open(tester, block: block);
    await tester.enterText(find.byType(TextFormField).at(0), 'Updated');
    await tester.enterText(find.byType(TextFormField).at(2), '23:00');
    await tester.enterText(find.byType(TextFormField).at(3), '24:00');
    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();
    expect(model.currentTimetable.customBlocks.single.end, 1440);
    await open(tester, block: model.currentTimetable.customBlocks.single);
    await tester.tap(find.text('삭제'));
    await tester.pumpAndSettle();
    expect(model.currentTimetable.customBlocks, hasLength(1));
    await tester.tap(find.text('삭제').last);
    await tester.pumpAndSettle();
    expect(model.currentTimetable.customBlocks, isEmpty);
  });

  testWidgets('validates empty name invalid time and overlaps before writing', (
    tester,
  ) async {
    await model.saveCustomBlock(
      1,
      const CustomBlock(name: 'Existing', day: 0, begin: 540, end: 600),
    );
    final writes = repository.writes;
    await open(tester);
    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();
    expect(find.text('일정 이름을 입력해 주세요.'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).at(0), 'Study');
    await tester.enterText(find.byType(TextFormField).at(3), '08:00');
    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();
    expect(repository.writes, writes);
    await tester.enterText(find.byType(TextFormField).at(3), '10:00');
    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();
    expect(find.text('다른 커스텀 블록과 시간이 겹칩니다.'), findsOneWidget);
    expect(repository.writes, writes);
  });

  testWidgets('failure retains input and retry succeeds', (tester) async {
    repository.fails = true;
    await open(tester);
    await tester.enterText(find.byType(TextFormField).at(0), 'Retry me');
    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();
    expect(find.text('작업을 완료하지 못했습니다. 다시 시도해 주세요.'), findsOneWidget);
    expect(find.text('Retry me'), findsOneWidget);
    expect(model.currentTimetable.customBlocks, isEmpty);
    repository.fails = false;
    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();
    expect(model.currentTimetable.customBlocks.single.name, 'Retry me');
  });

  test('read-only and stale timetable targets cannot mutate', () async {
    const block = CustomBlock(name: 'No', day: 0, begin: 0, end: 60);
    expect(await model.saveCustomBlock(2, block), isFalse);
    model.setIndex(0);
    expect(await model.saveCustomBlock(-1, block), isFalse);
    expect(await model.deleteCustomBlock(-1, 1), isFalse);
    expect(repository.writes, 0);
  });

  test('in-flight custom block stays with its original timetable', () async {
    repository.gate = Completer<void>();
    final save = model.saveCustomBlock(
      1,
      const CustomBlock(name: 'Original', day: 0, begin: 540, end: 600),
    );
    model.setIndex(0);
    repository.gate!.complete();
    expect(await save, isTrue);
    expect(model.currentTimetable.customBlocks, isEmpty);
    expect(model.timetables[1].customBlocks.single.name, 'Original');
    expect(model.customBlocksBusy, isFalse);
  });

  testWidgets('early Sunday block expands grid and is absent from exam mode', (
    tester,
  ) async {
    const blocks = [
      CustomBlock(id: 3, name: 'Sunday', day: 6, begin: 60, end: 120),
    ];
    Widget grid(bool exam) => SingleChildScrollView(
      child: Timetable(
        lectures: [],
        customBlocks: blocks,
        isExamTime: exam,
        builder: (_, __, ___) => throw StateError('no lectures'),
      ),
    ).scaffold;
    await tester.pumpWidget(grid(false));
    expect(find.byType(CustomBlockTile), findsOneWidget);
    expect(find.text('timetable.days.sun'.tr()), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(grid(true));
    expect(find.byType(CustomBlockTile), findsNothing);
  });
}
