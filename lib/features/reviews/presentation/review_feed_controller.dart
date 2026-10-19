import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_error_message.dart';
import '../../../core/errors/app_exception.dart';
import '../domain/review.dart';
import '../domain/review_feed_repository.dart';
import 'review_providers.dart';

typedef ReviewFeedSeed = ({
  String placeId,
  String scope,
  ReviewFilters filters,
});
final reviewFeedRepositoryProvider = Provider<ReviewFeedRepository?>((ref) {
  final repository = ref.watch(reviewRepositoryProvider);
  return repository is ReviewFeedRepository
      ? repository as ReviewFeedRepository
      : null;
});

class ReviewFeedState {
  const ReviewFeedState({
    required this.filters,
    this.summary = const AsyncLoading(),
    this.items = const [],
    this.loading = true,
    this.loadingMore = false,
    this.error,
    this.pageError,
    this.nextCursor,
    this.totalCount,
    this.isDemo = false,
  });
  final ReviewFilters filters;
  final AsyncValue<ReviewSummary> summary;
  final List<Review> items;
  final bool loading, loadingMore, isDemo;
  final String? error, pageError, nextCursor;
  final int? totalCount;
  ReviewFeedState copyWith({
    ReviewFilters? filters,
    AsyncValue<ReviewSummary>? summary,
    List<Review>? items,
    bool? loading,
    bool? loadingMore,
    bool? isDemo,
    String? error,
    bool clearError = false,
    String? pageError,
    bool clearPageError = false,
    String? nextCursor,
    bool clearCursor = false,
    int? totalCount,
  }) => ReviewFeedState(
    filters: filters ?? this.filters,
    summary: summary ?? this.summary,
    items: items ?? this.items,
    loading: loading ?? this.loading,
    loadingMore: loadingMore ?? this.loadingMore,
    isDemo: isDemo ?? this.isDemo,
    error: clearError ? null : error ?? this.error,
    pageError: clearPageError ? null : pageError ?? this.pageError,
    nextCursor: clearCursor ? null : nextCursor ?? this.nextCursor,
    totalCount: totalCount ?? this.totalCount,
  );
}

final reviewFeedControllerProvider = NotifierProvider.autoDispose
    .family<ReviewFeedController, ReviewFeedState, ReviewFeedSeed>(
      ReviewFeedController.new,
    );

class ReviewFeedController extends Notifier<ReviewFeedState> {
  ReviewFeedController(this.seed);
  final ReviewFeedSeed seed;
  ReviewFeedRepository? _repository;
  int _generation = 0, _summaryGeneration = 0;
  @override
  ReviewFeedState build() {
    _repository = ref.watch(reviewFeedRepositoryProvider);
    final generation = ++_generation;
    final reference = ref;
    ref.onDispose(() {
      _generation++;
      _summaryGeneration++;
    });
    scheduleMicrotask(() {
      if (reference.mounted && generation == _generation) {
        refreshSummary();
        _first(seed.filters, generation);
      }
    });
    return ReviewFeedState(filters: seed.filters);
  }

  ReviewFeedRepository get _source =>
      _repository ??
      (throw const AppException(
        'Nguồn dữ liệu hiện tại chưa hỗ trợ danh sách đánh giá phân trang.',
      ));

  Future<void> refreshSummary() async {
    final generation = ++_summaryGeneration;
    final reference = ref;
    state = state.copyWith(summary: const AsyncLoading());
    try {
      final summary = await _source.getSummary(seed.placeId);
      if (!reference.mounted || generation != _summaryGeneration) return;
      state = state.copyWith(summary: AsyncData(summary));
    } catch (error, stack) {
      if (reference.mounted && generation == _summaryGeneration) {
        state = state.copyWith(summary: AsyncError(error, stack));
      }
    }
  }

  void apply(ReviewFilters filters) {
    final generation = ++_generation;
    state = ReviewFeedState(
      filters: filters,
      summary: state.summary,
      isDemo: state.isDemo,
    );
    _first(filters, generation);
  }

  void retry() => apply(state.filters);
  void reset() => apply(const ReviewFilters());

  Future<void> _first(ReviewFilters filters, int generation) async {
    final reference = ref;
    try {
      final page = await _source.getReviews(seed.placeId, filters: filters);
      _validate(page);
      if (!reference.mounted || generation != _generation) return;
      state = ReviewFeedState(
        filters: filters,
        summary: state.summary,
        items: page.items,
        loading: false,
        nextCursor: page.nextCursor,
        totalCount: page.totalCount,
        isDemo: page.isDemo,
      );
    } catch (error) {
      if (!reference.mounted || generation != _generation) return;
      state = ReviewFeedState(
        filters: filters,
        summary: state.summary,
        loading: false,
        isDemo: state.isDemo,
        error: AppErrorMessage.from(
          error,
          fallback: 'Không tải được đánh giá.',
        ),
      );
    }
  }

  Future<void> loadMore() async {
    final cursor = state.nextCursor;
    if (cursor == null || state.loading || state.loadingMore) return;
    final generation = _generation;
    final reference = ref;
    final filters = state.filters;
    state = state.copyWith(loadingMore: true, clearPageError: true);
    try {
      final page = await _source.getReviews(
        seed.placeId,
        filters: filters,
        cursor: cursor,
      );
      _validate(page);
      if (!reference.mounted || generation != _generation) return;
      final items = {for (final review in state.items) review.id: review};
      for (final review in page.items) {
        items.putIfAbsent(review.id, () => review);
      }
      state = state.copyWith(
        items: List.unmodifiable(items.values),
        loadingMore: false,
        nextCursor: page.nextCursor,
        clearCursor: page.nextCursor == null || page.nextCursor == cursor,
      );
    } catch (error) {
      if (!reference.mounted || generation != _generation) return;
      state = state.copyWith(
        loadingMore: false,
        pageError: AppErrorMessage.from(
          error,
          fallback: 'Không tải thêm được đánh giá.',
        ),
      );
    }
  }

  void _validate(ReviewPage page) {
    if (page.items.any((review) => review.placeId != seed.placeId)) {
      throw const AppException(
        'Dữ liệu đánh giá không khớp quán. Vui lòng tải lại.',
      );
    }
  }
}
