import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_review/core/errors/app_exception.dart';
import 'package:food_review/features/reviews/data/demo_review_repository.dart';
import 'package:food_review/features/reviews/domain/review.dart';
import 'package:food_review/features/reviews/domain/review_feed_repository.dart';
import 'package:food_review/features/reviews/presentation/review_feed_controller.dart';

Review review(
  String id, {
  String placeId = 'pho-demo',
  int rating = 5,
  bool photo = false,
}) => Review(
  id: id,
  placeId: placeId,
  userId: 'user-$id',
  rating: rating,
  content: 'Nhận xét $id',
  createdAt: DateTime.utc(2026, 10, 1),
  imageUrls: photo ? ['assets/images/demo/pho.jpg'] : [],
);

class PendingReviews implements ReviewFeedRepository {
  final summaries = <Completer<ReviewSummary>>[];
  final pages = <Completer<ReviewPage>>[];
  final requests =
      <({String placeId, ReviewFilters filters, String? cursor})>[];
  @override
  Future<ReviewSummary> getSummary(String placeId) {
    final pending = Completer<ReviewSummary>();
    summaries.add(pending);
    return pending.future;
  }

  @override
  Future<ReviewPage> getReviews(
    String placeId, {
    required ReviewFilters filters,
    String? cursor,
    int pageSize = 10,
  }) {
    requests.add((placeId: placeId, filters: filters, cursor: cursor));
    final pending = Completer<ReviewPage>();
    pages.add(pending);
    return pending.future;
  }
}

