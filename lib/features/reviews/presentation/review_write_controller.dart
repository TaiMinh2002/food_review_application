import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/presentation/auth_providers.dart';
import '../domain/review.dart';
import 'review_providers.dart';

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
    final reference = ref;
    state = const AsyncLoading();
    final review = Review(
      id: 'review-${user.id}-${DateTime.now().microsecondsSinceEpoch}',
      placeId: placeId,
      userId: user.id,
      authorName: user.displayName,
      rating: rating,
      title: title?.trim().isEmpty == true ? null : title?.trim(),
      content: content.trim(),
      createdAt: DateTime.now(),
      visitDate: visitDate,
      companion: companion,
      imageUrls: imageUrls,
    );
    final result = await AsyncValue.guard(() => repository.create(review));
    if (reference.mounted) state = result;
  }
}
