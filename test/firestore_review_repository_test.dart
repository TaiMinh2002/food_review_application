import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:food_review/core/errors/app_exception.dart';
import 'package:food_review/features/reviews/data/cloudinary_review_photo_uploader.dart';
import 'package:food_review/features/reviews/data/firestore_review_repository.dart';
import 'package:food_review/features/reviews/domain/review.dart';

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
