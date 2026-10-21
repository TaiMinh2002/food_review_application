import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'support/auth_fixtures.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:food_review/app/food_review_app.dart';
import 'package:food_review/core/errors/app_exception.dart';
import 'package:food_review/core/router/app_router.dart';
import 'package:food_review/core/theme/theme_mode_provider.dart';
import 'package:food_review/features/favorites/presentation/favorite_providers.dart';
import 'package:food_review/features/places/data/demo_place_repository.dart';
import 'package:food_review/features/places/domain/place_map_repository.dart';
import 'package:food_review/features/places/domain/place_search.dart';
import 'package:food_review/features/places/presentation/map_controller.dart';
import 'package:food_review/features/places/presentation/map_widgets.dart';
import 'package:food_review/features/places/presentation/user_location_controller.dart';
import 'package:food_review/features/places/presentation/place_detail_screen.dart';
import 'package:food_review/shared/widgets/app_text_field.dart';

const region = MapViewport(south: 10.7, west: 106.6, north: 10.9, east: 106.8);

class FakeLocation implements UserLocationRepository {
  int calls = 0;
  Object? error;
  Completer<GeoPoint>? pending;
  @override
  Future<GeoPoint> locate() async {
    calls++;
    if (error != null) throw error!;
    return pending?.future ?? const GeoPoint(10.7769, 106.7009);
  }

  @override
  Future<bool> openSettings() async => true;
}

class DelayedMap implements PlaceMapRepository {
  final calls = <Completer<PlaceMapResult>>[];
  @override
  Future<PlaceMapResult> findInViewport(
    MapViewport viewport, {
    required PlaceSearchRequest filters,
    GeoPoint? near,
    int limit = 50,
  }) {
    final result = Completer<PlaceMapResult>();
    calls.add(result);
    return result.future;
  }
}

