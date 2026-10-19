import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/presentation/auth_providers.dart';
import '../domain/review_repository.dart';
import 'review_providers.dart';

final reviewManagementControllerProvider = NotifierProvider.autoDispose
    .family<ReviewManagementController, AsyncValue<void>, String>(
      ReviewManagementController.new,
    );

class ReviewManagementController extends Notifier<AsyncValue<void>> {
  ReviewManagementController(this.scope);
  final String scope;

  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<void> delete({
    required String placeId,
    required String reviewId,
  }) async {
    if (state.isLoading) return;
    final user = ref.read(authSessionProvider).asData?.value;
    final repository = ref.read(reviewRepositoryProvider);
    if (user == null) {
      state = AsyncError(
        StateError('Vui lòng đăng nhập để xóa đánh giá.'),
        StackTrace.current,
      );
      return;
    }
    if (repository is! ReviewManagementRepository) {
      state = AsyncError(
        StateError('Nguồn dữ liệu hiện tại chưa hỗ trợ xóa đánh giá.'),
        StackTrace.current,
      );
      return;
    }
    final management = repository as ReviewManagementRepository;
    final reference = ref;
    state = const AsyncLoading();
    final result = await AsyncValue.guard(
      () => management.delete(
        userId: user.id,
        placeId: placeId,
        reviewId: reviewId,
      ),
    );
    if (reference.mounted) state = result;
  }
}
