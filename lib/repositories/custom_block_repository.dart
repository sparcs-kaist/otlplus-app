import 'package:dio/dio.dart';
import 'package:otlplus/constants/url.dart';
import 'package:otlplus/models/custom_block.dart';

class CustomBlockRepository {
  CustomBlockRepository(this._dio);
  final Dio _dio;

  String _path(int timetableId) {
    if (timetableId <= 0) throw ArgumentError.value(timetableId, 'timetableId');
    return '$API_V2_TIMETABLES_URL/$timetableId/custom-blocks';
  }

  Future<List<CustomBlock>> fetch(int timetableId) async {
    final response = await _dio.get<Map<String, dynamic>>(_path(timetableId));
    return (response.data!['custom_blocks'] as List<dynamic>)
        .map((json) => CustomBlock.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<int> create(int timetableId, CustomBlock block) async {
    if (!block.isValid) throw ArgumentError('Invalid custom block');
    final response = await _dio.post<Map<String, dynamic>>(
      _path(timetableId),
      data: block.toPayload(),
    );
    return response.data!['id'] as int;
  }

  Future<CustomBlock> update(int timetableId, CustomBlock block) async {
    if (!block.isValid || block.id <= 0)
      throw ArgumentError('Invalid custom block');
    final response = await _dio.patch<Map<String, dynamic>>(
      '${_path(timetableId)}/${block.id}',
      data: block.toPayload(),
    );
    return CustomBlock.fromJson(response.data!);
  }

  Future<void> delete(int timetableId, int blockId) async {
    if (blockId <= 0) throw ArgumentError.value(blockId, 'blockId');
    await _dio.delete<Map<String, dynamic>>('${_path(timetableId)}/$blockId');
  }
}
