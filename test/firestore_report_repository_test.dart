import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:food_review/core/errors/app_exception.dart';
import 'package:food_review/features/places/domain/place.dart';
import 'package:food_review/features/places/domain/place_repository.dart';
import 'package:food_review/features/profile/domain/public_reviewer_repository.dart';
import 'package:food_review/features/reports/data/firestore_report_repository.dart';
import 'package:food_review/features/reports/domain/report_repository.dart';
import 'package:food_review/features/reviews/domain/review.dart';
import 'package:food_review/features/reviews/domain/review_feed_repository.dart';
import 'package:food_review/features/reviews/domain/review_repository.dart';

class _FakePlaceRepo implements PlaceRepository {
  _FakePlaceRepo(this.place);
  final Place? place;

  @override
  Future<List<Place>> fetchPlaces() async => place != null ? [place!] : [];

  @override
  Future<Place?> getPlace(String id) async => place?.id == id ? place : null;
}

class _FakeReviewRepo
    implements
        ReviewRepository,
        ReviewMediaRepository,
        PublicReviewerRepository {
  _FakeReviewRepo({this.review, this.reviewer});
  final Review? review;
  final PublicReviewer? reviewer;

  @override
  Future<void> create(Review review) async {}

  @override
  Stream<List<Review>> watchForPlace(String placeId, {int limit = 3}) =>
      const Stream.empty();

  @override
  Future<Review?> getReview(String placeId, String reviewId) async =>
      review?.id == reviewId && review?.placeId == placeId ? review : null;

  @override
  Future<PublicReviewer?> getPublicReviewer(String userId) async =>
      reviewer?.id == userId ? reviewer : null;

  @override
  Future<ReviewPage> getPublicReviews(
    String userId, {
    PublicReviewFilter filter = PublicReviewFilter.newest,
    String? cursor,
    int pageSize = 10,
  }) async => ReviewPage(items: const [], totalCount: 0);

  @override
  Stream<void> watchPublicReviewerChanges(String userId) =>
      const Stream.empty();
}

