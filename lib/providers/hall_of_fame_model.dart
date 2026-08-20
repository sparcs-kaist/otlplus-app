import 'package:flutter/foundation.dart';
import 'package:otlplus/constants/enums.dart';
import 'package:otlplus/models/review.dart';
import 'package:otlplus/models/semester.dart';
import 'package:otlplus/repositories/review_repository.dart';

class HallOfFameModel extends ChangeNotifier {
  HallOfFameModel(this._repository);

  static const int _pageSize = 10;

  final ReviewRepository _repository;
  final List<Review> _hallOfFame = <Review>[];

  bool _isLoading = false;
  bool _hasMore = true;
  bool _hasLoaded = false;
  Object? _error;
  Semester? _semester;
  ReviewTab _selectedMode = ReviewTab.hallOfFame;

  List<Review> get hallOfFame => List<Review>.unmodifiable(_hallOfFame);
  bool get isLoading => _isLoading;
  bool get hasMore => _hasMore;
  Object? get error => _error;
  Semester? get semester => _semester;
  ReviewTab get selectedMode => _selectedMode;

  void setSemester(Semester? semester) {
    if (semester != null && (semester.semester < 1 || semester.semester > 4)) {
      throw ArgumentError.value(
        semester.semester,
        'semester',
        'must be between 1 and 4',
      );
    }
    if (_semester == semester) return;
    _semester = semester;
    notifyListeners();
  }

  void setMode(ReviewTab mode) {
    if (_selectedMode == mode) return;
    _selectedMode = mode;
    notifyListeners();
  }

  Future<void> load() async {
    if (_hasLoaded || _isLoading) return;
    await _fetch(reset: true);
  }

  Future<void> refresh() => _fetch(reset: true);

  Future<void> loadMore() async {
    if (_isLoading || !_hasMore) return;
    await _fetch(reset: false);
  }

  Future<void> _fetch({required bool reset}) async {
    if (_isLoading) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _repository.fetchHallOfFame(
        year: _semester?.year,
        semester: _semester?.semester,
        offset: reset ? 0 : _hallOfFame.length,
        limit: _pageSize,
      );
      if (reset) _hallOfFame.clear();
      _hallOfFame.addAll(result.reviews);
      _hasLoaded = true;
      _hasMore = _hallOfFame.length < result.totalCount;
    } catch (error) {
      _error = error;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