void main() {
  test(
    'Map query respects bounds, radius, filters, limit and invalid coordinates',
    () async {
      final repo = DemoPlaceRepository();
      var result = await repo.findInViewport(
        region,
        filters: PlaceSearchRequest(),
        limit: 1,
      );
      expect(result.places, hasLength(1));
      expect(result.hasMore, isTrue);
      result = await repo.findInViewport(
        region,
        filters: PlaceSearchRequest(query: 'ca phe', maxPrice: 49999),
      );
      expect(result.places.single.id, 'coffee-demo');
      result = await repo.findInViewport(
        region,
        filters: PlaceSearchRequest(),
        near: const GeoPoint(10.7769, 106.7009),
      );
      expect(result.places.single.id, 'pho-demo');
      result = await repo.findInViewport(
        const MapViewport(south: 20, west: 105, north: 22, east: 106),
        filters: PlaceSearchRequest(),
      );
      expect(result.places, isEmpty);
      expect(region.contains(const GeoPoint(double.nan, 106)), isFalse);
      expect(
        const MapViewport(
          south: -10,
          west: 170,
          north: 10,
          east: -170,
        ).contains(const GeoPoint(0, -175)),
        isTrue,
      );
      expect(
        const GeoPoint(0, 0).distanceTo(const GeoPoint(0, 1)),
        closeTo(111195, 10),
      );
      expect(
        walkingDirections(DemoPlaceRepository.places.first).queryParameters,
        {
          'api': '1',
          'destination': '10.7769,106.7009',
          'travelmode': 'walking',
        },
      );
    },
  );

  test(
    'Map debounce and stale responses cannot overwrite newer region or filters',
    () async {
      final repo = DelayedMap();
      final container = ProviderContainer(
        overrides: [placeMapRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);
      final controller = container.read(placeMapControllerProvider.notifier);
      controller.searchArea(region);
      controller.query('old');
      controller.query('new');
      repo.calls.first.complete(
        PlaceMapResult(places: DemoPlaceRepository.places),
      );
      await Future<void>.delayed(const Duration(milliseconds: 350));
      expect(repo.calls, hasLength(2));
      repo.calls.last.complete(
        PlaceMapResult(places: [DemoPlaceRepository.places.last]),
      );
      await Future<void>.delayed(Duration.zero);
      expect(container.read(placeMapControllerProvider).filters.query, 'new');
      expect(
        container.read(placeMapControllerProvider).result!.places.single.id,
        'banh-mi-demo',
      );
      controller.searchArea(region);
      repo.calls.last.completeError(const AppException('Lỗi vùng thử nghiệm'));
      await Future<void>.delayed(Duration.zero);
      expect(
        container.read(placeMapControllerProvider).error,
        'Lỗi vùng thử nghiệm',
      );
      expect(
        container.read(placeMapControllerProvider).result!.places,
        hasLength(1),
      );
    },
  );

  test(
    'Shared GPS guards duplicate requests and clears stale fix after denial',
    () async {
      final location = FakeLocation()..pending = Completer<GeoPoint>();
      final container = ProviderContainer(
        overrides: [userLocationRepositoryProvider.overrideWithValue(location)],
      );
      addTearDown(container.dispose);
      final controller = container.read(placeMapControllerProvider.notifier);
      expect(location.calls, 0);
      controller.nearby(true);
      expect(container.read(placeMapControllerProvider).nearby, isFalse);
      final first = controller.locate();
      expect(await controller.locate(), isNull);
      expect(location.calls, 1);
      location.pending!.complete(const GeoPoint(10.77, 106.7));
      expect(await first, isNotNull);
      controller.nearby(true);
      expect(container.read(placeMapControllerProvider).nearby, isTrue);
      controller.resetFilters();
      expect(container.read(placeMapControllerProvider).nearby, isFalse);
      location.error = const AppException('Vị trí bị từ chối');
      expect(await controller.locate(), isNull);
      expect(
        container.read(placeMapControllerProvider).locationError,
        'Vị trí bị từ chối',
      );
      expect(container.read(placeMapControllerProvider).location, isNull);
    },
  );

  Future<ProviderContainer> mount(
    WidgetTester tester, {
    double width = 390,
    double height = 844,
    double scale = 1,
    ThemeMode mode = ThemeMode.light,
    String route = '/map',
    FakeLocation? location,
    PlaceMapRepository? repository,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = Size(width, height);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final container = ProviderContainer(
      overrides: [
        mapTilesEnabledProvider.overrideWithValue(false),
        signedInSession,
        userLocationRepositoryProvider.overrideWithValue(
          location ?? FakeLocation(),
        ),
        if (repository != null)
          placeMapRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);
    container.read(themeModeProvider.notifier).setMode(mode);
    await container.read(userLocationControllerProvider.notifier).initialize();
    container.read(appRouterProvider).go(route);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MediaQuery.fromView(
          view: tester.view,
          child: Builder(
            builder: (context) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(scale),
                padding: const EdgeInsets.only(top: 44, bottom: 24),
                viewPadding: const EdgeInsets.only(top: 44, bottom: 24),
              ),
              child: const FoodReviewApp(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  for (final mode in [ThemeMode.light, ThemeMode.dark]) {
    for (final width in [320.0, 390.0, 428.0]) {
      for (final scale in [1.0, 1.6]) {
        testWidgets(
          'Map fits $width at ${scale}x text with safe insets in ${mode.name}',
          (tester) async {
            await mount(tester, width: width, scale: scale, mode: mode);
            expect(tester.takeException(), isNull);
            await tester.ensureVisible(find.text('Xem chi tiết'));
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
            expect(find.text('© OpenStreetMap'), findsOneWidget);
          },
        );
      }
    }
  }

  testWidgets(
    'Marker selection, favorites and camera survive detail Back and tab switches',
    (tester) async {
      final container = await mount(tester, height: 1000);
      final canvas = tester.widget<PlaceMapCanvas>(find.byType(PlaceMapCanvas));
      await tester.tap(find.byKey(const ValueKey('marker-pho-demo')));
      await tester.pumpAndSettle();
      final camera = canvas.controller.camera;
      await tester.tap(find.byTooltip('Lưu quán'));
      await tester.pumpAndSettle();
      expect(container.read(favoriteIdsProvider), contains('pho-demo'));
      await tester.tap(find.text('Xem chi tiết'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<PlaceDetailScreen>(find.byType(PlaceDetailScreen))
            .placeId,
        'pho-demo',
      );
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byTooltip('Bỏ lưu quán'), findsOneWidget);
      await tester.tap(find.text('Trang chủ'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bản đồ').last);
      await tester.pumpAndSettle();
      expect(canvas.controller.camera.center, camera.center);
      expect(canvas.controller.camera.zoom, camera.zoom);
      expect(find.byTooltip('Bỏ lưu quán'), findsOneWidget);
    },
  );

  testWidgets('Search, clear, empty and filter draft apply affect map data', (
    tester,
  ) async {
    final container = await mount(tester, height: 1100);
    final input = find.descendant(
      of: find.byType(AppSearchField),
      matching: find.byType(TextField),
    );
    await tester.enterText(input, 'missing');
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();
    expect(
      find.text('Không có quán phù hợp trong vùng đã tìm.'),
      findsOneWidget,
    );
    await tester.enterText(input, 'pho');
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();
    expect(find.byType(MapPlacePreview), findsOneWidget);
    await tester.tap(find.byTooltip('Bộ lọc'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hủy'));
    await tester.pumpAndSettle();
    expect(container.read(placeMapControllerProvider).filters.query, 'pho');
    await tester.enterText(input, '');
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();
    expect(container.read(placeMapControllerProvider).filters.query, '');
    await tester.tap(find.byTooltip('Bộ lọc'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Dưới 50.000đ'));
    await tester.tap(find.text('Dưới 50.000đ'));
    await tester.tap(find.text('Áp dụng bộ lọc'));
    await tester.pumpAndSettle();
    expect(container.read(placeMapControllerProvider).filters.maxPrice, 49999);
    final ids = container
        .read(placeMapControllerProvider)
        .result!
        .places
        .map((p) => p.id);
    expect(ids, contains('banh-mi-demo'));
    expect(ids, isNot(contains('pho-demo')));
  });

  testWidgets(
    'Keyboard and compact layout preserve the camera and search field',
    (tester) async {
      await mount(tester, height: 1000);
      final canvas = tester.widget<PlaceMapCanvas>(find.byType(PlaceMapCanvas));
      canvas.controller.move(const LatLng(10.78, 106.7), 16);
      await tester.pumpAndSettle();
      final camera = canvas.controller.camera;
      tester.view.viewInsets = const FakeViewPadding(bottom: 350);
      addTearDown(tester.view.resetViewInsets);
      await tester.pumpAndSettle();
      expect(canvas.controller.camera.center, camera.center);
      expect(canvas.controller.camera.zoom, camera.zoom);
      expect(tester.takeException(), isNull);
      tester.view.viewInsets = const FakeViewPadding();
      await tester.pumpAndSettle();
      expect(canvas.controller.camera.center, camera.center);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Loading and region failure offer retry; retry restores results',
    (tester) async {
      final repository = DelayedMap();
      final container = await mount(
        tester,
        repository: repository,
        height: 1100,
      );
      expect(find.text('Đang tìm quán…'), findsOneWidget);
      repository.calls.last.completeError(
        const AppException('Không tải được vùng thử nghiệm'),
      );
      await tester.pumpAndSettle();
      expect(find.text('Không tải được vùng thử nghiệm'), findsOneWidget);
      await tester.tap(find.text('Thử lại'));
      await tester.pumpAndSettle();
      repository.calls.last.complete(
        PlaceMapResult(places: [DemoPlaceRepository.places.first]),
      );
      await tester.pumpAndSettle();
      expect(container.read(placeMapControllerProvider).error, isNull);
      expect(find.byType(MapPlacePreview), findsOneWidget);
      const channel = MethodChannel('plugins.flutter.io/url_launcher');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (_) async => false);
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null),
      );
      await tester.runAsync(
        () => openMapLink(
          tester.element(find.byType(MapPlacePreview)),
          walkingDirections(DemoPlaceRepository.places.first),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('Không mở được ứng dụng bản đồ. Vui lòng thử lại.'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'Startup GPS denial offers settings without a fixed map; retry creates map at device position',
    (tester) async {
      final location = FakeLocation()
        ..error = const AppException('Chưa cấp quyền vị trí');
      final container = await mount(tester, height: 1100, location: location);
      expect(location.calls, 1);
      expect(find.text('Chưa cấp quyền vị trí'), findsOneWidget);
      expect(find.text('Cài đặt vị trí'), findsOneWidget);
      expect(find.byType(FlutterMap), findsNothing);
      location.error = null;
      await tester.tap(find.byTooltip('Cập nhật vị trí'));
      await tester.pumpAndSettle();
      expect(container.read(placeMapControllerProvider).location, isNotNull);
      expect(find.text('Chưa cấp quyền vị trí'), findsNothing);
      final canvas = tester.widget<PlaceMapCanvas>(find.byType(PlaceMapCanvas));
      expect(
        canvas.controller.camera.center.latitude,
        closeTo(10.7769, 0.00001),
      );
      expect(
        canvas.controller.camera.center.longitude,
        closeTo(106.7009, 0.00001),
      );
    },
  );

  testWidgets(
    'Deep link selects requested restaurant and invalid ID remains usable',
    (tester) async {
      final container = await mount(
        tester,
        height: 1100,
        route: '/map?restaurantId=banh-mi-demo',
      );
      expect(
        tester.widget<MapPlacePreview>(find.byType(MapPlacePreview)).place.id,
        'banh-mi-demo',
      );
      container.read(appRouterProvider).go('/map?restaurantId=missing');
      await tester.pumpAndSettle();
      expect(find.text('Không tìm thấy vị trí quán này.'), findsOneWidget);
      expect(find.byType(FlutterMap), findsOneWidget);
    },
  );

  testWidgets('Restaurant map remains available without location permission', (
    tester,
  ) async {
    await mount(
      tester,
      route: '/map?restaurantId=banh-mi-demo',
      location: FakeLocation()
        ..error = const AppException('Chưa cấp quyền vị trí'),
    );
    final canvas = tester.widget<PlaceMapCanvas>(find.byType(PlaceMapCanvas));
    expect(canvas.location, isNull);
    expect(canvas.center, const LatLng(10.8015, 106.7100));
    expect(
      tester.widget<MapPlacePreview>(find.byType(MapPlacePreview)).place.id,
      'banh-mi-demo',
    );
    expect(tester.takeException(), isNull);
    await tester.tap(find.byKey(const ValueKey('marker-banh-mi-demo')));
    await tester.pumpAndSettle();
    expect(find.byType(PlaceMapCanvas), findsOneWidget);
    expect(
      tester.widget<PlaceMapCanvas>(find.byType(PlaceMapCanvas)).location,
      isNull,
    );
    expect(tester.takeException(), isNull);
  });
}
