import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_route.dart';
import '../../../shared/design_system/design_system.dart';
import '../../places/presentation/place_providers.dart';
import '../domain/review.dart';
import '../domain/user_review_repository.dart';

class MyReviewSummary extends StatelessWidget {
  const MyReviewSummary({super.key, required this.summary});
  final UserReviewSummary summary;

  @override
  Widget build(BuildContext context) => Card(
    color: context.colors.surfaceContainerLow,
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: context.colors.surface,
              borderRadius: AppRadii.inputBorder,
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                children: [
                  Text(
                    '${summary.total}',
                    style: context.textStyles.headlineMedium?.copyWith(
                      color: context.colors.primary,
                    ),
                  ),
                  Text('Đã đăng', style: context.textStyles.labelSmall),
                ],
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Trải nghiệm của bạn',
                  style: context.textStyles.titleMedium,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Cảm ơn bạn đã chia sẻ trải nghiệm với cộng đồng Food Review.',
                  style: context.textStyles.bodySmall,
                ),
                if (summary.isDemo) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Bản demo · Đánh giá lưu trong phiên',
                    style: context.textStyles.labelSmall?.copyWith(
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class MyReviewCard extends ConsumerWidget {
  const MyReviewCard({
    super.key,
    required this.review,
    required this.busy,
    required this.onEdit,
    required this.onDelete,
    this.isDemo = false,
  });
  final Review review;
  final bool busy, isDemo;
  final VoidCallback onEdit, onDelete;

  void _open(BuildContext context) => context.push(
    AppRoute.restaurant.location(parameters: {'restaurantId': review.placeId}),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final placeState = ref.watch(placeProvider(review.placeId));
    final place = placeState.asData?.value;
    final date = review.createdAt.toLocal();
    return Card(
      shape: const RoundedRectangleBorder(borderRadius: AppRadii.inputBorder),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: AppRadii.inputBorder,
                  child: AppImage(
                    url: place?.imageUrls.firstOrNull,
                    width: 48,
                    height: 48,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: InkWell(
                    onTap: () => _open(context),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.xs,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              place?.name ??
                                  (placeState.isLoading
                                      ? 'Đang tải thông tin quán…'
                                      : placeState.hasError
                                      ? 'Không tải được tên quán'
                                      : 'Quán không còn khả dụng'),
                              style: context.textStyles.titleMedium,
                            ),
                            if (place != null)
                              AppBadge(
                                label: place.category,
                                tone: AppBadgeTone.primary,
                              ),
                          ],
                        ),
                        if (placeState.hasError)
                          TextButton(
                            onPressed: () =>
                                ref.invalidate(placeProvider(review.placeId)),
                            child: const Text('Thử lại thông tin quán'),
                          ),
                        const SizedBox(height: AppSpacing.xs),
                        Wrap(
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.xs,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            AppRating(
                              value: review.rating.toDouble(),
                              showValue: false,
                              showStars: true,
                            ),
                            Text(
                              '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}',
                              style: context.textStyles.labelSmall,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  enabled: !busy,
                  tooltip: 'Tùy chọn đánh giá',
                  onSelected: (value) {
                    if (value == 'edit') onEdit();
                    if (value == 'delete') onDelete();
                    if (value == 'place') _open(context);
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: 'edit',
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.edit_outlined),
                        title: Text('Chỉnh sửa đánh giá'),
                      ),
                    ),
                    PopupMenuItem(
                      value: 'place',
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.storefront_outlined),
                        title: Text('Xem trang quán'),
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
            const SizedBox(height: AppSpacing.sm),
            if (review.title?.isNotEmpty == true) ...[
              Text(review.title!, style: context.textStyles.titleMedium),
              const SizedBox(height: AppSpacing.xs),
            ],
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
                  itemBuilder: (context, index) => Semantics(
                    label: 'Xem ảnh đánh giá ${index + 1}',
                    button: true,
                    child: InkWell(
                      onTap: () => context.push(
                        AppRoute.gallery.location(
                          parameters: {'restaurantId': review.placeId},
                          query: {
                            'source': 'review',
                            'reviewId': review.id,
                            'index': '$index',
                          },
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: AppRadii.inputBorder,
                        child: AppImage(
                          url: review.imageUrls[index],
                          width: 76,
                          height: 76,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
            if (isDemo || review.isDemo || review.updatedAt != null) ...[
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                children: [
                  if (isDemo || review.isDemo)
                    const AppBadge(label: 'Lưu trong phiên'),
                  if (review.updatedAt != null)
                    const AppBadge(
                      label: 'Đã chỉnh sửa',
                      tone: AppBadgeTone.primary,
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class MyReviewsEmpty extends StatelessWidget {
  const MyReviewsEmpty({
    super.key,
    required this.filtered,
    required this.onCreate,
    required this.onReset,
  });
  final bool filtered;
  final VoidCallback onCreate, onReset;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(AppSpacing.xl),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AppEmptyState(
          title: filtered
              ? 'Không có đánh giá phù hợp'
              : 'Bạn chưa có đánh giá nào',
          message: filtered ? 'Thử xem tất cả đánh giá của bạn.' : 'Chia sẻ trải nghiệm ẩm thực để giúp cộng đồng khám phá thêm địa điểm thú vị.',
          icon: Icons.rate_review_outlined,
        ),
        const SizedBox(height: AppSpacing.md),
        AppButton(
          label: filtered ? 'Xem tất cả' : 'Viết đánh giá',
          icon: filtered ? Icons.filter_alt_off_outlined : Icons.edit_outlined,
          expanded: true,
          onPressed: filtered ? onReset : onCreate,
        ),
      ],
    ),
  );
}