void main() {
  test('Summary uses the entire place dataset, filters and paging do not change it', () async {
    final repository = DemoReviewRepository();
    final preview = await repository.watchForPlace('pho-demo', limit: 2).first;
    expect(preview.map((review) => review.id), [
      'review-linh-demo',
      'review-nam-demo',
    ]);
    final summary = await repository.getSummary('pho-demo');
    expect(summary.totalCount, 4);
    expect(summary.averageRating, 4.5);
    expect(summary.starCounts, {1: 0, 2: 0, 3: 0, 4: 2, 5: 2});
    expect(summary.withPhotosCount, 2);
    expect(summary.highRatingPercent, 100);
    final page = await repository.getReviews(
      'pho-demo',
      filters: const ReviewFilters(rating: 4, withPhotos: true),
      pageSize: 1,
    );
    expect(page.items.single.id, 'review-chau-demo');
    expect(page.totalCount, 1);
    expect(page.nextCursor, isNull);
    final empty = await repository.getSummary('coffee-demo');
    expect(empty.totalCount, 0);
    expect(empty.averageRating, isNull);
    expect(empty.highRatingPercent, isNull);
    expect(() => summary.starCounts![5] = 999, throwsUnsupportedError);
    expect(() => page.items.clear(), throwsUnsupportedError);
    final unknown = ReviewSummary(totalCount: 7, averageRating: 4);
    expect(unknown.starCounts, isNull);
    expect(unknown.highRatingPercent, isNull);
    expect(
      () => ReviewSummary(totalCount: 5, starCounts: {5: 2}),
      throwsArgumentError,
    );
  });

  test(
    'Paging is bounded, sorted and isolated by place with stable ties',
    () async {
      final data = List.generate(
        25,
        (i) => review(
          'r-${i.toString().padLeft(2, '0')}',
          rating: i.isEven ? 5 : 3,
        ),
      );
      final repository = DemoReviewRepository(
        data: [
          ...data,
          review('foreign', placeId: 'other'),
        ],
      );
      final page = await repository.getReviews(
        'pho-demo',
        filters: const ReviewFilters(),
      );
      final next = await repository.getReviews(
        'pho-demo',
        filters: const ReviewFilters(),
        cursor: page.nextCursor,
      );
      expect(page.items, hasLength(10));
      expect(page.items.first.id, 'r-00');
      expect(next.items.first.id, 'r-10');
      expect(page.totalCount, 25);
      expect((await repository.getSummary('other')).totalCount, 1);
      expect(
        (await repository.getReviews(
          'pho-demo',
          filters: const ReviewFilters(sort: ReviewSort.ratingLow),
        )).items.first.rating,
        3,
      );
      expect(
        () => repository.getReviews(
          'pho-demo',
          filters: const ReviewFilters(),
          cursor: '-1',
        ),
        throwsA(isA<AppException>()),
      );
      expect(
        () => repository.getReviews(
          'pho-demo',
          filters: const ReviewFilters(),
          pageSize: 51,
        ),
        throwsArgumentError,
      );
    },
  );

  test('Filter URI roundtrip and invalid parameters are safe', () {
    const filters = ReviewFilters(
      rating: 4,
      withPhotos: true,
      sort: ReviewSort.oldest,
    );
    expect(
      ReviewFilters.fromUri(
        Uri(path: '/reviews', queryParameters: filters.queryParameters),
      ),
      filters,
    );
    expect(
      ReviewFilters.fromUri(
        Uri.parse('/reviews?rating=9&sort=unknown&photos=no'),
      ),
      const ReviewFilters(),
    );
    expect(filters.copyWith(clearRating: true).rating, isNull);
    expect(filters.copyWith(withPhotos: false).withPhotos, isFalse);
  });

  Future<({ProviderContainer container, ReviewFeedController controller})>
  mount(PendingReviews repository) async {
    final container = ProviderContainer(
      overrides: [reviewFeedRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    const seed = (placeId: 'pho-demo', scope: 'test', filters: ReviewFilters());
    final subscription = container.listen(
      reviewFeedControllerProvider(seed),
      (_, _) {},
    );
    addTearDown(subscription.close);
    final controller = container.read(
      reviewFeedControllerProvider(seed).notifier,
    );
    await Future<void>.delayed(Duration.zero);
    return (container: container, controller: controller);
  }

  const seed = (placeId: 'pho-demo', scope: 'test', filters: ReviewFilters());

  test('Late filter response is ignored while summary remains independent and retryable', () async {
    final repository = PendingReviews();
    final mounted = await mount(repository);
    mounted.controller.apply(const ReviewFilters(rating: 4));
    repository.pages.last.complete(
      ReviewPage(items: [review('new', rating: 4)], totalCount: 1),
    );
    repository.pages.first.complete(ReviewPage(items: [review('old')]));
    repository.summaries.first.completeError(const AppException('Lỗi summary'));
    await Future<void>.delayed(Duration.zero);
    var state = mounted.container.read(reviewFeedControllerProvider(seed));
    expect(state.items.single.id, 'new');
    expect(state.summary.hasError, isTrue);
    final pageRequests = repository.pages.length;
    final retry = mounted.controller.refreshSummary();
    repository.summaries.last.complete(
      ReviewSummary(totalCount: 4, averageRating: 4.5),
    );
    await retry;
    state = mounted.container.read(reviewFeedControllerProvider(seed));
    expect(state.summary.requireValue.totalCount, 4);
    expect(repository.pages, hasLength(pageRequests));
  });

  test('Pagination guards duplicates, keeps records on failure and stops repeated cursor', () async {
    final repository = PendingReviews();
    final mounted = await mount(repository);
    repository.summaries.first.complete(ReviewSummary(totalCount: 3));
    repository.pages.first.complete(
      ReviewPage(items: [review('a')], nextCursor: 'next'),
    );
    await Future<void>.delayed(Duration.zero);
    final first = mounted.controller.loadMore();
    await mounted.controller.loadMore();
    expect(repository.pages, hasLength(2));
    repository.pages.last.completeError(const AppException('Lỗi trang'));
    await first;
    expect(
      mounted.container
          .read(reviewFeedControllerProvider(seed))
          .items
          .single
          .id,
      'a',
    );
    final retry = mounted.controller.loadMore();
    repository.pages.last.complete(
      ReviewPage(items: [review('a'), review('b')], nextCursor: 'next'),
    );
    await retry;
    final state = mounted.container.read(reviewFeedControllerProvider(seed));
    expect(state.items.map((r) => r.id), ['a', 'b']);
    expect(state.pageError, isNull);
    expect(state.nextCursor, isNull);
    expect(repository.requests.every((r) => r.placeId == 'pho-demo'), isTrue);
  });

  test(
    'Changing filters rejects stale pagination and mixed-place records',
    () async {
      final repository = PendingReviews();
      final mounted = await mount(repository);
      repository.summaries.first.complete(ReviewSummary(totalCount: 2));
      repository.pages.first.complete(
        ReviewPage(items: [review('a')], nextCursor: 'next'),
      );
      await Future<void>.delayed(Duration.zero);
      final more = mounted.controller.loadMore();
      mounted.controller.apply(const ReviewFilters(withPhotos: true));
      repository.pages.last.complete(
        ReviewPage(items: [review('foreign', placeId: 'other')]),
      );
      repository.pages[1].complete(ReviewPage(items: [review('stale')]));
      await more;
      await Future<void>.delayed(Duration.zero);
      final state = mounted.container.read(reviewFeedControllerProvider(seed));
      expect(state.items, isEmpty);
      expect(state.error, contains('không khớp quán'));
    },
  );

  test(
    'Disposed controllers ignore pending page and summary results',
    () async {
      final repository = PendingReviews();
      final container = ProviderContainer(
        overrides: [reviewFeedRepositoryProvider.overrideWithValue(repository)],
      );
      container.listen(reviewFeedControllerProvider(seed), (_, _) {});
      await Future<void>.delayed(Duration.zero);
      container.dispose();
      repository.pages.first.complete(ReviewPage(items: [review('late')]));
      repository.summaries.first.complete(ReviewSummary(totalCount: 0));
      await Future<void>.delayed(Duration.zero);
    },
  );
}
