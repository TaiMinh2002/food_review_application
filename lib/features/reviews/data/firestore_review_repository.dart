import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/errors/app_exception.dart';
import '../domain/review.dart';
import '../domain/review_repository.dart';

class FirestoreReviewRepository
    implements
        ReviewRepository,
        ReviewManagementRepository,
        ReviewMediaRepository {
  FirestoreReviewRepository(
    this._firestore, {
    this.saveReview,
    this.updateReviewHook,
    this.deleteReviewHook,
    this.watchPlaceHook,
    this.getReviewHook,
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
      return saveReview!(review);
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
      return updateReviewHook!(review);
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
      return deleteReviewHook!(userId, placeId, reviewId);
    }

    final docRef = _reviewsCollection(placeId).doc(reviewId);
    try {
      await docRef.delete();
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
