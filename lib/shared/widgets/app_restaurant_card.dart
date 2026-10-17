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
    this.isOpen,
    this.badge,
    this.onTap,
    this.onFavorite,
    this.compact = false,
  });
  final String name, category;
  final String? imageUrl, address, priceLabel, distanceLabel, badge;
  final double rating;
  final int reviewCount;
  final bool isFavorite, compact;
  final bool? isOpen;
  final VoidCallback? onTap, onFavorite;

  @override
  Widget build(BuildContext context) {
    final details = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: context.textStyles.titleMedium,
        ),
        const SizedBox(height: 4),
        Text(
          category,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: context.textStyles.bodySmall?.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        AppRating(value: rating, count: reviewCount),
        if (priceLabel != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              priceLabel!,
              style: context.textStyles.bodySmall?.copyWith(
                color: context.colors.secondary,
                fontFeatures: const [FontFeature.tabularFigures()],
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
            icon: isFavorite ? Icons.favorite : Icons.favorite_border,
            tooltip: isFavorite ? 'Bỏ yêu thích' : 'Lưu yêu thích',
            onPressed: onFavorite,
            selected: isFavorite,
            circular: true,
          );
    return Card(
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
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Stack(
                    children: [
                      AspectRatio(
                        aspectRatio: 16 / 9,
                        child: AppImage(url: imageUrl, semanticLabel: name),
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
                  Padding(padding: const EdgeInsets.all(16), child: details),
                ],
              ),
      ),
    );
  }
}
