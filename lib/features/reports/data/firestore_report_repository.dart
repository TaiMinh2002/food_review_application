import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/errors/app_exception.dart';
import '../../places/domain/place_repository.dart';
import '../../places/data/osm_region_place_repository.dart';
import '../../profile/domain/public_reviewer_repository.dart';
import '../../reviews/domain/review_repository.dart';
import '../domain/report_repository.dart';

/// Real Firestore-backed report repository.
/// Stores private receipts at `reports/{reporterId}/submissions/{requestId}`
/// and evidence in `reports/{reporterId}/submissions/{requestId}/evidence/{evidenceId}`.
class FirestoreReportRepository implements ReportRepository {
  FirestoreReportRepository(
    this._firestore, {
    required this.places,
    required this.reviews,
    this.osmPlaces,
    this.getTargetHook,
    this.submitHook,
  });

  final FirebaseFirestore? _firestore;
  final PlaceRepository places;
  final ReviewRepository reviews;
  final OsmRegionPlaceRepository? osmPlaces;

  final Future<ReportContext?> Function(ReportTarget target, String reporterId)?
  getTargetHook;

  final Future<ReportReceipt> Function(
    String reporterId,
    String requestId,
    ReportDraft draft,
  )?
  submitHook;

  @override
  bool get isDemo => false;

  @override
  Future<ReportContext?> getTarget(
    ReportTarget target, {
    required String reporterId,
  }) async {
    if (reporterId.trim().isEmpty ||
        target.id.trim().isEmpty ||
        (target.type == ReportTargetType.review &&
            (target.placeId == null || target.placeId!.trim().isEmpty))) {
      return null;
    }

    if (getTargetHook != null) {
      return getTargetHook!(target, reporterId);
    }

    switch (target.type) {
      case ReportTargetType.place:
        var place = await places.getPlace(target.id);
        if (place == null && osmPlaces != null) {
          place = await osmPlaces!.getById(target.id);
        }
        if (place == null) return null;
        return ReportContext(
          target: target,
          title: place.name,
          subtitle: '${place.category} • ${place.address}',
          imageUrl: place.imageUrls.firstOrNull,
        );

      case ReportTargetType.review:
        if (reviews is! ReviewMediaRepository) {
          throw const AppException(
            'Nguồn dữ liệu chưa hỗ trợ đọc nội dung đánh giá.',
          );
        }
        final review = await (reviews as ReviewMediaRepository).getReview(
          target.placeId!,
          target.id,
        );
        if (review == null ||
            review.id != target.id ||
            review.placeId != target.placeId) {
          return null;
        }
        var place = await places.getPlace(target.placeId!);
        if (place == null && osmPlaces != null) {
          place = await osmPlaces!.getById(target.placeId!);
        }
        if (place == null) return null;
        return ReportContext(
          target: target,
          title: place.name,
          subtitle: place.category,
          authorName: review.authorName,
          excerpt: review.content,
          imageUrl: place.imageUrls.firstOrNull,
        );

      case ReportTargetType.user:
        if (reviews is! PublicReviewerRepository) {
          throw const AppException(
            'Nguồn dữ liệu chưa hỗ trợ hồ sơ công khai.',
          );
        }
        final user = await (reviews as PublicReviewerRepository)
            .getPublicReviewer(target.id);
        if (user == null || user.id != target.id) return null;
        return ReportContext(
          target: target,
          title: user.name,
          subtitle: user.handle,
          imageUrl: user.photoUrl,
          excerpt: user.bio,
        );
    }
  }

  @override
  Future<ReportReceipt> submit({
    required String reporterId,
    required String requestId,
    required ReportDraft draft,
  }) async {
    final reporter = reporterId.trim();
    final request = requestId.trim();
    if (reporter.isEmpty || request.isEmpty) {
      throw const AppException('Vui lòng đăng nhập và mở lại form báo cáo.');
    }

    final error = draft.validationError;
    if (error != null) throw AppException(error);

    if (submitHook != null) {
      return submitHook!(reporter, request, draft);
    }

    final targetContext = await getTarget(draft.target, reporterId: reporter);
    if (targetContext == null) {
      throw const AppException('Nội dung không còn khả dụng để báo cáo.');
    }

    final docRef = _firestore!
        .collection('reports')
        .doc(reporter)
        .collection('submissions')
        .doc(request);

    try {
      final existing = await docRef.get();
      if (existing.exists) {
        final data = existing.data() ?? {};
        if (data['targetType'] == draft.target.type.name &&
            data['targetId'] == draft.target.id &&
            data['reason'] == draft.reason.name &&
            data['description'] == draft.description &&
            data['evidenceCount'] == draft.evidence.length) {
          return ReportReceipt(id: request, isDemo: false);
        }
        throw const AppException(
          'Báo cáo đã được lưu với nội dung trước đó. Vui lòng đóng form.',
        );
      }

      await docRef.set({
        'targetType': draft.target.type.name,
        'targetId': draft.target.id,
        if (draft.target.placeId != null) 'placeId': draft.target.placeId,
        'reason': draft.reason.name,
        'description': draft.description,
        'evidenceCount': draft.evidence.length,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      for (var i = 0; i < draft.evidence.length; i++) {
        final photo = draft.evidence[i];
        final evidenceDoc = docRef.collection('evidence').doc('photo_$i');
        await evidenceDoc.set({
          'name': photo.name,
          'bytes': photo.bytes,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      return ReportReceipt(id: request, isDemo: false);
    } on AppException {
      rethrow;
    } on FirebaseException catch (e) {
      throw AppException(
        e.code == 'permission-denied'
            ? 'Bạn không có quyền gửi báo cáo này.'
            : 'Không thể gửi báo cáo lúc này. Vui lòng thử lại sau.',
        code: e.code,
      );
    } catch (_) {
      throw const AppException(
        'Không thể gửi báo cáo lúc này. Vui lòng thử lại sau.',
      );
    }
  }
}
