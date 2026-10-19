import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_error_message.dart';
import '../../../core/formatters/app_formatters.dart';
import '../../../core/router/app_route.dart';
import '../../../shared/design_system/design_system.dart';
import '../../reviews/presentation/review_providers.dart';
import '../domain/place.dart';
import 'place_detail_actions.dart';

class PlaceStorySection extends StatelessWidget {
  const PlaceStorySection({super.key, required this.place});
  final Place place;
  @override
  Widget build(BuildContext context) => Padding(
    padding: AppSpacing.page,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionTitle(
          icon: Icons.menu_book_outlined,
          title: 'Câu chuyện hương vị',
        ),
        const SizedBox(height: AppSpacing.md),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  place.description.trim().isEmpty
                      ? 'Chưa có mô tả về quán.'
                      : place.description,
                  style: context.textStyles.bodyMedium?.copyWith(
                    color: context.colors.onSurfaceVariant,
                    height: 1.6,
                  ),
                ),
                if (place.amenities.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  Wrap(
                    spacing: 6,
                    runSpacing: 8,
                    children: [
                      for (final amenity in place.amenities)
                        AppBadge(
                          label: amenity,
                          icon: switch (amenity) {
                            'Ăn tại chỗ' => Icons.table_restaurant_outlined,
                            'Mang về' => Icons.takeout_dining_outlined,
                            'Chuyển khoản / QR' => Icons.qr_code,
                            'Có chỗ để xe' => Icons.two_wheeler_outlined,
                            _ => Icons.check_circle_outline,
                          },
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

class PlaceMenuSection extends StatelessWidget {
  const PlaceMenuSection({super.key, required this.place});
  final Place place;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.margin),
        child: _SectionTitle(
          icon: Icons.local_fire_department_outlined,
          title: 'Món ăn nổi bật',
          onAction: place.menuItems.isEmpty
              ? null
              : () => showPlaceMenu(context, place),
        ),
      ),
      const SizedBox(height: AppSpacing.md),
      if (place.menuItems.isEmpty)
        const Padding(
          padding: AppSpacing.page,
          child: Text('Quán chưa cập nhật thực đơn.'),
        )
      else
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.margin),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final item in place.menuItems.take(4))
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.md),
                  child: SizedBox(
                    width: 220,
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            InkWell(
                              onTap: () => showPlaceDish(
                                context,
                                item,
                                isDemo: place.isDemo,
                              ),
                              child: Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: AppRadii.inputBorder,
                                    child: AppImage(
                                      url: item.imageUrl,
                                      height: 128,
                                      width: 204,
                                      semanticLabel: item.name,
                                    ),
                                  ),
                                  if (item.label != null)
                                    Positioned(
                                      left: 6,
                                      top: 6,
                                      child: AppBadge(
                                        label: item.label!,
                                        tone: AppBadgeTone.accent,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              item.name,
                              style: context.textStyles.titleMedium,
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              item.description,
                              style: context.textStyles.bodySmall?.copyWith(
                                color: context.colors.onSurfaceVariant,
                              ),
                            ),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    AppFormatters.price(item.price),
                                    style: context.textStyles.titleMedium
                                        ?.copyWith(
                                          color: context.colors.primary,
                                        ),
                                  ),
                                ),
                                AppIconButton(
                                  icon: Icons.info_outline,
                                  tooltip: 'Thông tin món ${item.name}',
                                  circular: true,
                                  onPressed: () => showPlaceDish(
                                    context,
                                    item,
                                    isDemo: place.isDemo,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
    ],
  );
}

class PlaceReviewsSection extends ConsumerWidget {
  const PlaceReviewsSection({
    super.key,
    required this.place,
    required this.onWriteReview,
  });
  final Place place;
  final VoidCallback onWriteReview;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final params = {'restaurantId': place.id};
    return Padding(
      padding: AppSpacing.page,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SectionTitle(
            icon: Icons.rate_review_outlined,
            title: 'Đánh giá nổi bật',
            onAction: () =>
                context.push(AppRoute.reviews.location(parameters: params)),
          ),
          const SizedBox(height: AppSpacing.md),
          if (place.reviewCount > 0) ...[
            AppRatingSummary(
              value: place.averageRating,
              count: place.reviewCount,
            ),
            const SizedBox(height: AppSpacing.md),
            ref
                .watch(reviewPreviewProvider(place.id))
                .when(
                  loading: () => const AppSkeleton(height: 180),
                  error: (error, stack) => AppErrorState(
                    message: AppErrorMessage.from(
                      error,
                      fallback: 'Không tải được đánh giá.',
                    ),
                    onRetry: () =>
                        ref.invalidate(reviewPreviewProvider(place.id)),
                  ),
                  data: (reviews) => reviews.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(16),
                          child: Text(
                            'Chưa có nội dung đánh giá để xem trước.',
                          ),
                        )
                      : Column(
                          children: [
                            for (final review in reviews)
                              Padding(
                                padding: const EdgeInsets.only(
                                  bottom: AppSpacing.md,
                                ),
                                child: AppReviewCard(
                                  reviewerName: review.authorName,
                                  content: review.content,
                                  rating: review.rating.toDouble(),
                                  timeLabel: review.isDemo
                                      ? 'Đánh giá minh họa'
                                      : '${review.createdAt.day}/${review.createdAt.month}/${review.createdAt.year}',
                                  imageUrls: review.imageUrls,
                                  onReviewerTap: () => context.push(
                                    AppRoute.reviewer.location(
                                      parameters: {'userId': review.userId},
                                    ),
                                  ),
                                  onMore: () => context.push(
                                    AppRoute.createReport.location(
                                      query: {
                                        'targetType': 'review',
                                        'restaurantId': place.id,
                                        'reviewId': review.id,
                                      },
                                    ),
                                  ),
                                  onImageTap: (index) => context.push(
                                    AppRoute.gallery.location(
                                      parameters: params,
                                      query: {
                                        'index': '$index',
                                        'source': 'review',
                                        'reviewId': review.id,
                                      },
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                ),
          ] else
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Hãy là người đầu tiên chia sẻ cảm nhận về quán.'),
            ),
          const SizedBox(height: AppSpacing.lg),
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: context.colors.secondaryContainer.withValues(alpha: .4),
              borderRadius: AppRadii.cardBorder,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.edit_note, color: context.colors.secondary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Bạn đã từng dùng bữa tại đây?',
                        style: context.textStyles.titleMedium,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Chia sẻ trải nghiệm giúp cộng đồng chọn quán ngon.',
                ),
                const SizedBox(height: 12),
                AppButton(
                  label: 'Viết đánh giá',
                  icon: Icons.edit_outlined,
                  onPressed: onWriteReview,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.title, this.onAction});
  final IconData icon;
  final String title;
  final VoidCallback? onAction;
  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      Icon(icon, size: 20, color: context.colors.primary),
      const SizedBox(width: 6),
      Expanded(
        child: AppSectionHeader(title: title, onAction: onAction),
      ),
    ],
  );
}
