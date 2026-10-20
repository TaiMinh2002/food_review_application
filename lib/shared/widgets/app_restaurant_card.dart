import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';
import 'app_button.dart';
import 'app_chip.dart';
import 'app_image.dart';
import 'app_rating.dart';

/// Presentation-only: does not depend on repositories, routing, or Place.
class AppRestaurantCard extends StatelessWidget {
  const AppRestaurantCard({
    super.key,
    required this.name,
    required this.category,
    this.imageUrl,
    this.address,
    this.priceLabel,
    this.distanceLabel,
    this.rating = 0,
    this.reviewCount = 0,
    this.isFavorite = false,
    this.favoriteIcon = Icons.favorite,
    this.favoriteBorderIcon = Icons.favorite_border,
    this.favoriteLabel,
    this.isOpen,
    this.badge,
    this.onTap,
    this.onFavorite,
    this.compact = false,
    this.imageAspectRatio = 16 / 9,
    this.insetImage = false,
  });
  final String name, category;
  final String? imageUrl, address, priceLabel, distanceLabel, badge;
  final double rating, imageAspectRatio;
  final int reviewCount;
  final bool isFavorite, compact, insetImage;
  final IconData favoriteIcon, favoriteBorderIcon;
  final String? favoriteLabel;
  final bool? isOpen;
  final VoidCallback? onTap, onFavorite;

  @override
  Widget build(BuildContext context) {
    final details = insetImage
        ? _insetDetails(context)
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (compact)
                Text(
                  name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: context.textStyles.titleMedium,
                )
              else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: context.textStyles.headlineSmall,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (reviewCount > 0) AppRating(value: rating),
                  ],
                ),
              const SizedBox(height: 4),
              Text(
                compact || reviewCount == 0
                    ? category
                    : '$category · $reviewCount đánh giá',
                style: context.textStyles.bodySmall?.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              if (compact && reviewCount > 0)
                AppRating(value: rating, count: reviewCount)
              else if (reviewCount == 0)
                Text('Chưa có đánh giá', style: context.textStyles.bodySmall),
              if (priceLabel != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    priceLabel!,
                    style:
                        (compact
                                ? context.textStyles.bodySmall
                                : context.textStyles.labelLarge)
                            ?.copyWith(
                              color: context.colors.secondary,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                  ),
                ),
              if (address != null || distanceLabel != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    [distanceLabel, address].whereType<String>().join(' • '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.textStyles.bodySmall?.copyWith(
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
                ),
              if (isOpen != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: AppBadge(
                    label: isOpen! ? 'Mở cửa' : 'Đóng cửa',
                    tone: isOpen! ? AppBadgeTone.success : AppBadgeTone.neutral,
                  ),
                ),
            ],
          );
    final favorite = onFavorite == null
        ? null
        : AppIconButton(
            icon: isFavorite ? favoriteIcon : favoriteBorderIcon,
            tooltip:
                favoriteLabel ??
                (isFavorite ? 'Bỏ yêu thích' : 'Lưu yêu thích'),
            onPressed: onFavorite,
            selected: isFavorite,
            circular: true,
          );
    return Card(
      shape: insetImage
          ? const RoundedRectangleBorder(borderRadius: AppRadii.inputBorder)
          : null,
      child: InkWell(
        onTap: onTap,
        child: compact
            ? Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: AppRadii.inputBorder,
                      child: AppImage(
                        url: imageUrl,
                        width: 88,
                        height: 88,
                        semanticLabel: name,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: details),
                    ?favorite,
                  ],
                ),
              )
            : Padding(
                padding: insetImage
                    ? const EdgeInsets.all(12)
                    : EdgeInsets.zero,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: insetImage
                              ? BorderRadius.circular(AppRadii.small)
                              : BorderRadius.zero,
                          child: AspectRatio(
                            aspectRatio: imageAspectRatio,
                            child: AppImage(url: imageUrl, semanticLabel: name),
                          ),
                        ),
                        if (badge != null)
                          Positioned(
                            top: 12,
                            left: 12,
                            child: AppBadge(
                              label: badge!,
                              tone: AppBadgeTone.primary,
                            ),
                          ),
                        if (favorite != null)
                          Positioned(top: 8, right: 8, child: favorite),
                      ],
                    ),
                    Padding(
                      padding: insetImage
                          ? const EdgeInsets.only(top: 8)
                          : const EdgeInsets.all(16),
                      child: details,
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _insetDetails(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SizedBox(
        width: double.infinity,
        child: Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 4,
          children: [
            Text(name, style: context.textStyles.titleMedium),
            AppBadge(label: category),
          ],
        ),
      ),
      const SizedBox(height: 6),
      if (reviewCount > 0)
        Wrap(
          spacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            AppRating(value: rating),
            Text(
              '· $reviewCount đánh giá',
              style: context.textStyles.labelSmall,
            ),
          ],
        )
      else
        Text('Chưa có đánh giá', style: context.textStyles.labelSmall),
      const SizedBox(height: 8),
      Wrap(
        spacing: 12,
        runSpacing: 4,
        children: [
          if (priceLabel != null)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.payments_outlined,
                  size: 16,
                  color: context.colors.primary,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    priceLabel!,
                    style: context.textStyles.labelSmall?.copyWith(
                      color: context.colors.primary,
                    ),
                  ),
                ),
              ],
            ),
          if (address != null)
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.location_on_outlined,
                  size: 16,
                  color: context.colors.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(address!, style: context.textStyles.labelSmall),
                ),
              ],
            ),
        ],
      ),
    ],
  );
}
