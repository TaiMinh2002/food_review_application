import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/presentation/auth_providers.dart';
import '../domain/review.dart';
import '../domain/review_repository.dart';
import 'review_providers.dart';

typedef NewReviewPhoto = ({Uint8List bytes, String filename});

final reviewWriteControllerProvider = NotifierProvider.autoDispose
    .family<ReviewWriteController, AsyncValue<void>, String>(
      ReviewWriteController.new,
    );

class ReviewWriteController extends Notifier<AsyncValue<void>> {
  ReviewWriteController(this.scope);
  final String scope;

  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<void> submit({
    required String placeId,
    required int rating,
    required String content,
    String? title,
    DateTime? visitDate,
    String? companion,
    List<String> imageUrls = const [],
    List<NewReviewPhoto> newPhotos = const [],
  }) async {
    if (state.isLoading) return;
    final user = ref.read(authSessionProvider).asData?.value;
    if (user == null) {
      state = AsyncError(
        StateError('Vui lòng đăng nhập để viết đánh giá.'),
        StackTrace.current,
      );
      return;
    }
    final repository = ref.read(reviewRepositoryProvider);
    final uploader = ref.read(reviewPhotoUploaderProvider);
    final reference = ref;
    state = const AsyncLoading();

    final result = await AsyncValue.guard(() async {
      final uploadedUrls = <String>[...imageUrls];
      for (final photo in newPhotos) {
        final url = await uploader.uploadPhoto(
          bytes: photo.bytes,
          filename: photo.filename,
        );
        uploadedUrls.add(url);
      }

      final review = Review(
        id: user.id,
        placeId: placeId,
        userId: user.id,
        authorName: user.displayName,
        rating: rating,
        title: title?.trim().isEmpty == true ? null : title?.trim(),
        content: content.trim(),
        createdAt: DateTime.now(),
        visitDate: visitDate,
        companion: companion,
        imageUrls: uploadedUrls,
      );
      await repository.create(review);
    });
    if (reference.mounted) state = result;
  }

  Future<void> updateReview({
    required String placeId,
    required String reviewId,
    required int rating,
    required String content,
    String? title,
    DateTime? visitDate,
    String? companion,
    List<String> imageUrls = const [],
    List<NewReviewPhoto> newPhotos = const [],
    required DateTime createdAt,
  }) async {
    if (state.isLoading) return;
    final user = ref.read(authSessionProvider).asData?.value;
    final repository = ref.read(reviewRepositoryProvider);
    final uploader = ref.read(reviewPhotoUploaderProvider);
    if (user == null) {
      state = AsyncError(
        StateError('Vui lòng đăng nhập để sửa đánh giá.'),
        StackTrace.current,
      );
      return;
    }
    if (repository is! ReviewManagementRepository) {
      state = AsyncError(
        StateError('Nguồn dữ liệu hiện tại chưa hỗ trợ sửa đánh giá.'),
        StackTrace.current,
      );
      return;
    }
    final management = repository as ReviewManagementRepository;
    final reference = ref;
    state = const AsyncLoading();

    final result = await AsyncValue.guard(() async {
      final uploadedUrls = <String>[...imageUrls];
      for (final photo in newPhotos) {
        final url = await uploader.uploadPhoto(
          bytes: photo.bytes,
          filename: photo.filename,
        );
        uploadedUrls.add(url);
      }

      final review = Review(
        id: reviewId,
        placeId: placeId,
        userId: user.id,
        authorName: user.displayName,
        rating: rating,
        title: title?.trim().isEmpty == true ? null : title?.trim(),
        content: content.trim(),
        createdAt: createdAt,
        updatedAt: DateTime.now(),
        visitDate: visitDate,
        companion: companion,
        imageUrls: uploadedUrls,
      );
      await management.update(review);
    });
    if (reference.mounted) state = result;
  }
}
