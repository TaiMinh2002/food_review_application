import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/router/app_route.dart';
import '../../../shared/widgets/app_feedback.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../places/domain/place.dart';
import '../../places/presentation/map_controller.dart';
import '../../places/presentation/place_providers.dart';

import '../data/firestore_favorite_repository.dart';
import '../data/memory_favorite_repository.dart';
import '../domain/favorite_repository.dart';

final favoriteRepositoryProvider = Provider<FavoriteRepository>((ref) {
  ref.watch(authSessionProvider.select((state) => state.asData?.value?.id));
  if (Firebase.apps.isEmpty) {
    final repository = MemoryFavoriteRepository();
    ref.onDispose(repository.dispose);
    return repository;
  }
  return FirestoreFavoriteRepository(FirebaseFirestore.instance);
});

final favoriteIdsProvider = NotifierProvider<FavoriteIds, Set<String>>(
  FavoriteIds.new,
);

class FavoriteIds extends Notifier<Set<String>> {
  @override
  Set<String> build() {
    final session = ref.watch(authSessionProvider);
    final user = session.asData?.value;
    if (session.isLoading || session.hasError || user == null) return {};
    final repository = ref.watch(favoriteRepositoryProvider);
    final subscription = repository.watchPlaceIds(user.id).listen((ids) {
      if (ref.mounted) state = Set.unmodifiable(ids);
    });
    ref.onDispose(subscription.cancel);
    return {};
  }

  void toggle(String placeId) {
    final session = ref.read(authSessionProvider);
    if (session.isLoading ||
        session.hasError ||
        session.asData?.value == null) {
      throw const AppException('Vui lòng đăng nhập trước khi lưu quán.');
    }
    final user = session.asData!.value!;
    final repository = ref.read(favoriteRepositoryProvider);
    final previous = state;
    final value = !state.contains(placeId);
    final next = {...state};
    if (value) {
      next.add(placeId);
    } else {
      next.remove(placeId);
    }
    state = Set.unmodifiable(next);
    unawaited(
      repository
          .setFavorite(userId: user.id, placeId: placeId, value: value)
          .catchError((_) {
            if (ref.mounted) state = previous;
          }),
    );
  }
}

/// Resolves real Place models (OSM or demo) for the currently favorited place IDs.
final favoritePlacesProvider = FutureProvider<List<Place>>((ref) async {
  final ids = ref.watch(favoriteIdsProvider);
  if (ids.isEmpty) return const [];

  final demoRepo = ref.watch(placeRepositoryProvider);
  final osmRepo = ref.watch(osmRegionPlaceRepositoryProvider);

  final places = <Place>[];
  for (final id in ids) {
    var place = await demoRepo.getPlace(id);
    place ??= await osmRepo.getById(id);
    if (place != null) {
      places.add(place);
    }
  }
  return places;
}, retry: (retryCount, error) => null);

void requestFavorite(BuildContext context, WidgetRef ref, String placeId) {
  final session = ref.read(authSessionProvider);
  if (session.isLoading || session.hasError) {
    AppToast.show(
      context,
      'Chưa kiểm tra được phiên đăng nhập. Vui lòng thử lại.',
    );
  } else if (session.asData?.value == null) {
    context.push(
      AppRoute.login.location(
        query: {
          'returnTo': AppRoute.restaurant.location(
            parameters: {'restaurantId': placeId},
          ),
          'action': 'favorite',
        },
      ),
    );
  } else {
    ref.read(favoriteIdsProvider.notifier).toggle(placeId);
  }
}
