import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_error_message.dart';
import '../../../core/errors/app_exception.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../reviews/domain/review.dart';
import '../../reviews/domain/review_feed_repository.dart';
import '../../reviews/presentation/review_providers.dart';
import '../domain/public_reviewer_repository.dart';

final publicReviewerRepositoryProvider = Provider<PublicReviewerRepository>((
  ref,
) {
  final repository = ref.watch(reviewRepositoryProvider);
  if (repository is! PublicReviewerRepository) {
    throw const AppException(
      'Hồ sơ công khai chưa được hỗ trợ bởi nguồn dữ liệu này.',
    );
  }
  return repository as PublicReviewerRepository;
});

class PublicReviewerState {
  const PublicReviewerState({
    this.profile,
    this.items = const [],
    this.filter = PublicReviewFilter.newest,
    this.loading = true,
    this.loadingMore = false,
    this.nextCursor,
    this.error,
    this.pageError,
  });
  final PublicReviewer? profile;
  final List<Review> items;
  final PublicReviewFilter filter;
  final bool loading, loadingMore;
  final String? nextCursor, error, pageError;
}

final publicReviewerControllerProvider = NotifierProvider.autoDispose
    .family<PublicReviewerController, PublicReviewerState, String>(
      PublicReviewerController.new,
    );

class PublicReviewerController extends Notifier<PublicReviewerState> {
  PublicReviewerController(this.userId);
  final String userId;
  int _generation = 0;

  @override
  PublicReviewerState build() {
    ref.watch(authSessionProvider.select((value) => value.asData?.value?.id));
    final generation = ++_generation;
    StreamSubscription<void>? changes;
    scheduleMicrotask(() {
      if (!ref.mounted || generation != _generation) return;
      try {
        changes = ref
            .read(publicReviewerRepositoryProvider)
            .watchPublicReviewerChanges(userId)
            .listen((_) => refresh(), onError: (_) => refresh());
      } catch (_) {
        // refresh converts unavailable capabilities to a safe, retryable error.
      }
      refresh();
    });
    ref.onDispose(() {
      _generation++;
      changes?.cancel();
    });
    return const PublicReviewerState();
  }

  Future<void> refresh() => apply(state.filter);

  Future<void> apply(PublicReviewFilter filter) async {
    final generation = ++_generation;
    state = PublicReviewerState(filter: filter);
    try {
      final repository = ref.read(publicReviewerRepositoryProvider);
      final profile = await repository.getPublicReviewer(userId);
      if (!ref.mounted || generation != _generation) return;
      if (profile == null) {
        state = PublicReviewerState(filter: filter, loading: false);
        return;
      }
      if (profile.id != userId ||
          profile.name.trim().isEmpty ||
          profile.reviewCount < 0 ||
          profile.photoReviewCount < 0 ||
          profile.photoReviewCount > profile.reviewCount ||
          (profile.averageRating != null &&
              (!profile.averageRating!.isFinite ||
                  profile.averageRating! < 1 ||
                  profile.averageRating! > 5)) ||
          (profile.featured != null && profile.featured!.userId != userId)) {
        throw const AppException('Không đọc được hồ sơ công khai.');
      }
      final page = await repository.getPublicReviews(userId, filter: filter);
      if (!ref.mounted || generation != _generation) return;
      _validate(page, profile, filter);
      state = PublicReviewerState(
        profile: profile,
        items: page.items,
        filter: filter,
        loading: false,
        nextCursor: page.nextCursor,
      );
    } catch (error) {
      if (!ref.mounted || generation != _generation) return;
      state = PublicReviewerState(
        filter: filter,
        loading: false,
        error: AppErrorMessage.from(
          error,
          fallback: 'Không tải được hồ sơ. Vui lòng thử lại.',
        ),
      );
    }
  }

  Future<void> loadMore() async {
    final old = state;
    if (old.loading || old.loadingMore || old.nextCursor == null) return;
    final generation = _generation;
    state = PublicReviewerState(
      profile: old.profile,
      items: old.items,
      filter: old.filter,
      loading: false,
      loadingMore: true,
      nextCursor: old.nextCursor,
    );
    try {
      final page = await ref
          .read(publicReviewerRepositoryProvider)
          .getPublicReviews(userId, filter: old.filter, cursor: old.nextCursor);
      if (!ref.mounted || generation != _generation) return;
      _validate(page, old.profile!, old.filter, loaded: old.items.length);
      if (page.nextCursor == old.nextCursor ||
          page.items.any(
            (r) => old.items.any((existing) => existing.id == r.id),
          )) {
        throw const AppException('Danh sách đã thay đổi. Vui lòng tải lại.');
      }
      state = PublicReviewerState(
        profile: old.profile,
        items: List.unmodifiable([...old.items, ...page.items]),
        filter: old.filter,
        loading: false,
        nextCursor: page.nextCursor,
      );
    } catch (error) {
      if (!ref.mounted || generation != _generation) return;
      state = PublicReviewerState(
        profile: old.profile,
        items: old.items,
        filter: old.filter,
        loading: false,
        nextCursor: old.nextCursor,
        pageError: AppErrorMessage.from(
          error,
          fallback: 'Không tải thêm được bài đánh giá.',
        ),
      );
    }
  }

  void _validate(
    ReviewPage page,
    PublicReviewer profile,
    PublicReviewFilter filter, {
    int loaded = 0,
  }) {
    final expected = filter == PublicReviewFilter.withPhotos
        ? profile.photoReviewCount
        : profile.reviewCount;
    if ((page.totalCount != null && page.totalCount != expected) ||
        loaded + page.items.length > expected ||
        page.items.length > 10 ||
        page.items.any((r) => r.userId != userId) ||
        page.items.map((r) => r.id).toSet().length != page.items.length ||
        (page.nextCursor != null &&
            (page.items.isEmpty || page.nextCursor!.isEmpty))) {
      throw const AppException('Không đọc được bài đánh giá công khai.');
    }
  }
}
