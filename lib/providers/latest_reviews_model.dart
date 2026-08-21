import 'package:flutter/foundation.dart';
import 'package:otlplus/models/review.dart';
import 'package:otlplus/repositories/review_repository.dart';

class LatestReviewsModel extends ChangeNotifier {
  LatestReviewsModel(this._repository);

  static const int _pageSize = 10;

  final ReviewRepository _repository;
  final List<Review> _latestReviews = <Review>[];

  bool _isLoading = false;
  bool _hasMore = true;
  bool _hasLoaded = false;
  Object? _error;

  List<Review> get latestReviews => List<Review>.unmodifiable(_latestReviews);
  bool get isLoading => _isLoading;
  bool get hasMore => _hasMore;
  Object? get error => _error;

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
      final result = await _repository.fetchRecent(
        offset: reset ? 0 : _latestReviews.length,
        limit: _pageSize,
      );
      if (reset) _latestReviews.clear();
      _latestReviews.addAll(result.reviews);
      _hasLoaded = true;
      _hasMore = _latestReviews.length < result.totalCount;
    } catch (error) {
      _error = error;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
