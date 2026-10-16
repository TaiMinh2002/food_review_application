import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../favorites/presentation/favorite_providers.dart';
import '../domain/place.dart';

class PlaceCard extends ConsumerWidget {
  const PlaceCard({super.key, required this.place});

  final Place place;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFavorite = ref.watch(favoriteIdsProvider).contains(place.id);
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: const CircleAvatar(child: Icon(Icons.restaurant)),
        title: Text(place.name),
        subtitle: Text('${place.category}\n${place.address}'),
        isThreeLine: true,
        onTap: () => context.push('/places/${place.id}'),
        trailing: IconButton(
          tooltip: isFavorite ? 'Bỏ yêu thích' : 'Lưu yêu thích',
          onPressed: () =>
              ref.read(favoriteIdsProvider.notifier).toggle(place.id),
          icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border),
        ),
      ),
    );
  }
}
