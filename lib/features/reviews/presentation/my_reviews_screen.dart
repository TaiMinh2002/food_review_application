import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_error_message.dart';
import '../../../core/router/app_route.dart';
import '../../../core/router/route_placeholder_screen.dart';
import '../../../shared/design_system/design_system.dart';
import '../../auth/presentation/auth_gate.dart';
import '../../auth/presentation/auth_providers.dart';
import '../domain/review.dart';
import '../domain/user_review_repository.dart';
import 'my_reviews_controller.dart';
import 'my_review_widgets.dart';
import 'review_management_controller.dart';
import 'review_place_picker.dart';

class MyReviewsScreen extends ConsumerWidget {
  const MyReviewsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authSessionProvider);
    final user = session.asData?.value;
    if (session.isLoading || session.hasError || user == null) {
      return const Scaffold(
        body: SafeArea(
          child: AuthGate(returnTo: '/my-reviews', child: SizedBox.shrink()),
        ),
      );
    }
    final state = ref.watch(myReviewsControllerProvider);
    final controller = ref.read(myReviewsControllerProvider.notifier);
    final operation = ref.watch(
      reviewManagementControllerProvider('my-reviews-${user.id}'),
    );
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 80 * MediaQuery.textScalerOf(context).scale(14) / 14,
        leading: const RouteBackButton(),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Đánh giá của tôi', style: context.textStyles.titleMedium),
            Text(
              'Những trải nghiệm bạn đã chia sẻ',
              style: context.textStyles.bodySmall,
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Tạo đánh giá mới',
            onPressed: () => _createReview(context),
            icon: const Icon(Icons.rate_review_outlined),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: RefreshIndicator(
              onRefresh: controller.refresh,
              child: ListView.builder(
                key: PageStorageKey('my-reviews-${user.id}'),
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.margin,
                  AppSpacing.md,
                  AppSpacing.margin,
                  AppSpacing.xxl,
                ),
                itemCount: state.items.length + 2,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    final summary = state.summary.asData?.value;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        state.summary.when(
                          data: (summary) => MyReviewSummary(summary: summary),
                          loading: () => const AppSkeleton(height: 100),
                          error: (error, _) => AppErrorState(
                            message: AppErrorMessage.from(
                              error,
                              fallback: 'Không tải được thống kê đánh giá.',
                            ),
                            onRetry: controller.refresh,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Wrap(
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.sm,
                          children: [
                            for (final filter in UserReviewFilter.values)
                              AppChip(
                                label: _filterLabel(filter, summary),
                                selected: state.filter == filter,
                                onSelected: (_) => controller.apply(filter),
                              ),
                          ],
                        ),
                        if (state.refreshing)
                          const LinearProgressIndicator(
                            semanticsLabel: 'Đang cập nhật đánh giá',
                          ),
                        if (state.error != null)
                          AppErrorState(
                            message: state.error!,
                            onRetry: controller.refresh,
                          ),
                        if (operation.hasError)
                          Padding(
                            padding: const EdgeInsets.only(top: AppSpacing.md),
                            child: Text(
                              AppErrorMessage.from(
                                operation.error!,
                                fallback: 'Không thể xóa đánh giá.',
                              ),
                              style: context.textStyles.bodyMedium?.copyWith(
                                color: context.colors.error,
                              ),
                            ),
                          ),
                        const SizedBox(height: AppSpacing.md),
                      ],
                    );
                  }
                  if (index <= state.items.length) {
                    final review = state.items[index - 1];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: MyReviewCard(
                        key: ValueKey((review.placeId, review.id)),
                        review: review,
                        busy: operation.isLoading,
                        isDemo: state.isDemo,
                        onEdit: () => context.push(
                          AppRoute.editReview.location(
                            parameters: {'reviewId': review.id},
                            query: {'restaurantId': review.placeId},
                          ),
                        ),
                        onDelete: () =>
                            _confirmDelete(context, ref, review, user.id),
                      ),
                    );
                  }
                  if (state.loading) {
                    return const Center(
                      child: CircularProgressIndicator(
                        semanticsLabel: 'Đang tải đánh giá của bạn',
                      ),
                    );
                  }
                  if (state.error != null && state.items.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  if (state.items.isEmpty) {
                    return MyReviewsEmpty(
                      filtered: state.filter != UserReviewFilter.all,
                      onCreate: () => _createReview(context),
                      onReset: () => controller.apply(UserReviewFilter.all),
                    );
                  }
                  return Column(
                    children: [
                      if (state.pageError != null)
                        Text(
                          state.pageError!,
                          style: context.textStyles.bodySmall?.copyWith(
                            color: context.colors.error,
                          ),
                        ),
                      if (state.pageError != null)
                        TextButton(
                          onPressed: controller.refresh,
                          child: const Text('Tải lại danh sách'),
                        ),
                      if (state.nextCursor != null)
                        AppButton(
                          label: state.pageError != null
                              ? 'Thử tải thêm'
                              : 'Tải thêm đánh giá',
                          isLoading: state.loadingMore,
                          variant: AppButtonVariant.outline,
                          onPressed: state.loadingMore || state.refreshing
                              ? null
                              : controller.loadMore,
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _filterLabel(UserReviewFilter filter, UserReviewSummary? summary) {
    final (label, count) = switch (filter) {
      UserReviewFilter.all => ('Tất cả', summary?.total),
      UserReviewFilter.withPhotos => ('Có ảnh', summary?.withPhotos),
      UserReviewFilter.edited => ('Đã chỉnh sửa', summary?.edited),
    };
    return count == null ? label : '$label ($count)';
  }

  Future<void> _createReview(BuildContext context) async {
    final id = await pickReviewPlace(context);
    if (id == null || !context.mounted) return;
    context.push(
      AppRoute.createReview.location(parameters: {'restaurantId': id}),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Review review,
    String userId,
  ) async {
    final confirmed = await showAppConfirmation(
      context,
      title: 'Xóa đánh giá?',
      message: 'Bạn có chắc muốn xóa bài đánh giá này? Thao tác này không thể hoàn tác.',
      confirmLabel: 'Xóa đánh giá',
      cancelLabel: 'Giữ lại',
      destructive: true,
    );
    if (!confirmed ||
        !context.mounted ||
        ref.read(authSessionProvider).asData?.value?.id != userId) {
      return;
    }
    final provider = reviewManagementControllerProvider('my-reviews-$userId');
    await ref
        .read(provider.notifier)
        .delete(placeId: review.placeId, reviewId: review.id);
    if (!context.mounted ||
        ref.read(authSessionProvider).asData?.value?.id != userId) {
      return;
    }
    if (!ref.read(provider).hasError) {
      AppToast.show(context, 'Đã xóa đánh giá.', type: AppFeedbackType.success);
    }
  }
}
