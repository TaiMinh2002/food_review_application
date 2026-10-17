import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../favorites/presentation/favorite_providers.dart';
import '../domain/place.dart';
import '../../../shared/widgets/app_restaurant_card.dart';

class PlaceCard extends ConsumerWidget {
  const PlaceCard({super.key, required this.place});

  final Place place;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFavorite = ref.watch(favoriteIdsProvider).contains(place.id);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppRestaurantCard(
        name: place.name,
        category: place.category,
        address: place.address,
        imageUrl: place.imageUrls.firstOrNull,
        rating: place.averageRating,
        reviewCount: place.reviewCount,
        compact: true,
        isFavorite: isFavorite,
        onTap: () => context.push('/places/${place.id}'),
        onFavorite: () =>
            ref.read(favoriteIdsProvider.notifier).toggle(place.id),
      ),
    );
  }
}
