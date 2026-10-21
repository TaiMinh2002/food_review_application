import 'dart:typed_data';

import 'package:characters/characters.dart';

enum ReportTargetType { place, review, user }

typedef ReportTarget = ({ReportTargetType type, String id, String? placeId});

ReportTarget? parseReportTarget(Uri uri) {
  if (uri.queryParametersAll.values.any((values) => values.length != 1)) {
    return null;
  }
  final query = uri.queryParameters;
  final type = query['targetType'];
  final place = query['restaurantId'];
  final review = query['reviewId'];
  final user = query['userId'];
  bool valid(String? value) =>
      value != null &&
      value.trim().isNotEmpty &&
      value.length <= 200 &&
      !RegExp(r'[/\\\x00-\x1f]').hasMatch(value);
  if ((type == 'place' || type == 'restaurant') &&
      valid(place) &&
      review == null &&
      user == null) {
    return (type: ReportTargetType.place, id: place!, placeId: null);
  }
  if (type == 'review' && valid(place) && valid(review) && user == null) {
    return (type: ReportTargetType.review, id: review!, placeId: place);
  }
  if (type == 'user' && valid(user) && place == null && review == null) {
    return (type: ReportTargetType.user, id: user!, placeId: null);
  }
  return null;
}

enum ReportReason {
  inaccurate('Thông tin sai sự thật'),
  harassment('Nội dung xúc phạm hoặc quấy rối'),
  spam('Spam hoặc quảng cáo'),
  inappropriatePhoto('Hình ảnh không phù hợp'),
  fakeReview('Đánh giá giả mạo'),
  other('Lý do khác');

  const ReportReason(this.label);
  final String label;
}

class ReportContext {
  const ReportContext({
    required this.target,
    required this.title,
    this.subtitle,
    this.excerpt,
    this.imageUrl,
    this.authorName,
  });
  final ReportTarget target;
  final String title;
  final String? subtitle, excerpt, imageUrl, authorName;
}

class ReportEvidence {
  ReportEvidence({required Uint8List bytes, required this.name})
    : bytes = Uint8List.fromList(bytes).asUnmodifiableView();
  final Uint8List bytes;
  final String name;
}

String? validateReportEvidence(ReportEvidence photo) {
  final bytes = photo.bytes;
  if (bytes.isEmpty || bytes.length > 5 * 1024 * 1024) {
    return 'Mỗi ảnh cần có dung lượng từ 1 byte đến 5 MB.';
  }
  final jpeg =
      bytes.length >= 3 &&
      bytes[0] == 255 &&
      bytes[1] == 216 &&
      bytes[2] == 255;
  const signature = [137, 80, 78, 71, 13, 10, 26, 10];
  final png =
      bytes.length >= signature.length &&
      signature.asMap().entries.every(
        (entry) => bytes[entry.key] == entry.value,
      );
  return jpeg || png ? null : 'Vui lòng chọn ảnh định dạng JPG hoặc PNG.';
}

class ReportDraft {
  ReportDraft({
    required this.target,
    required this.reason,
    required String description,
    List<ReportEvidence> evidence = const [],
  }) : description = description.trim(),
       evidence = List.unmodifiable(evidence);
  final ReportTarget target;
  final ReportReason reason;
  final String description;
  final List<ReportEvidence> evidence;
  String? get validationError {
    if (description.characters.length > 500) return 'Mô tả tối đa 500 ký tự.';
    if (evidence.length > 3) return 'Chỉ được đính kèm tối đa 3 ảnh.';
    for (final photo in evidence) {
      final error = validateReportEvidence(photo);
      if (error != null) return error;
    }
    return null;
  }
}

class ReportReceipt {
  const ReportReceipt({required this.id, required this.isDemo});
  final String id;
  final bool isDemo;
}

abstract interface class ReportRepository {
  bool get isDemo;
  Future<ReportContext?> getTarget(
    ReportTarget target, {
    required String reporterId,
  });

  /// Implementations authenticate the reporter and enforce reporter ownership
  /// and idempotency server-side. Evidence must use restricted/private storage.
  Future<ReportReceipt> submit({
    required String reporterId,
    required String requestId,
    required ReportDraft draft,
  });
}
