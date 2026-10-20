import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_error_message.dart';
import '../../../core/errors/app_exception.dart';
import '../../auth/presentation/auth_providers.dart';
import '../domain/review.dart';
import '../domain/review_feed_repository.dart';
import '../domain/user_review_repository.dart';
import 'review_providers.dart';

class MyReviewsState {
  const MyReviewsState({
    this.filter = UserReviewFilter.all,
    this.summary = const AsyncLoading(),
    this.items = const [],
    this.loading = true,
    this.refreshing = false,
    this.loadingMore = false,
    this.error,
    this.pageError,
    this.nextCursor,
    this.isDemo = false,
  });
  final UserReviewFilter filter;
  final AsyncValue<UserReviewSummary> summary;
  final List<Review> items;
  final bool loading, refreshing, loadingMore, isDemo;
  final String? error, pageError, nextCursor;
}

final myReviewsControllerProvider =
    NotifierProvider.autoDispose<MyReviewsController, MyReviewsState>(
      MyReviewsController.new,
    );

class MyReviewsController extends Notifier<MyReviewsState> {
  UserReviewRepository? _repository;
  String? _userId;
  int _generation = 0;

  @override
  MyReviewsState build() {
    final session = ref.watch(authSessionProvider);
    _userId = !session.isLoading && !session.hasError
        ? session.asData?.value?.id
        : null;
    final repository = ref.watch(reviewRepositoryProvider);
    _repository = repository is UserReviewRepository
        ? repository as UserReviewRepository
        : null;
    final generation = ++_generation;
    ref.onDispose(() => _generation++);
    final userId = _userId;
    if (userId != null) {
      final subscription = _repository
          ?.watchUserReviewChanges(userId)
          .listen(
            (_) => refresh(),
            onError: (Object error) {
              if (ref.mounted) refresh();
            },
          );
      if (subscription != null) ref.onDispose(subscription.cancel);
      scheduleMicrotask(() {
        if (ref.mounted && generation == _generation) refresh();
      });
    }
    return const MyReviewsState();
  }

  UserReviewRepository get _source =>
      _repository ??
      (throw const AppException(
        'Nguồn dữ liệu hiện tại chưa hỗ trợ danh sách đánh giá cá nhân phân trang.',
      ));

  Future<void> apply(UserReviewFilter filter) => _first(filter, retain: false);
  Future<void> refresh() => _first(state.filter, retain: true);

  Future<void> _first(UserReviewFilter filter, {required bool retain}) async {
    final userId = _userId;
    if (userId == null) return;
    final generation = ++_generation;
    final old = state;
    state = MyReviewsState(
      filter: filter,
      summary: old.summary,
      items: retain ? old.items : const [],
      loading: !retain || old.items.isEmpty,
      refreshing: retain && old.items.isNotEmpty,
      isDemo: old.isDemo,
    );
    final summary = await AsyncValue.guard(
      () => _source.getUserReviewSummary(userId),
    );
    if (!ref.mounted || generation != _generation) return;
    try {
      final page = await _source.getUserReviews(userId, filter: filter);
      _validate(page, userId, filter);
      if (!ref.mounted || generation != _generation) return;
      state = MyReviewsState(
        filter: filter,
        summary: summary,
        items: page.items,
        loading: false,
        nextCursor: page.nextCursor,
        isDemo: page.isDemo,
      );
    } catch (error) {
      if (!ref.mounted || generation != _generation) return;
      state = MyReviewsState(
        filter: filter,
        summary: summary,
        items: retain ? old.items : const [],
        loading: false,
        isDemo: old.isDemo,
        error: AppErrorMessage.from(
          error,
          fallback: 'Không tải được đánh giá của bạn.',
        ),
      );
    }
  }

  Future<void> loadMore() async {
    final old = state;
    final cursor = old.nextCursor;
    final userId = _userId;
    if (userId == null ||
        cursor == null ||
        old.loading ||
        old.refreshing ||
        old.loadingMore) {
      return;
    }
    final generation = _generation;
    state = MyReviewsState(
      filter: old.filter,
      summary: old.summary,
      items: old.items,
      loading: false,
      loadingMore: true,
      nextCursor: cursor,
      isDemo: old.isDemo,
    );
    try {
      final page = await _source.getUserReviews(
        userId,
        filter: old.filter,
        cursor: cursor,
      );
      _validate(page, userId, old.filter);
      if (!ref.mounted || generation != _generation) return;
      final items = {
        for (final review in old.items) (review.placeId, review.id): review,
      };
      for (final review in page.items) {
        items[(review.placeId, review.id)] = review;
      }
      state = MyReviewsState(
        filter: old.filter,
        summary: old.summary,
        items: List.unmodifiable(items.values),
        loading: false,
        nextCursor: page.nextCursor == cursor ? null : page.nextCursor,
        isDemo: page.isDemo,
      );
    } catch (error) {
      if (!ref.mounted || generation != _generation) return;
      state = MyReviewsState(
        filter: old.filter,
        summary: old.summary,
        items: old.items,
        loading: false,
        nextCursor: cursor,
        isDemo: old.isDemo,
        pageError: AppErrorMessage.from(
          error,
          fallback: 'Không tải thêm được đánh giá.',
        ),
      );
    }
  }

  void _validate(ReviewPage page, String userId, UserReviewFilter filter) {
    if (page.items.any(
      (review) =>
          review.userId != userId ||
          switch (filter) {
            UserReviewFilter.all => false,
            UserReviewFilter.withPhotos => review.imageUrls.isEmpty,
            UserReviewFilter.edited => review.updatedAt == null,
          },
    )) {
      throw const AppException(
        'Dữ liệu đánh giá không khớp tài khoản hoặc bộ lọc. Vui lòng tải lại.',
      );
    }
  }
}
