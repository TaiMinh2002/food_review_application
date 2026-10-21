import 'dart:convert';

import '../../../core/errors/app_exception.dart';
import '../../places/domain/place_repository.dart';
import '../../profile/domain/public_reviewer_repository.dart';
import '../../reviews/domain/review_repository.dart';
import '../domain/report_repository.dart';

/// Reports and evidence stay local to this process. Nothing is uploaded or
/// delivered to moderators. Replace this adapter with an authenticated backend.
class DemoReportRepository implements ReportRepository {
  DemoReportRepository({required this.places, required this.reviews});
  final PlaceRepository places;
  final ReviewRepository reviews;
  final _records =
      <
        (String, String),
        ({String fingerprint, ReportReceipt receipt, ReportDraft draft})
      >{};
  @override
  bool get isDemo => true;

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
    switch (target.type) {
      case ReportTargetType.place:
        final place = await places.getPlace(target.id);
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
            review.placeId != target.placeId ||
            (!review.isDemo && review.userId != reporterId)) {
          return null;
        }
        final place = await places.getPlace(target.placeId!);
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
    if (reporterId.trim().isEmpty || requestId.trim().isEmpty) {
      throw const AppException('Vui lòng đăng nhập và mở lại form báo cáo.');
    }
    final error = draft.validationError;
    if (error != null) throw AppException(error);
    final fingerprint = jsonEncode([
      draft.target.type.name,
      draft.target.id,
      draft.target.placeId,
      draft.reason.name,
      draft.description,
      for (final photo in draft.evidence)
        [photo.name, base64Encode(photo.bytes)],
    ]);
    final key = (reporterId, requestId);
    ReportReceipt? previous() {
      final saved = _records[key];
      if (saved == null) return null;
      if (saved.fingerprint != fingerprint) {
        throw const AppException(
          'Báo cáo đã được lưu với nội dung trước đó. Vui lòng đóng form.',
        );
      }
      return saved.receipt;
    }

    final existing = previous();
    if (existing != null) return existing;
    if (await getTarget(draft.target, reporterId: reporterId) == null) {
      throw const AppException('Nội dung không còn khả dụng để báo cáo.');
    }
    final concurrent = previous();
    if (concurrent != null) return concurrent;
    final receipt = ReportReceipt(
      id: 'demo-report-${_records.length + 1}',
      isDemo: true,
    );
    _records[key] = (fingerprint: fingerprint, receipt: receipt, draft: draft);
    return receipt;
  }
}