void main() {
  const dummyPlace = Place(
    id: 'pho-1',
    name: 'Phở Thìn',
    description: 'Phở bò',
    category: 'Món Việt',
    address: '13 Lò Đúc',
    latitude: 21.0,
    longitude: 105.8,
  );

  group('FirestoreReportRepository unit tests', () {
    test('Validates empty reporterId and target id', () async {
      final repo = FirestoreReportRepository(
        null,
        places: _FakePlaceRepo(null),
        reviews: _FakeReviewRepo(),
      );

      final result = await repo.getTarget((
        type: ReportTargetType.place,
        id: '',
        placeId: null,
      ), reporterId: 'u1');
      expect(result, isNull);

      final resultEmptyReporter = await repo.getTarget((
        type: ReportTargetType.place,
        id: 'p1',
        placeId: null,
      ), reporterId: '');
      expect(resultEmptyReporter, isNull);

      expect(
        () => repo.submit(
          reporterId: '',
          requestId: 'req1',
          draft: ReportDraft(
            target: (type: ReportTargetType.place, id: 'p1', placeId: null),
            reason: ReportReason.spam,
            description: 'Spam',
          ),
        ),
        throwsA(isA<AppException>()),
      );
    });

    test('Validates description length limit (max 500 chars)', () async {
      final repo = FirestoreReportRepository(
        null,
        places: _FakePlaceRepo(null),
        reviews: _FakeReviewRepo(),
      );

      final longDesc = 'A' * 501;
      expect(
        () => repo.submit(
          reporterId: 'u1',
          requestId: 'req1',
          draft: ReportDraft(
            target: (type: ReportTargetType.place, id: 'p1', placeId: null),
            reason: ReportReason.spam,
            description: longDesc,
          ),
        ),
        throwsA(isA<AppException>()),
      );
    });

    test('Validates evidence photo count limit (max 3)', () async {
      final repo = FirestoreReportRepository(
        null,
        places: _FakePlaceRepo(null),
        reviews: _FakeReviewRepo(),
      );

      final fakeJpeg = Uint8List.fromList([255, 216, 255, 0]);
      final tooManyEvidence = [
        ReportEvidence(bytes: fakeJpeg, name: '1.jpg'),
        ReportEvidence(bytes: fakeJpeg, name: '2.jpg'),
        ReportEvidence(bytes: fakeJpeg, name: '3.jpg'),
        ReportEvidence(bytes: fakeJpeg, name: '4.jpg'),
      ];

      expect(
        () => repo.submit(
          reporterId: 'u1',
          requestId: 'req1',
          draft: ReportDraft(
            target: (type: ReportTargetType.place, id: 'p1', placeId: null),
            reason: ReportReason.spam,
            description: 'Spam',
            evidence: tooManyEvidence,
          ),
        ),
        throwsA(isA<AppException>()),
      );
    });

    test('getTarget resolves place target context', () async {
      final repo = FirestoreReportRepository(
        null,
        places: _FakePlaceRepo(dummyPlace),
        reviews: _FakeReviewRepo(),
      );

      final context = await repo.getTarget((
        type: ReportTargetType.place,
        id: 'pho-1',
        placeId: null,
      ), reporterId: 'u1');

      expect(context, isNotNull);
      expect(context!.title, 'Phở Thìn');
      expect(context.subtitle, contains('Món Việt'));
    });

    test('getTarget resolves review target context', () async {
      final fakeReview = Review(
        id: 'r1',
        placeId: 'pho-1',
        userId: 'u2',
        rating: 1,
        content: 'Thái độ phục vụ rất tệ.',
        createdAt: DateTime.now(),
        authorName: 'Khách A',
      );

      final repo = FirestoreReportRepository(
        null,
        places: _FakePlaceRepo(dummyPlace),
        reviews: _FakeReviewRepo(review: fakeReview),
      );

      final context = await repo.getTarget((
        type: ReportTargetType.review,
        id: 'r1',
        placeId: 'pho-1',
      ), reporterId: 'u1');

      expect(context, isNotNull);
      expect(context!.title, 'Phở Thìn');
      expect(context.authorName, 'Khách A');
      expect(context.excerpt, 'Thái độ phục vụ rất tệ.');
    });

    test('getTarget resolves user target context', () async {
      const fakeReviewer = PublicReviewer(
        id: 'user-xyz',
        name: 'Trần Nam',
        handle: '@trannam',
        reviewCount: 3,
        photoReviewCount: 1,
      );

      final repo = FirestoreReportRepository(
        null,
        places: _FakePlaceRepo(null),
        reviews: _FakeReviewRepo(reviewer: fakeReviewer),
      );

      final context = await repo.getTarget((
        type: ReportTargetType.user,
        id: 'user-xyz',
        placeId: null,
      ), reporterId: 'u1');

      expect(context, isNotNull);
      expect(context!.title, 'Trần Nam');
      expect(context.subtitle, '@trannam');
    });

    test('submit executes hook and returns non-demo receipt', () async {
      var called = false;
      final repo = FirestoreReportRepository(
        null,
        places: _FakePlaceRepo(dummyPlace),
        reviews: _FakeReviewRepo(),
        submitHook: (reporterId, requestId, draft) async {
          called = true;
          expect(reporterId, 'u1');
          expect(requestId, 'req-123');
          expect(draft.reason, ReportReason.inaccurate);
          return ReportReceipt(id: requestId, isDemo: false);
        },
      );

      final receipt = await repo.submit(
        reporterId: 'u1',
        requestId: 'req-123',
        draft: ReportDraft(
          target: (type: ReportTargetType.place, id: 'pho-1', placeId: null),
          reason: ReportReason.inaccurate,
          description: 'Quán đã chuyển địa điểm sang phố khác.',
        ),
      );

      expect(called, isTrue);
      expect(receipt.id, 'req-123');
      expect(receipt.isDemo, isFalse);
    });
  });
}
