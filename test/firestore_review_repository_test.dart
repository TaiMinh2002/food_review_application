import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:food_review/core/errors/app_exception.dart';
import 'package:food_review/features/reviews/data/cloudinary_review_photo_uploader.dart';
import 'package:food_review/features/reviews/data/firestore_review_repository.dart';
import 'package:food_review/features/reviews/domain/review.dart';
import 'package:food_review/features/reviews/domain/review_feed_repository.dart';
import 'package:food_review/features/reviews/domain/user_review_repository.dart';

void main() {
  group('FirestoreReviewRepository unit tests', () {
    test(
      'Validates review content length, userId and placeId on create',
      () async {
        final repo = FirestoreReviewRepository(null);

        // Empty user id
        expect(
          () => repo.create(
            Review(
              id: 'r1',
              placeId: 'pho-demo',
              userId: '',
              rating: 5,
              content: 'Nước dùng phở bò rất ngon và thơm.',
              createdAt: DateTime.now(),
            ),
          ),
          throwsA(isA<AppException>()),
        );

        // Empty place id
        expect(
          () => repo.create(
            Review(
              id: 'r1',
              placeId: '',
              userId: 'u1',
              rating: 5,
              content: 'Nước dùng phở bò rất ngon và thơm.',
              createdAt: DateTime.now(),
            ),
          ),
          throwsA(isA<AppException>()),
        );

        // Content < 10 chars
        expect(
          () => repo.create(
            Review(
              id: 'r1',
              placeId: 'pho-demo',
              userId: 'u1',
              rating: 5,
              content: 'Quá ngắn',
              createdAt: DateTime.now(),
            ),
          ),
          throwsA(isA<AppException>()),
        );
      },
    );

    test('Creates review via saveReview hook', () async {
      Review? saved;
      final repo = FirestoreReviewRepository(
        null,
        saveReview: (review) async {
          saved = review;
        },
      );

      final review = Review(
        id: 'u1',
        placeId: 'osm_node_123',
        userId: 'u1',
        authorName: 'Minh',
        rating: 5,
        content: 'Bún chả rất ngon và đậm đà hương vị truyền thống.',
        createdAt: DateTime.now(),
        imageUrls: ['https://example.com/photo.jpg'],
      );

      await repo.create(review);
      expect(saved, isNotNull);
      expect(saved!.placeId, 'osm_node_123');
      expect(saved!.userId, 'u1');
      expect(saved!.imageUrls, hasLength(1));
    });

    test('Updates review via updateReviewHook', () async {
      Review? updated;
      final repo = FirestoreReviewRepository(
        null,
        updateReviewHook: (review) async {
          updated = review;
        },
      );

      final review = Review(
        id: 'u1',
        placeId: 'osm_node_123',
        userId: 'u1',
        rating: 4,
        content: 'Đã cập nhật: chất lượng món ăn rất ổn định.',
        createdAt: DateTime.now(),
      );

      await repo.update(review);
      expect(updated, isNotNull);
      expect(updated!.rating, 4);
      expect(updated!.content, contains('Đã cập nhật'));

      // Validate short content on update
      expect(
        () => repo.update(
          Review(
            id: 'u1',
            placeId: 'osm_node_123',
            userId: 'u1',
            rating: 4,
            content: 'Ngắn',
            createdAt: DateTime.now(),
          ),
        ),
        throwsA(isA<AppException>()),
      );
    });

    test('Deletes review via deleteReviewHook', () async {
      String? deletedId;
      final repo = FirestoreReviewRepository(
        null,
        deleteReviewHook: (userId, placeId, reviewId) async {
          deletedId = reviewId;
        },
      );

      await repo.delete(userId: 'u1', placeId: 'osm_node_123', reviewId: 'u1');
      expect(deletedId, 'u1');

      expect(
        () => repo.delete(userId: '', placeId: 'osm_node_123', reviewId: 'u1'),
        throwsA(isA<AppException>()),
      );
    });

    test('Streams reviews for place via watchPlaceHook', () async {
      final streamController = StreamController<List<Review>>.broadcast();
      addTearDown(streamController.close);

      final repo = FirestoreReviewRepository(
        null,
        watchPlaceHook: (placeId, limit) => streamController.stream,
      );

      final stream = repo.watchForPlace('osm_node_123');
      final expectation = expectLater(
        stream,
        emits([predicate<Review>((r) => r.placeId == 'osm_node_123')]),
      );

      streamController.add([
        Review(
          id: 'u1',
          placeId: 'osm_node_123',
          userId: 'u1',
          rating: 5,
          content: 'Quán ăn tuyệt vời, giá cả phải chăng.',
          createdAt: DateTime.now(),
        ),
      ]);
      await expectation;
    });

    test('Gets review via getReviewHook', () async {
      final repo = FirestoreReviewRepository(
        null,
        getReviewHook: (placeId, reviewId) async {
          if (reviewId == 'u1') {
            return Review(
              id: 'u1',
              placeId: placeId,
              userId: 'u1',
              rating: 5,
              content: 'Nội dung đánh giá mẫu hợp lệ.',
              createdAt: DateTime.now(),
            );
          }
          return null;
        },
      );

      expect(await repo.getReview('', 'u1'), isNull);
      expect(await repo.getReview('p1', ''), isNull);

      final result = await repo.getReview('osm_node_123', 'u1');
      expect(result, isNotNull);
      expect(result!.userId, 'u1');

      final notFound = await repo.getReview('osm_node_123', 'nonexistent');
      expect(notFound, isNull);
    });

    test(
      'getSummary returns empty summary for empty placeId or via hook',
      () async {
        final repo = FirestoreReviewRepository(
          null,
          getSummaryHook: (placeId) async => ReviewSummary(
            totalCount: 3,
            averageRating: 4.67,
            starCounts: const {1: 0, 2: 0, 3: 0, 4: 1, 5: 2},
            withPhotosCount: 2,
          ),
        );

        final empty = await repo.getSummary('');
        expect(empty.totalCount, 0);

        final summary = await repo.getSummary('osm_node_123');
        expect(summary.totalCount, 3);
        expect(summary.averageRating, 4.67);
        expect(summary.starCounts?[5], 2);
      },
    );

    test('getReviews validates pageSize and returns page via hook', () async {
      final repo = FirestoreReviewRepository(
        null,
        getReviewsHook: (placeId, filters, cursor, pageSize) async =>
            ReviewPage(
              items: [
                Review(
                  id: 'u1',
                  placeId: placeId,
                  userId: 'u1',
                  rating: 5,
                  content: 'Ngon tuyệt vời!',
                  createdAt: DateTime.now(),
                ),
              ],
              nextCursor: null,
              totalCount: 1,
            ),
      );

      expect(
        () =>
            repo.getReviews('p1', filters: const ReviewFilters(), pageSize: 0),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () =>
            repo.getReviews('p1', filters: const ReviewFilters(), pageSize: 51),
        throwsA(isA<ArgumentError>()),
      );

      final empty = await repo.getReviews('', filters: const ReviewFilters());
      expect(empty.items, isEmpty);

      final page = await repo.getReviews(
        'osm_node_123',
        filters: const ReviewFilters(),
      );
      expect(page.items, hasLength(1));
      expect(page.items.first.content, 'Ngon tuyệt vời!');
    });

    test(
      'getUserReviewSummary returns empty for empty userId or via hook',
      () async {
        final repo = FirestoreReviewRepository(
          null,
          getUserReviewSummaryHook: (userId) async => const UserReviewSummary(
            total: 5,
            withPhotos: 3,
            edited: 1,
            isDemo: false,
          ),
        );

        final empty = await repo.getUserReviewSummary('');
        expect(empty.total, 0);

        final summary = await repo.getUserReviewSummary('u1');
        expect(summary.total, 5);
        expect(summary.withPhotos, 3);
        expect(summary.edited, 1);
      },
    );

    test(
      'getUserReviews validates pageSize and returns page via hook',
      () async {
        final repo = FirestoreReviewRepository(
          null,
          getUserReviewsHook: (userId, filter, cursor, pageSize) async =>
              ReviewPage(
                items: [
                  Review(
                    id: 'u1',
                    placeId: 'pho-demo',
                    userId: userId,
                    rating: 5,
                    content: 'Phở bò nước dùng trong và ngọt.',
                    createdAt: DateTime.now(),
                  ),
                ],
                totalCount: 1,
              ),
        );

        expect(
          () => repo.getUserReviews(
            'u1',
            filter: UserReviewFilter.all,
            pageSize: 0,
          ),
          throwsA(isA<ArgumentError>()),
        );
        expect(
          () => repo.getUserReviews(
            'u1',
            filter: UserReviewFilter.all,
            pageSize: 51,
          ),
          throwsA(isA<ArgumentError>()),
        );

        final empty = await repo.getUserReviews(
          '',
          filter: UserReviewFilter.all,
        );
        expect(empty.items, isEmpty);

        final page = await repo.getUserReviews(
          'u1',
          filter: UserReviewFilter.all,
        );
        expect(page.items, hasLength(1));
        expect(page.items.first.content, contains('nước dùng'));
      },
    );

    test('watchUserReviewChanges emits when review created', () async {
      final repo = FirestoreReviewRepository(
        null,
        saveReview: (review) async {},
      );

      final emitted = <void>[];
      final sub = repo.watchUserReviewChanges('u1').listen((event) {
        emitted.add(event);
      });
      addTearDown(sub.cancel);

      await repo.create(
        Review(
          id: 'u1',
          placeId: 'p1',
          userId: 'u1',
          rating: 5,
          content: 'Nội dung đánh giá hợp lệ.',
          createdAt: DateTime.now(),
        ),
      );

      expect(emitted, hasLength(1));
    });
  });

  group('CloudinaryReviewPhotoUploader unit tests', () {
    test('Throws informative exception when config is missing', () async {
      final uploader = CloudinaryReviewPhotoUploader();
      // AppConfig values may be empty in raw test env
      expect(
        () => uploader.uploadPhoto(
          bytes: Uint8List.fromList([1, 2, 3]),
          filename: 'test.jpg',
        ),
        throwsA(isA<AppException>()),
      );
    });
  });
}
