import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:food_review/app/food_review_app.dart';
import 'package:food_review/core/router/app_router.dart';
import 'package:food_review/features/places/domain/place.dart';
import 'package:food_review/features/places/domain/nearby_place_repository.dart';
import 'package:food_review/features/places/domain/place_map_repository.dart';
import 'package:food_review/features/places/presentation/place_providers.dart';
import 'package:food_review/shared/widgets/app_skeleton.dart';

void main() {
  testWidgets('Pending repository shows loading before its empty result', (
    tester,
  ) async {
    final result = Completer<List<Place>>();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          nearbyPlaceRepositoryProvider.overrideWithValue(
            _DeferredRepository(result.future),
          ),
        ],
        child: const FoodReviewApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Xem Chợ Phùng Khoang'));
    await tester.pump();
    expect(find.byType(AppRestaurantSkeleton), findsOneWidget);
    result.complete([]);
    await tester.pumpAndSettle();
    expect(find.byType(AppRestaurantSkeleton), findsNothing);
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -300));
    await tester.pumpAndSettle();
    expect(find.text('Không tìm thấy quán phù hợp.'), findsOneWidget);
  });

  testWidgets('Empty repository shows empty state', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          nearbyPlaceRepositoryProvider.overrideWithValue(_EmptyRepository()),
        ],
        child: const FoodReviewApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Xem Chợ Phùng Khoang'));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -300));
    await tester.pumpAndSettle();
    expect(find.text('Không tìm thấy quán phù hợp.'), findsOneWidget);
  });

  testWidgets('Repository failure can be retried', (tester) async {
    final repository = _FailOnceRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          nearbyPlaceRepositoryProvider.overrideWithValue(repository),
        ],
        child: const FoodReviewApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Xem Chợ Phùng Khoang'));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -300));
    await tester.pumpAndSettle();
    expect(find.text('Không tải được quán trong khu vực này.'), findsOneWidget);
    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();
    expect(repository.calls, 2);
    expect(find.text('Không tìm thấy quán phù hợp.'), findsOneWidget);
  });

  testWidgets('Unknown place ID shows not found', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const FoodReviewApp(),
      ),
    );
    await tester.pumpAndSettle();
    // Enter a detail route without passing an in-memory Place object.
    container.read(appRouterProvider).go('/places/missing');
    await tester.pumpAndSettle();
    expect(find.text('Quán không tồn tại.'), findsOneWidget);
  });
}

class _EmptyRepository implements NearbyPlaceRepository {
  @override
  Future<List<Place>> findNearby(
    GeoPoint center, {
    int radiusMeters = 5000,
  }) async => [];
}

class _DeferredRepository extends _EmptyRepository {
  _DeferredRepository(this.result);
  final Future<List<Place>> result;

  @override
  Future<List<Place>> findNearby(GeoPoint center, {int radiusMeters = 5000}) =>
      result;
}

class _FailOnceRepository extends _EmptyRepository {
  int calls = 0;

  @override
  Future<List<Place>> findNearby(
    GeoPoint center, {
    int radiusMeters = 5000,
  }) async {
    calls++;
    if (calls == 1) throw Exception('Simulated network failure');
    return [];
  }
}
