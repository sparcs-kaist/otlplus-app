import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otlplus/constants/url.dart';
import 'package:otlplus/models/custom_block.dart';
import 'package:otlplus/repositories/custom_block_repository.dart';
import '../utils/fake_http.dart';

void main() {
  const block = CustomBlock(
    id: 10,
    name: 'Study',
    place: 'Library',
    day: 6,
    begin: 0,
    end: 1440,
  );
  test('v4 snake-case and minute bounds round trip', () {
    expect(CustomBlock.fromJson(block.toJson()).toJson(), block.toJson());
    expect(
      () => CustomBlock.fromJson({...block.toJson(), 'day': 7}),
      throwsFormatException,
    );
    expect(
      () => CustomBlock.fromJson({...block.toJson(), 'end': 0}),
      throwsFormatException,
    );
  });
  test('v4 list create patch delete use the dedicated endpoint', () async {
    final adapter = FakeHttpAdapter();
    final dio = Dio(BaseOptions(baseUrl: 'http://test/'))
      ..httpClientAdapter = adapter;
    final requests = <RequestOptions>[];
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (request, handler) {
          requests.add(request);
          handler.next(request);
        },
      ),
    );
    final repository = CustomBlockRepository(dio);
    final path = '/$API_V2_TIMETABLES_URL/7/custom-blocks';
    adapter.register('GET', path, {
      'custom_blocks': [block.toJson()],
    });
    adapter.register('POST', path, {'id': 10});
    adapter.register('PATCH', '$path/10', block.toJson());
    adapter.register('DELETE', '$path/10', {'id': 10});
    expect((await repository.fetch(7)).single.name, 'Study');
    expect(await repository.create(7, block), 10);
    await repository.update(7, block);
    await repository.delete(7, 10);
    expect(requests.map((r) => r.method), ['GET', 'POST', 'PATCH', 'DELETE']);
    expect(requests[1].data, {
      'block_name': 'Study',
      'place': 'Library',
      'day': 6,
      'begin': 0,
      'end': 1440,
    });
    expect(requests[2].data, requests[1].data);
    await expectLater(repository.create(-1, block), throwsArgumentError);
    await expectLater(
      repository.create(
        7,
        const CustomBlock(name: '', day: 0, begin: 60, end: 30),
      ),
      throwsArgumentError,
    );
    expect(requests.length, 4);
  });
}
