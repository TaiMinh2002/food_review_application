import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_route.dart';
import '../../../shared/design_system/design_system.dart';
import '../../places/presentation/place_providers.dart';
import '../../reviews/domain/review.dart';
import '../domain/public_reviewer_repository.dart';

class PublicReviewerHeader extends StatelessWidget {
  const PublicReviewerHeader({
    super.key,
    required this.profile,
    required this.options,
  });
  final PublicReviewer profile;
  final Widget options;

  @override
  Widget build(BuildContext context) => Container(
    padding: AppSpacing.page,
    decoration: BoxDecoration(
      color: context.colors.surface,
      borderRadius: AppRadii.cardBorder,
    ),
    child: Column(
      children: [
        AppAvatar(
          name: profile.name,
          imageUrl: profile.photoUrl,
          size: AppAvatarSize.reviewer,
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          profile.name,
          style: context.textStyles.headlineMedium,
          textAlign: TextAlign.center,
        ),
        if (profile.handle != null)
          Text(
            profile.handle!,
            style: context.textStyles.labelMedium?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
        if (profile.region != null) ...[
          const SizedBox(height: AppSpacing.sm),
          AppBadge(label: profile.region!, icon: Icons.location_on_outlined),
        ],
        if (profile.bio != null) ...[
          const SizedBox(height: AppSpacing.md),
          Text(
            profile.bio!,
            textAlign: TextAlign.center,
            style: context.textStyles.bodyMedium?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
        ],
        if (profile.isDemo) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Hồ sơ và số liệu minh họa',
            style: context.textStyles.bodySmall?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        Align(alignment: Alignment.centerRight, child: options),
      ],
    ),
  );
}

class PublicReviewerStats extends StatelessWidget {
  const PublicReviewerStats({super.key, required this.profile});
  final PublicReviewer profile;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.lg),
    decoration: BoxDecoration(
      color: context.colors.surface,
      borderRadius: AppRadii.cardBorder,
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stat(context, '${profile.reviewCount}', 'Đánh giá'),
        _stat(context, '${profile.photoReviewCount}', 'Có ảnh', shaded: true),
        _stat(
          context,
          profile.averageRating?.toStringAsFixed(1) ?? '—',
          'Điểm TB',
          accent: true,
        ),
      ],
    ),
  );

  Widget _stat(
    BuildContext context,
    String value,
    String label, {
    bool shaded = false,
    bool accent = false,
  }) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.sm,
        horizontal: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: shaded ? context.colors.surfaceContainerLow : null,
        borderRadius: AppRadii.inputBorder,
      ),
      child: Column(
        children: [
          Text(
            value,
            style: context.textStyles.headlineMedium?.copyWith(
              color: accent ? context.colors.secondary : context.colors.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            label,
            textAlign: TextAlign.center,
            style: context.textStyles.bodySmall?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    ),
  );
}

class PublicReviewerReviewCard extends ConsumerWidget {
  const PublicReviewerReviewCard({
    super.key,
    required this.review,
    this.featured = false,
  });
  final Review review;
  final bool featured;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final placeState = ref.watch(placeProvider(review.placeId));
    final place = placeState.asData?.value;
    final date = review.createdAt.toLocal();
    // Keep the Stitch heading/rating row on regular phones; larger text or
    // compact widths place the stars below to keep names fully readable.
    final inlineStars =
        MediaQuery.sizeOf(context).width >= 390 &&
        MediaQuery.textScalerOf(context).scale(14) <= 16;
    void gallery(int index) => context.push(
      AppRoute.gallery.location(
        parameters: {'restaurantId': review.placeId},
        query: {'source': 'review', 'reviewId': review.id, 'index': '$index'},
      ),
    );
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: AppRadii.cardBorder,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            key: ValueKey(
              'public-place-${review.id}${featured ? '-featured' : ''}',
            ),
            borderRadius: AppRadii.inputBorder,
            onTap: place == null
                ? null
                : () => context.push(
                    AppRoute.restaurant.location(
                      parameters: {'restaurantId': review.placeId},
                    ),
                  ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (featured) ...[
                    ClipRRect(
                      borderRadius: AppRadii.inputBorder,
                      child: AppImage(
                        url: place?.imageUrls.firstOrNull,
                        width: 48,
                        height: 48,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          place?.name ??
                              (placeState.isLoading
                                  ? 'Đang tải thông tin quán…'
                                  : placeState.hasError
                                  ? 'Không tải được thông tin quán'
                                  : 'Quán không còn khả dụng'),
                          style: context.textStyles.titleMedium,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          '${place == null ? '' : '${place.category} • '}${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}',
                          style: context.textStyles.bodySmall?.copyWith(
                            color: context.colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (inlineStars) ...[
                    const SizedBox(width: AppSpacing.sm),
                    AppRating(
                      value: review.rating.toDouble(),
                      showValue: false,
                      showStars: true,
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (placeState.hasError)
            TextButton(
              onPressed: () => ref.invalidate(placeProvider(review.placeId)),
              child: const Text('Thử lại thông tin quán'),
            ),
          if (!inlineStars) ...[
            const SizedBox(height: AppSpacing.sm),
            AppRating(
              value: review.rating.toDouble(),
              showValue: false,
              showStars: true,
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          Text(review.content, style: context.textStyles.bodyMedium),
          if (review.imageUrls.isNotEmpty && place != null) ...[
            const SizedBox(height: AppSpacing.lg),
            if (featured || review.imageUrls.length > 1)
              SizedBox(
                height: 72,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: review.imageUrls.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(width: AppSpacing.sm),
                  itemBuilder: (_, index) => Semantics(
                    button: true,
                    label: 'Xem ảnh ${index + 1}',
                    child: InkWell(
                      onTap: () => gallery(index),
                      child: ClipRRect(
                        borderRadius: AppRadii.inputBorder,
                        child: AppImage(
                          url: review.imageUrls[index],
                          width: 72,
                          height: 72,
                        ),
                      ),
                    ),
                  ),
                ),
              )
            else
              Semantics(
                button: true,
                label: 'Xem ảnh đánh giá',
                child: InkWell(
                  onTap: () => gallery(0),
                  child: ClipRRect(
                    borderRadius: AppRadii.inputBorder,
                    child: AspectRatio(
                      aspectRatio: 2.3,
                      child: AppImage(url: review.imageUrls.first),
                    ),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
