import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/memory_favorite_repository.dart';
import '../domain/favorite_repository.dart';

final favoriteRepositoryProvider = Provider<FavoriteRepository>(
  (ref) => MemoryFavoriteRepository(),
);

final favoriteIdsProvider = NotifierProvider<FavoriteIds, Set<String>>(
  FavoriteIds.new,
);

class FavoriteIds extends Notifier<Set<String>> {
  @override
  Set<String> build() => ref.watch(favoriteRepositoryProvider).getPlaceIds();

  void toggle(String placeId) {
    final repository = ref.read(favoriteRepositoryProvider);
    repository.toggle(placeId);
    state = repository.getPlaceIds();
  }
}
