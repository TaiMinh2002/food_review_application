import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_review/core/errors/app_exception.dart';
import 'package:food_review/features/auth/presentation/auth_providers.dart';
import 'package:food_review/features/reviews/data/demo_review_repository.dart';
import 'package:food_review/features/reviews/domain/review_feed_repository.dart';
import 'package:food_review/features/reviews/domain/user_review_repository.dart';
import 'package:food_review/features/reviews/presentation/my_reviews_controller.dart';
import 'package:food_review/features/reviews/presentation/review_providers.dart';

import 'support/auth_harness.dart';
import 'support/my_review_fixtures.dart';

class _ControlledReviews extends DemoReviewRepository {
  _ControlledReviews()
    : super(
        data: [
          ...ownedReviews(),
          ...ownedReviews(count: 1, userId: 'user-b'),
        ],
      );
  bool failFirst = false, failMore = false, failSummary = false;
  int requests = 0;
  Completer<ReviewPage>? pending;
  @override
  Future<UserReviewSummary> getUserReviewSummary(String userId) async {
    if (failSummary) throw const AppException('Không tải được thống kê.');
    return super.getUserReviewSummary(userId);
  }

  @override
  Future<ReviewPage> getUserReviews(
    String userId, {
    required UserReviewFilter filter,
    String? cursor,
    int pageSize = 10,
  }) async {
    requests++;
    if ((cursor == null && failFirst) || (cursor != null && failMore)) {
      throw const AppException('Lỗi tải thử nghiệm');
    }
    final wait = pending;
    pending = null;
    if (wait != null) return wait.future;
    return super.getUserReviews(
      userId,
      filter: filter,
      cursor: cursor,
      pageSize: pageSize,
    );
  }
}

Future<void> settle() => Future<void>.delayed(Duration.zero);

void main() {
  test(
    'User queries count and filter before paging; cursor ordering is stable',
    () async {
      final repository = _ControlledReviews();
      addTearDown(repository.dispose);
      final summary = await repository.getUserReviewSummary('user-a');
      expect(summary.total, 23);
      expect(summary.withPhotos, 12);
      expect(summary.edited, 8);
      final first = await repository.getUserReviews(
        'user-a',
        filter: UserReviewFilter.all,
      );
      final second = await repository.getUserReviews(
        'user-a',
        filter: UserReviewFilter.all,
        cursor: first.nextCursor,
      );
      expect(first.items.length, 10);
      expect(second.items.length, 10);
      expect(
        {
          ...first.items.map((r) => r.id),
          ...second.items.map((r) => r.id),
        }.length,
        20,
      );
      expect(
        [...first.items, ...second.items].every((r) => r.userId == 'user-a'),
        isTrue,
      );
      final edited = await repository.getUserReviews(
        'user-a',
        filter: UserReviewFilter.edited,
      );
      expect(edited.items.length, 8);
      expect(edited.nextCursor, isNull);
      await expectLater(
        repository.getUserReviews(
          'user-a',
          filter: UserReviewFilter.all,
          cursor: 'not-found',
        ),
        throwsA(isA<AppException>()),
      );
    },
  );

  test(
    'Initial and page failures retry; summary failure does not hide records',
    () async {
      final repository = _ControlledReviews()..failFirst = true;
      final container = ProviderContainer(
        overrides: [
          authSessionProvider.overrideWithValue(const AsyncData(authTestUser)),
          reviewRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(() {
        container.dispose();
        repository.dispose();
      });
      final subscription = container.listen(
        myReviewsControllerProvider,
        (_, _) {},
      );
      addTearDown(subscription.close);
      await settle();
      expect(container.read(myReviewsControllerProvider).error, isNotNull);
      repository.failFirst = false;
      final controller = container.read(myReviewsControllerProvider.notifier);
      await controller.refresh();
      expect(container.read(myReviewsControllerProvider).items.length, 10);
      repository.failMore = true;
      await controller.loadMore();
      expect(container.read(myReviewsControllerProvider).pageError, isNotNull);
      expect(container.read(myReviewsControllerProvider).items.length, 10);
      repository.failMore = false;
      await controller.loadMore();
      expect(container.read(myReviewsControllerProvider).items.length, 20);
      repository.failSummary = true;
      await controller.refresh();
      expect(
        container.read(myReviewsControllerProvider).summary.hasError,
        isTrue,
      );
      expect(container.read(myReviewsControllerProvider).items.length, 10);
    },
  );

  test(
    'Stale page responses cannot overwrite a newer filter or account',
    () async {
      final repository = _ControlledReviews();
      final auth = ControlledAuth(user: authTestUser);
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(auth),
          reviewRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(() async {
        container.dispose();
        repository.dispose();
        await auth.events.close();
      });
      final subscription = container.listen(
        myReviewsControllerProvider,
        (_, _) {},
      );
      addTearDown(subscription.close);
      final authSubscription = container.listen(authSessionProvider, (_, _) {});
      addTearDown(authSubscription.close);
      await container.read(authSessionProvider.future);
      await settle();
      final controller = container.read(myReviewsControllerProvider.notifier);
      await controller.refresh();
      expect(container.read(myReviewsControllerProvider).items.length, 10);
      final delayed = Completer<ReviewPage>();
      repository.pending = delayed;
      final loading = controller.loadMore();
      await controller.loadMore();
      await controller.apply(UserReviewFilter.withPhotos);
      delayed.complete(ReviewPage(items: [ownedReviews()[1]]));
      await loading;
      expect(
        container
            .read(myReviewsControllerProvider)
            .items
            .every((r) => r.imageUrls.isNotEmpty),
        isTrue,
      );
      final accountDelay = Completer<ReviewPage>();
      repository.pending = accountDelay;
      final next = controller.refresh();
      await settle();
      auth.setUser(null);
      await settle();
      accountDelay.complete(ReviewPage(items: ownedReviews(count: 1)));
      await next;
      expect(container.read(myReviewsControllerProvider).items, isEmpty);
    },
  );

  test(
    'Wrong-owner response is rejected and own mutations update counts',
    () async {
      final repository = _ControlledReviews();
      final container = ProviderContainer(
        overrides: [
          authSessionProvider.overrideWithValue(const AsyncData(authTestUser)),
          reviewRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(() {
        container.dispose();
        repository.dispose();
      });
      final subscription = container.listen(
        myReviewsControllerProvider,
        (_, _) {},
      );
      addTearDown(subscription.close);
      await settle();
      await repository.delete(
        userId: 'user-a',
        placeId: 'pho-demo',
        reviewId: 'owned-0',
      );
      await settle();
      expect(
        container.read(myReviewsControllerProvider).summary.asData!.value.total,
        22,
      );
      final response = Completer<ReviewPage>();
      repository.pending = response;
      final request = container
          .read(myReviewsControllerProvider.notifier)
          .refresh();
      await settle();
      response.complete(
        ReviewPage(items: ownedReviews(count: 1, userId: 'intruder')),
      );
      await request;
      expect(
        container.read(myReviewsControllerProvider).error,
        contains('không khớp'),
      );
      expect(
        container
            .read(myReviewsControllerProvider)
            .items
            .any((r) => r.userId != 'user-a'),
        isFalse,
      );
    },
  );
}
