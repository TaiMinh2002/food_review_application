import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_route.dart';
import '../../../core/formatters/app_formatters.dart';

import '../../favorites/presentation/favorite_providers.dart';
import '../domain/place.dart';
import '../domain/place_map_repository.dart';
import 'user_location_controller.dart';
import 'discovery_center.dart';
import '../../../shared/widgets/app_restaurant_card.dart';

class PlaceCard extends ConsumerWidget {
  const PlaceCard({
    super.key,
    required this.place,
    this.compact = true,
    this.onOpen,
    this.openOnMap = false,
    this.imageAspectRatio = 16 / 9,
    this.insetImage = false,
  });

  final Place place;
  final VoidCallback? onOpen;
  final bool openOnMap;
  final bool compact;
  final bool insetImage;
  final double imageAspectRatio;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFavorite = ref.watch(favoriteIdsProvider).contains(place.id);
    final location = openOnMap
        ? ref.watch(activeDiscoveryCenterProvider)
        : ref.watch(userLocationControllerProvider).point;
    final destination = GeoPoint(place.latitude, place.longitude);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppRestaurantCard(
        name: place.name,
        category: insetImage
            ? place.foodCategories.firstOrNull ?? place.category
            : place.category,
        address: (compact || insetImage) && place.address.isNotEmpty
            ? place.address
            : null,
        distanceLabel: location != null && destination.isValid
            ? '${AppFormatters.distance(location.distanceTo(destination))} · đường chim bay'
            : null,
        badge: compact || !place.isDemo ? null : 'Minh họa',
        imageUrl: place.imageUrls.firstOrNull,
        rating: place.averageRating,
        reviewCount: place.reviewCount,
        showReviewSummary: !openOnMap,
        compact: compact,
        imageAspectRatio: imageAspectRatio,
        insetImage: insetImage,
        priceLabel: place.minPrice != null && place.maxPrice != null
            ? AppFormatters.priceRange(place.minPrice!, place.maxPrice!)
            : null,
        isFavorite: isFavorite,
        onTap: () {
          onOpen?.call();
          if (openOnMap) {
            context.push(
              AppRoute.map.location(query: {'restaurantId': place.id}),
            );
          } else {
            context.push(
              AppRoute.restaurant.location(
                parameters: {'restaurantId': place.id},
              ),
            );
          }
        },
        onFavorite: openOnMap
            ? null
            : () => requestFavorite(context, ref, place.id),
      ),
    );
  }
}
