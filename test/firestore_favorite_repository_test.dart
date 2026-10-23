import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_review/core/errors/app_exception.dart';
import 'package:food_review/features/auth/presentation/auth_providers.dart';
import 'package:food_review/features/favorites/data/firestore_favorite_repository.dart';
import 'package:food_review/features/favorites/presentation/favorite_providers.dart';
import 'package:food_review/features/places/data/osm_region_place_repository.dart';
import 'package:food_review/features/places/domain/place.dart';
import 'package:food_review/features/places/domain/place_repository.dart';
import 'package:food_review/features/places/presentation/map_controller.dart';
import 'package:food_review/features/places/presentation/place_providers.dart';

import 'support/auth_harness.dart';

class _StubDemoRepo implements PlaceRepository {
  static const _demoPlace = Place(
    id: 'pho-demo',
    name: 'Phở Nhà Mình',
    description: 'Phở gia truyền',
    category: 'Món Việt',
    address: '123 Phố Huế',
    latitude: 21.01,
    longitude: 105.85,
  );

  @override
  Future<List<Place>> fetchPlaces() async => [_demoPlace];

  @override
  Future<Place?> getPlace(String id) async {
    if (id == 'pho-demo') {
      return _demoPlace;
    }
    return null;
  }
}

void main() {
  group('FirestoreFavoriteRepository unit tests', () {
    test('Validates empty userId and placeId', () async {
      final repo = FirestoreFavoriteRepository(null);

      expect(
        () => repo.setFavorite(userId: '', placeId: 'p1', value: true),
        throwsA(isA<AppException>()),
      );
      expect(
        () => repo.setFavorite(userId: 'u1', placeId: ' ', value: true),
        throwsA(isA<AppException>()),
      );
    });

    test('watchPlaceIds yields empty set for empty userId', () async {
      final repo = FirestoreFavoriteRepository(null);

      final result = await repo.watchPlaceIds('').first;
      expect(result, isEmpty);
    });

    test('Adds and removes favorites via saveFavorite hook', () async {
      final store = <String, bool>{};
      final repo = FirestoreFavoriteRepository(
        null,
        saveFavorite: (userId, placeId, value) async {
          if (value) {
            store[placeId] = true;
          } else {
            store.remove(placeId);
          }
        },
      );

      await repo.setFavorite(
        userId: 'user1',
        placeId: 'osm_node_123',
        value: true,
      );
      expect(store.containsKey('osm_node_123'), isTrue);

      await repo.setFavorite(
        userId: 'user1',
        placeId: 'osm_node_123',
        value: false,
      );
      expect(store.containsKey('osm_node_123'), isFalse);
    });

    test('Streams updates via watchIds hook', () async {
      final streamController = StreamController<Set<String>>.broadcast();
      addTearDown(streamController.close);

      final repo = FirestoreFavoriteRepository(
        null,
        watchIds: (userId) => streamController.stream,
      );

      final stream = repo.watchPlaceIds('user1');
      final expectation = expectLater(
        stream,
        emitsInOrder([
          {'p1', 'p2'},
        ]),
      );

      streamController.add({'p1', 'p2'});
      await expectation;
    });
  });

  group('favoritePlacesProvider resolution tests', () {
    testWidgets('Resolves both demo and OSM places into Place models', (
      tester,
    ) async {
      final package =
          File('assets/osm/hanoi_urban_places.json').readAsStringSync();
      final fakeOsm = OsmRegionPlaceRepository(() async => package);

      final auth = ControlledAuth(user: authTestUser);

      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(auth),
          placeRepositoryProvider.overrideWithValue(_StubDemoRepo()),
          osmRegionPlaceRepositoryProvider.overrideWithValue(fakeOsm),
        ],
      );
      addTearDown(() async {
        container.dispose();
        await auth.events.close();
      });

      final listenAuth = container.listen(authSessionProvider, (_, _) {});
      addTearDown(listenAuth.close);
      final listenFavorites = container.listen(
        favoritePlacesProvider,
        (_, _) {},
      );
      addTearDown(listenFavorites.close);

      await tester.runAsync(() async {
        await Future<void>.delayed(Duration.zero);
      });

      // Favorite a demo place and an OSM place
      container.read(favoriteIdsProvider.notifier).toggle('pho-demo');
      container
          .read(favoriteIdsProvider.notifier)
          .toggle('osm_node_10098130619');

      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });

      final places = await container.read(favoritePlacesProvider.future);
      expect(places.length, 2);
      expect(places.any((p) => p.name == 'Phở Nhà Mình'), isTrue);
      expect(places.any((p) => p.name == 'Youone Hotdog'), isTrue);

      // Missing place is ignored gracefully
      container.read(favoriteIdsProvider.notifier).toggle('missing-id-404');
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });
      final updated = await container.read(favoritePlacesProvider.future);
      expect(updated.length, 2);

      await tester.pumpAndSettle();
    });
  });
}
