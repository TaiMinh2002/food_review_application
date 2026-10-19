import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_error_message.dart';
import '../../../core/router/app_route.dart';
import '../../../core/router/route_placeholder_screen.dart';
import '../../../shared/design_system/design_system.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../places/presentation/place_providers.dart';
import '../domain/review.dart';
import 'review_management_controller.dart';
import 'review_providers.dart';

class MyReviewsScreen extends ConsumerWidget {
  const MyReviewsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authSessionProvider);
    final reviews = ref.watch(myReviewsProvider);
    final operation = ref.watch(
      reviewManagementControllerProvider('my-reviews'),
    );
    final user = session.asData?.value;
    if (session.isLoading) {
      return const Scaffold(
        body: Center(child: Text('Đang kiểm tra phiên...')),
      );
    }
    if (session.hasError) {
      return Scaffold(
        body: SafeArea(
          child: AppErrorState(
            message: AppErrorMessage.from(
              session.error!,
              fallback: 'Không kiểm tra được phiên đăng nhập.',
            ),
            onRetry: () => ref.invalidate(authSessionProvider),
          ),
        ),
      );
    }
    if (user == null && !session.isLoading) {
      return const Scaffold(
        body: SafeArea(
          child: AppEmptyState(
            title: 'Đăng nhập để xem đánh giá',
            message: 'Nội dung bạn đã chia sẻ sẽ được hiển thị tại đây.',
            icon: Icons.rate_review_outlined,
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        leading: const RouteBackButton(),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Đánh giá của tôi'),
            Text('Những trải nghiệm bạn đã chia sẻ'),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Tạo đánh giá mới',
            onPressed: () => _createReview(context, ref),
            icon: const Icon(Icons.rate_review_outlined),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: reviews.when(
          loading: () => const Center(
            child: CircularProgressIndicator(
              semanticsLabel: 'Đang tải đánh giá của bạn',
            ),
          ),
          error: (error, _) => AppErrorState(
            message: AppErrorMessage.from(
              error,
              fallback: 'Không tải được đánh giá của bạn.',
            ),
            onRetry: () => ref.invalidate(myReviewsProvider),
          ),
          data: (items) => items.isEmpty
              ? _EmptyReviews(onCreate: () => _createReview(context, ref))
              : RefreshIndicator(
                  onRefresh: () async => ref.invalidate(myReviewsProvider),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.margin,
                      AppSpacing.md,
                      AppSpacing.margin,
                      AppSpacing.xxl,
                    ),
                    children: [
                      _ReviewSummary(total: items.length),
                      const SizedBox(height: AppSpacing.md),
                      for (final review in items) ...[
                        _MyReviewCard(
                          review: review,
                          busy: operation.isLoading,
                          onEdit: () => _editReview(context, review),
                          onDelete: () => _confirmDelete(context, ref, review),
                        ),
                        const SizedBox(height: AppSpacing.md),
                      ],
                      if (operation.hasError)
                        Text(
                          AppErrorMessage.from(
                            operation.error!,
                            fallback: 'Không thể xóa đánh giá.',
                          ),
                          style: context.textStyles.bodyMedium?.copyWith(
                            color: context.colors.error,
                          ),
                        ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  void _createReview(BuildContext context, WidgetRef ref) {
    final placeId = ref.read(placesProvider).asData?.value.firstOrNull?.id;
    if (placeId == null) {
      AppToast.show(context, 'Chưa có quán để tạo đánh giá.');
      return;
    }
    context.push(
      AppRoute.createReview.location(parameters: {'restaurantId': placeId}),
    );
  }

  void _editReview(BuildContext context, Review review) {
    context.push(
      AppRoute.editReview.location(
        parameters: {'reviewId': review.id},
        query: {'restaurantId': review.placeId},
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Review review,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(Icons.delete_forever, color: context.colors.error),
        title: const Text('Xóa đánh giá?'),
        content: Text(
          'Bạn có chắc muốn xóa bài đánh giá cho quán này? Thao tác này không thể hoàn tác.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: context.colors.error,
              foregroundColor: context.colors.onError,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa đánh giá'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await ref
        .read(reviewManagementControllerProvider('my-reviews').notifier)
        .delete(placeId: review.placeId, reviewId: review.id);
    if (!context.mounted) return;
    if (!ref.read(reviewManagementControllerProvider('my-reviews')).hasError) {
      ref.invalidate(myReviewsProvider);
      AppToast.show(context, 'Đã xóa đánh giá.', type: AppFeedbackType.success);
    }
  }
}

class _ReviewSummary extends StatelessWidget {
  const _ReviewSummary({required this.total});
  final int total;
  @override
  Widget build(BuildContext context) => Card(
    color: context.colors.primaryContainer,
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          Icon(Icons.rate_review, color: context.colors.onPrimaryContainer),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              '$total bài đánh giá đã đăng',
              style: context.textStyles.titleMedium?.copyWith(
                color: context.colors.onPrimaryContainer,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _EmptyReviews extends StatelessWidget {
  const _EmptyReviews({required this.onCreate});
  final VoidCallback onCreate;
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(AppSpacing.xl),
    children: [
      const SizedBox(height: 80),
      const AppEmptyState(
        title: 'Bạn chưa có đánh giá nào',
        message: 'Chia sẻ trải nghiệm đầu tiên của bạn với cộng đồng.',
        icon: Icons.rate_review_outlined,
      ),
      const SizedBox(height: AppSpacing.md),
      AppButton(
        label: 'Viết đánh giá',
        icon: Icons.edit_outlined,
        expanded: true,
        onPressed: onCreate,
      ),
    ],
  );
}

class _MyReviewCard extends StatelessWidget {
  const _MyReviewCard({
    required this.review,
    required this.busy,
    required this.onEdit,
    required this.onDelete,
  });
  final Review review;
  final bool busy;
  final VoidCallback onEdit, onDelete;
  @override
  Widget build(BuildContext context) {
    final date = review.createdAt.toLocal();
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    review.title?.isNotEmpty == true
                        ? review.title!
                        : 'Đánh giá quán',
                    style: context.textStyles.titleMedium,
                  ),
                ),
                PopupMenuButton<String>(
                  enabled: !busy,
                  tooltip: 'Tùy chọn đánh giá',
                  onSelected: (value) {
                    if (value == 'edit') onEdit();
                    if (value == 'delete') onDelete();
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: 'edit',
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.edit_outlined),
                        title: Text('Chỉnh sửa đánh giá'),
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.delete_outline),
                        title: Text('Xóa đánh giá'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}',
              style: context.textStyles.bodySmall?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            AppRating(value: review.rating.toDouble(), showValue: false),
            const SizedBox(height: AppSpacing.sm),
            Text(review.content, style: context.textStyles.bodyMedium),
            if (review.imageUrls.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                height: 76,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: review.imageUrls.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(width: AppSpacing.sm),
                  itemBuilder: (context, index) => ClipRRect(
                    borderRadius: AppRadii.inputBorder,
                    child: AppImage(
                      url: review.imageUrls[index],
                      width: 76,
                      height: 76,
                      semanticLabel: 'Ảnh đánh giá ${index + 1}',
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: 16,
                  color: context.semanticColors.success,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  'Đã lưu trong phiên',
                  style: context.textStyles.labelSmall,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
