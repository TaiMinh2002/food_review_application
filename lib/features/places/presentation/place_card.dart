import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_route.dart';
import '../../../core/formatters/app_formatters.dart';

import '../../favorites/presentation/favorite_providers.dart';
import '../domain/place.dart';
import '../../../shared/widgets/app_restaurant_card.dart';

class PlaceCard extends ConsumerWidget {
  const PlaceCard({
    super.key,
    required this.place,
    this.compact = true,
    this.onOpen,
    this.imageAspectRatio = 16 / 9,
    this.insetImage = false,
  });

  final Place place;
  final VoidCallback? onOpen;
  final bool compact;
  final bool insetImage;
  final double imageAspectRatio;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFavorite = ref.watch(favoriteIdsProvider).contains(place.id);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppRestaurantCard(
        name: place.name,
        category: insetImage
            ? place.foodCategories.firstOrNull ?? place.category
            : place.category,
        address: compact || insetImage ? place.address : null,
        badge: compact || !place.isDemo ? null : 'Minh họa',
        imageUrl: place.imageUrls.firstOrNull,
        rating: place.averageRating,
        reviewCount: place.reviewCount,
        compact: compact,
        imageAspectRatio: imageAspectRatio,
        insetImage: insetImage,
        priceLabel: place.minPrice != null && place.maxPrice != null
            ? AppFormatters.priceRange(place.minPrice!, place.maxPrice!)
            : null,
        isFavorite: isFavorite,
        onTap: () {
          onOpen?.call();
          context.push(
            AppRoute.restaurant.location(
              parameters: {'restaurantId': place.id},
            ),
          );
        },
        onFavorite: () =>
            ref.read(favoriteIdsProvider.notifier).toggle(place.id),
      ),
    );
  }
}
