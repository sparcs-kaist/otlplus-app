import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:otlplus/models/review.dart';
import 'package:otlplus/repositories/review_repository.dart';

class LikedReviewModel extends ChangeNotifier {
  LikedReviewModel(this._repository);

  static const int _pageSize = 10;

  final ReviewRepository _repository;
  final List<Review> _allLikedReviews = <Review>[];
  final List<Review> _likedReviews = <Review>[];

  bool _isLoading = false;
  bool _hasMore = true;
  Object? _error;
  int? _loadedUserId;
  int? _activeUserId;
  int _requestGeneration = 0;

  List<Review> get likedReviews => List<Review>.unmodifiable(_likedReviews);
  bool get isLoading => _isLoading;
  bool get hasMore => _hasMore;
  Object? get error => _error;

  Future<void> load(int userId) async {
    if (!_isLoading && _loadedUserId == userId) return;
    if (_isLoading && _activeUserId == userId) return;
    await refresh(userId);
  }

  Future<void> refresh(int userId) async {
    final requestGeneration = ++_requestGeneration;
    _activeUserId = userId;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final reviews = await _repository.fetchLiked(userId);
      if (requestGeneration != _requestGeneration) return;

      _loadedUserId = userId;
      _allLikedReviews
        ..clear()
        ..addAll(reviews);
      _likedReviews
        ..clear()
        ..addAll(_allLikedReviews.take(_pageSize));
      _hasMore = _likedReviews.length < _allLikedReviews.length;
    } catch (error) {
      if (requestGeneration == _requestGeneration) {
        _error = error;
      }
    } finally {
      if (requestGeneration == _requestGeneration) {
        _activeUserId = null;
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> loadMore() async {
    if (_isLoading || !_hasMore) return;

    final end = math.min(
      _likedReviews.length + _pageSize,
      _allLikedReviews.length,
    );
    _likedReviews.addAll(_allLikedReviews.getRange(_likedReviews.length, end));
    _hasMore = end < _allLikedReviews.length;
    notifyListeners();
  }
}
