import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/errors/app_exception.dart';
import '../domain/review.dart';
import '../domain/review_feed_repository.dart';
import '../domain/review_repository.dart';
import '../domain/user_review_repository.dart';

class FirestoreReviewRepository
    implements
        ReviewRepository,
        ReviewManagementRepository,
        ReviewMediaRepository,
        ReviewFeedRepository,
        UserReviewRepository {
  FirestoreReviewRepository(
    this._firestore, {
    this.saveReview,
    this.updateReviewHook,
    this.deleteReviewHook,
    this.watchPlaceHook,
    this.getReviewHook,
    this.getSummaryHook,
    this.getReviewsHook,
    this.getUserReviewSummaryHook,
    this.getUserReviewsHook,
    this.watchUserReviewChangesHook,
  });

  final FirebaseFirestore? _firestore;
  final Future<void> Function(Review review)? saveReview;
  final Future<void> Function(Review review)? updateReviewHook;
  final Future<void> Function(String userId, String placeId, String reviewId)?
  deleteReviewHook;
  final Stream<List<Review>> Function(String placeId, int limit)?
  watchPlaceHook;
  final Future<Review?> Function(String placeId, String reviewId)?
  getReviewHook;
  final Future<ReviewSummary> Function(String placeId)? getSummaryHook;
  final Future<ReviewPage> Function(
    String placeId,
    ReviewFilters filters,
    String? cursor,
    int pageSize,
  )?
  getReviewsHook;
  final Future<UserReviewSummary> Function(String userId)?
  getUserReviewSummaryHook;
  final Future<ReviewPage> Function(
    String userId,
    UserReviewFilter filter,
    String? cursor,
    int pageSize,
  )?
  getUserReviewsHook;
  final Stream<void> Function(String userId)? watchUserReviewChangesHook;

  final _userChanges = StreamController<String>.broadcast(sync: true);

  void dispose() => _userChanges.close();

  CollectionReference<Map<String, dynamic>> _reviewsCollection(
    String placeId,
  ) => _firestore!.collection('places').doc(placeId).collection('reviews');

  @override
  Stream<List<Review>> watchForPlace(String placeId, {int limit = 20}) {
    if (placeId.trim().isEmpty) return Stream.value(const []);
    if (watchPlaceHook != null) return watchPlaceHook!(placeId, limit);
    return _reviewsCollection(placeId)
        .where('status', isEqualTo: 'public')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(_fromDoc).toList())
        .handleError((error, stack) {
          throw const AppException('Không tải được đánh giá của quán.');
        });
  }

  @override
  Future<void> create(Review review) async {
    if (review.userId.trim().isEmpty) {
      throw const AppException('Vui lòng đăng nhập trước khi gửi đánh giá.');
    }
    if (review.placeId.trim().isEmpty) {
      throw const AppException('Địa điểm không hợp lệ.');
    }
    if (review.content.trim().length < 10) {
      throw const AppException('Nội dung đánh giá cần ít nhất 10 ký tự.');
    }
    if (saveReview != null) {
      await saveReview!(review);
      _userChanges.add(review.userId);
      return;
    }

    final docRef = _reviewsCollection(review.placeId).doc(review.userId);
    try {
      await docRef.set({
        'placeId': review.placeId,
        'userId': review.userId,
        'authorName': review.authorName,
        'rating': review.rating,
        'title': review.title,
        'content': review.content.trim(),
        'visitDate': review.visitDate != null
            ? Timestamp.fromDate(review.visitDate!)
            : null,
        'companion': review.companion,
        'dishes': review.dishes,
        'imageUrls': review.imageUrls,
        'status': 'public',
        'createdAt': FieldValue.serverTimestamp(),
      });
      _userChanges.add(review.userId);
    } on FirebaseException catch (e) {
      throw AppException(
        e.code == 'permission-denied'
            ? 'Bạn không có quyền thực hiện thao tác này.'
            : 'Không gửi được đánh giá. Vui lòng thử lại.',
        code: e.code,
      );
    } catch (_) {
      throw const AppException('Không gửi được đánh giá. Vui lòng thử lại.');
    }
  }

  @override
  Future<Review?> getReview(String placeId, String reviewId) async {
    if (placeId.trim().isEmpty || reviewId.trim().isEmpty) return null;
    if (getReviewHook != null) return getReviewHook!(placeId, reviewId);
    try {
      final doc = await _reviewsCollection(placeId).doc(reviewId).get();
      if (!doc.exists) return null;
      return _fromDoc(doc);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> update(Review review) async {
    if (review.userId.trim().isEmpty) {
      throw const AppException('Vui lòng đăng nhập để sửa đánh giá.');
    }
    if (review.content.trim().length < 10) {
      throw const AppException('Nội dung đánh giá cần ít nhất 10 ký tự.');
    }
    if (updateReviewHook != null) {
      await updateReviewHook!(review);
      _userChanges.add(review.userId);
      return;
    }

    final docRef = _reviewsCollection(review.placeId).doc(review.id);
    try {
      await docRef.update({
        'rating': review.rating,
        'title': review.title,
        'content': review.content.trim(),
        'visitDate': review.visitDate != null
            ? Timestamp.fromDate(review.visitDate!)
            : null,
        'companion': review.companion,
        'dishes': review.dishes,
        'imageUrls': review.imageUrls,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      _userChanges.add(review.userId);
    } on FirebaseException catch (e) {
      throw AppException(
        e.code == 'permission-denied'
            ? 'Bạn không có quyền sửa đánh giá này.'
            : 'Không cập nhật được đánh giá. Vui lòng thử lại.',
        code: e.code,
      );
    } catch (_) {
      throw const AppException(
        'Không cập nhật được đánh giá. Vui lòng thử lại.',
      );
    }
  }

  @override
  Future<void> delete({
    required String userId,
    required String placeId,
    required String reviewId,
  }) async {
    if (userId.trim().isEmpty) {
      throw const AppException('Vui lòng đăng nhập để xóa đánh giá.');
    }
    if (deleteReviewHook != null) {
      await deleteReviewHook!(userId, placeId, reviewId);
      _userChanges.add(userId);
      return;
    }

    final docRef = _reviewsCollection(placeId).doc(reviewId);
    try {
      await docRef.delete();
      _userChanges.add(userId);
    } on FirebaseException catch (e) {
      throw AppException(
        e.code == 'permission-denied'
            ? 'Bạn không có quyền xóa đánh giá này.'
            : 'Không xóa được đánh giá. Vui lòng thử lại.',
        code: e.code,
      );
    } catch (_) {
      throw const AppException('Không xóa được đánh giá. Vui lòng thử lại.');
    }
  }

  @override
  Stream<List<Review>> watchForUser(String userId) {
    if (userId.trim().isEmpty) return Stream.value(const []);
    return _firestore!
        .collectionGroup('reviews')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(_fromDoc).toList())
        .handleError((_, _) => const <Review>[]);
  }

  @override
  Future<ReviewSummary> getSummary(String placeId) async {
    if (placeId.trim().isEmpty) {
      return ReviewSummary(
        totalCount: 0,
        averageRating: null,
        starCounts: const {1: 0, 2: 0, 3: 0, 4: 0, 5: 0},
        withPhotosCount: 0,
        isDemo: false,
      );
    }
    if (getSummaryHook != null) {
      return getSummaryHook!(placeId);
    }

    try {
      final snapshot = await _reviewsCollection(placeId)
          .where('status', isEqualTo: 'public')
          .get();

      if (snapshot.docs.isEmpty) {
        return ReviewSummary(
          totalCount: 0,
          averageRating: null,
          starCounts: const {1: 0, 2: 0, 3: 0, 4: 0, 5: 0},
          withPhotosCount: 0,
          isDemo: false,
        );
      }

      final reviews = snapshot.docs.map(_fromDoc).toList();
      final total = reviews.length;
      final avg =
          reviews.fold<int>(0, (totalRating, r) => totalRating + r.rating) /
          total;
      final starCounts = <int, int>{
        for (var star = 1; star <= 5; star++)
          star: reviews.where((r) => r.rating == star).length,
      };
      final withPhotos = reviews.where((r) => r.imageUrls.isNotEmpty).length;

      return ReviewSummary(
        totalCount: total,
        averageRating: avg,
        starCounts: starCounts,
        withPhotosCount: withPhotos,
        isDemo: false,
      );
    } on FirebaseException catch (e) {
      throw AppException(
        'Không tải được tổng quan đánh giá. Vui lòng thử lại.',
        code: e.code,
      );
    } catch (_) {
      throw const AppException(
        'Không tải được tổng quan đánh giá. Vui lòng thử lại.',
      );
    }
  }

  @override
  Future<ReviewPage> getReviews(
    String placeId, {
    required ReviewFilters filters,
    String? cursor,
    int pageSize = 10,
  }) async {
    if (pageSize < 1 || pageSize > 50) {
      throw ArgumentError.value(pageSize, 'pageSize');
    }
    if (placeId.trim().isEmpty) {
      return ReviewPage(items: const [], totalCount: 0, isDemo: false);
    }
    if (getReviewsHook != null) {
      return getReviewsHook!(placeId, filters, cursor, pageSize);
    }

    try {
      Query<Map<String, dynamic>> query = _reviewsCollection(placeId)
          .where('status', isEqualTo: 'public');

      if (filters.rating != null) {
        query = query.where('rating', isEqualTo: filters.rating);
      }

      query = switch (filters.sort) {
        ReviewSort.newest => query.orderBy('createdAt', descending: true),
        ReviewSort.oldest => query.orderBy('createdAt', descending: false),
        ReviewSort.ratingHigh =>
          query
              .orderBy('rating', descending: true)
              .orderBy('createdAt', descending: true),
        ReviewSort.ratingLow =>
          query
              .orderBy('rating', descending: false)
              .orderBy('createdAt', descending: true),
      };

      if (cursor != null && cursor.isNotEmpty) {
        final startDoc = await _reviewsCollection(placeId).doc(cursor).get();
        if (startDoc.exists) {
          query = query.startAfterDocument(startDoc);
        }
      }

      final snapshot = await query.limit(pageSize + 1).get();
      final docs = snapshot.docs;

      var reviews = docs.map(_fromDoc).toList();
      if (filters.withPhotos) {
        reviews = reviews.where((r) => r.imageUrls.isNotEmpty).toList();
      }

      final hasMore = reviews.length > pageSize;
      final items = hasMore ? reviews.sublist(0, pageSize) : reviews;
      final nextCursor = hasMore && items.isNotEmpty ? items.last.id : null;

      return ReviewPage(items: items, nextCursor: nextCursor, isDemo: false);
    } on FirebaseException catch (e) {
      throw AppException(
        'Không tải được danh sách đánh giá. Vui lòng thử lại.',
        code: e.code,
      );
    } catch (_) {
      throw const AppException(
        'Không tải được danh sách đánh giá. Vui lòng thử lại.',
      );
    }
  }

  @override
  Stream<void> watchUserReviewChanges(String userId) {
    if (userId.trim().isEmpty) return const Stream.empty();
    if (watchUserReviewChangesHook != null) {
      return watchUserReviewChangesHook!(userId);
    }
    return _userChanges.stream.where((id) => id == userId).map((_) {});
  }

  @override
  Future<UserReviewSummary> getUserReviewSummary(String userId) async {
    if (userId.trim().isEmpty) {
      return const UserReviewSummary(
        total: 0,
        withPhotos: 0,
        edited: 0,
        isDemo: false,
      );
    }
    if (getUserReviewSummaryHook != null) {
      return getUserReviewSummaryHook!(userId);
    }
    try {
      final snapshot = await _firestore!
          .collectionGroup('reviews')
          .where('userId', isEqualTo: userId)
          .get();

      final reviews = snapshot.docs.map(_fromDoc).toList();
      return UserReviewSummary(
        total: reviews.length,
        withPhotos: reviews.where((r) => r.imageUrls.isNotEmpty).length,
        edited: reviews.where((r) => r.updatedAt != null).length,
        isDemo: false,
      );
    } on FirebaseException catch (e) {
      throw AppException(
        'Không tải được thống kê đánh giá cá nhân. Vui lòng thử lại.',
        code: e.code,
      );
    } catch (_) {
      throw const AppException(
        'Không tải được thống kê đánh giá cá nhân. Vui lòng thử lại.',
      );
    }
  }

  @override
  Future<ReviewPage> getUserReviews(
    String userId, {
    required UserReviewFilter filter,
    String? cursor,
    int pageSize = 10,
  }) async {
    if (pageSize < 1 || pageSize > 50) {
      throw ArgumentError.value(pageSize, 'pageSize');
    }
    if (userId.trim().isEmpty) {
      return ReviewPage(items: const [], totalCount: 0, isDemo: false);
    }
    if (getUserReviewsHook != null) {
      return getUserReviewsHook!(userId, filter, cursor, pageSize);
    }
    try {
      final snapshot = await _firestore!
          .collectionGroup('reviews')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      var owned = snapshot.docs.map(_fromDoc).toList();
      owned = owned
          .where(
            (r) => switch (filter) {
              UserReviewFilter.all => true,
              UserReviewFilter.withPhotos => r.imageUrls.isNotEmpty,
              UserReviewFilter.edited => r.updatedAt != null,
            },
          )
          .toList();

      var start = 0;
      if (cursor != null) {
        final index = owned.indexWhere((r) => r.id == cursor);
        if (index < 0) {
          throw const AppException('Danh sách đã thay đổi. Vui lòng tải lại.');
        }
        start = index + 1;
      }

      final items = owned.skip(start).take(pageSize).toList();
      final nextCursor = start + items.length < owned.length
          ? items.last.id
          : null;

      return ReviewPage(
        items: items,
        totalCount: owned.length,
        nextCursor: nextCursor,
        isDemo: false,
      );
    } on AppException {
      rethrow;
    } on FirebaseException catch (e) {
      throw AppException(
        'Không tải được danh sách đánh giá cá nhân. Vui lòng thử lại.',
        code: e.code,
      );
    } catch (_) {
      throw const AppException(
        'Không tải được danh sách đánh giá cá nhân. Vui lòng thử lại.',
      );
    }
  }

  Review _fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final createdAtRaw = data['createdAt'];
    DateTime createdAt;
    if (createdAtRaw is Timestamp) {
      createdAt = createdAtRaw.toDate();
    } else {
      createdAt = DateTime.now();
    }

    final updatedAtRaw = data['updatedAt'];
    DateTime? updatedAt;
    if (updatedAtRaw is Timestamp) {
      updatedAt = updatedAtRaw.toDate();
    }

    final visitDateRaw = data['visitDate'];
    DateTime? visitDate;
    if (visitDateRaw is Timestamp) {
      visitDate = visitDateRaw.toDate();
    }

    final imageUrls =
        (data['imageUrls'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        const [];
    final dishes =
        (data['dishes'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
        const [];

    return Review(
      id: doc.id,
      placeId: (data['placeId'] as String?) ?? '',
      userId: (data['userId'] as String?) ?? '',
      authorName: (data['authorName'] as String?) ?? 'Thành viên',
      rating: (data['rating'] as num?)?.toInt() ?? 5,
      content: (data['content'] as String?) ?? '',
      createdAt: createdAt,
      updatedAt: updatedAt,
      title: data['title'] as String?,
      visitDate: visitDate,
      companion: data['companion'] as String?,
      imageUrls: imageUrls,
      dishes: dishes,
      isDemo: false,
    );
  }
}
