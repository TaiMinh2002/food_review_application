import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_review/app/food_review_app.dart';
import 'package:food_review/core/theme/theme_mode_provider.dart';
import 'package:food_review/features/places/domain/nearby_place_repository.dart';
import 'package:food_review/features/places/data/osm_region_place_repository.dart';
import 'package:food_review/features/places/domain/place.dart';
import 'package:food_review/features/places/domain/place_map_repository.dart';
import 'package:food_review/features/places/presentation/discovery_center.dart';
import 'package:food_review/features/places/presentation/map_controller.dart';
import 'package:food_review/features/places/presentation/map_widgets.dart';
import 'package:food_review/features/places/presentation/place_providers.dart';
import 'package:food_review/features/places/presentation/user_location_controller.dart';

import 'support/auth_fixtures.dart';

const _cafe = Place(
  id: 'osm_node_1',
  name: 'Cà Phê Sông',
  description: '',
  address: 'Phùng Khoang',
  category: 'Cà phê',
  latitude: 20.986,
  longitude: 105.794,
);
const _restaurant = Place(
  id: 'osm_node_2',
  name: 'Bún Thanh Xuân',
  description: '',
  address: '',
  category: 'Nhà hàng',
  latitude: 20.99,
  longitude: 105.795,
);
const _other = Place(
  id: 'osm_node_3',
  name: 'Quán Khu Mới',
  description: '',
  address: '',
  category: 'Nhà hàng',
  latitude: 21.02,
  longitude: 105.82,
);

class _Nearby implements NearbyPlaceRepository {
  final calls = <GeoPoint>[];

  @override
  Future<List<Place>> findNearby(
    GeoPoint center, {
    int radiusMeters = 5000,
  }) async {
    calls.add(center);
    expectSync(radiusMeters, 5000);
    return center.latitude > 21 ? [_other] : [_cafe, _restaurant];
  }
}

class _DelayedNearby implements NearbyPlaceRepository {
  final pending = <Completer<List<Place>>>[];

  @override
  Future<List<Place>> findNearby(GeoPoint center, {int radiusMeters = 5000}) {
    final result = Completer<List<Place>>();
    pending.add(result);
    return result.future;
  }
}

class _Location implements UserLocationRepository {
  _Location(this.point);
  final GeoPoint? point;
  @override
  Future<GeoPoint> locate() async => point ?? (throw StateError('GPS denied'));
  @override
  Future<bool> openSettings() async => false;
}

Future<ProviderContainer> _mount(
  WidgetTester tester, {
  NearbyPlaceRepository? nearby,
  GeoPoint? gps,
  double width = 390,
  double scale = 1,
  ThemeMode mode = ThemeMode.light,
  OsmRegionPlaceRepository? region,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(width, 844);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final container = ProviderContainer(
    overrides: [
      signedInSession,
      userLocationRepositoryProvider.overrideWithValue(_Location(gps)),
      if (nearby != null)
        nearbyPlaceRepositoryProvider.overrideWithValue(nearby),
      if (region != null)
        osmRegionPlaceRepositoryProvider.overrideWithValue(region),
      mapTilesEnabledProvider.overrideWithValue(false),
    ],
  );
  addTearDown(container.dispose);
  container.read(themeModeProvider.notifier).setMode(mode);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(scale)),
        child: const FoodReviewApp(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

void main() {
  testWidgets('Home waits for a real center and allows manual Phùng Khoang', (
    tester,
  ) async {
    final source = _Nearby();
    await _mount(tester, nearby: source);
    expect(source.calls, isEmpty);
    expect(
      find.textContaining('Chọn Chợ Phùng Khoang hoặc cấp quyền'),
      findsOneWidget,
    );
    await tester.tap(find.text('Xem Chợ Phùng Khoang'));
    await tester.pumpAndSettle();
    expect(source.calls.single.latitude, phungKhoangCenter.latitude);
    expect(find.text('2 quán phù hợp trong 5 km'), findsOneWidget);
    expect(find.text('Cà Phê Sông'), findsOneWidget);
    expect(find.text('Bản demo'), findsNothing);
    expect(find.text('Chưa có đánh giá'), findsNothing);
    expect(find.byTooltip('Lưu yêu thích'), findsNothing);
  });

  testWidgets('Changing the center replaces old results', (tester) async {
    final source = _Nearby();
    final container = await _mount(tester, nearby: source);
    await tester.tap(find.text('Xem Chợ Phùng Khoang'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Quán quanh khu vực này'));
    await tester.pumpAndSettle();
    expect(find.text('Cà Phê Sông'), findsOneWidget);
    container
        .read(discoveryCenterProvider.notifier)
        .choose(const GeoPoint(21.02, 105.82));
    await tester.pumpAndSettle();
    expect(find.text('Cà Phê Sông'), findsNothing);
    expect(
      (await container.read(homeNearbyPlacesProvider.future))?.single.name,
      'Quán Khu Mới',
    );
    expect(source.calls.length, 2);
  });

  testWidgets('An older region response cannot replace the new center', (
    tester,
  ) async {
    final source = _DelayedNearby();
    final container = await _mount(tester, nearby: source);
    await tester.tap(find.text('Xem Chợ Phùng Khoang'));
    await tester.pump();
    expect(source.pending, hasLength(1));
    container
        .read(discoveryCenterProvider.notifier)
        .choose(const GeoPoint(21.02, 105.82));
    await tester.pump();
    expect(source.pending, hasLength(2));
    source.pending.last.complete([_other]);
    await tester.pumpAndSettle();
    source.pending.first.complete([_cafe]);
    await tester.pumpAndSettle();
    expect(
      container.read(homeNearbyPlacesProvider).value?.single.id,
      _other.id,
    );
  });

  testWidgets('GPS can replace the manual center; local search filters POIs', (
    tester,
  ) async {
    final source = _Nearby();
    final container = await _mount(
      tester,
      nearby: source,
      gps: const GeoPoint(21.02, 105.82),
    );
    await container.read(userLocationControllerProvider.notifier).initialize();
    await tester.pumpAndSettle();
    expect(
      (await container.read(homeNearbyPlacesProvider.future))?.single.name,
      'Quán Khu Mới',
    );
    await tester.tap(find.text('Xem Chợ Phùng Khoang'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Quán quanh khu vực này'));
    await tester.pumpAndSettle();
    expect(find.text('Cà Phê Sông'), findsOneWidget);
    await tester.ensureVisible(find.byType(TextField));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'bun');
    await tester.pumpAndSettle();
    expect(find.text('Bún Thanh Xuân'), findsOneWidget);
    expect(find.text('Cà Phê Sông'), findsNothing);
    await tester.tap(find.byTooltip('Xoá nội dung'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Dùng vị trí thiết bị'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dùng vị trí thiết bị'));
    await tester.pumpAndSettle();
    expect(
      (await container.read(homeNearbyPlacesProvider.future))?.single.name,
      'Quán Khu Mới',
    );
    expect(container.read(discoveryCenterProvider), isNull);
  });

  for (final mode in [ThemeMode.light, ThemeMode.dark]) {
    testWidgets(
      'Home renders on a small screen with large text in ${mode.name}',
      (tester) async {
        await _mount(
          tester,
          nearby: _Nearby(),
          width: 320,
          scale: 1.6,
          mode: mode,
        );
        await tester.tap(find.text('Xem Chợ Phùng Khoang'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.drag(find.byType(CustomScrollView), const Offset(0, -450));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('Bundled OSM asset supplies the real Phùng Khoang count', (
    tester,
  ) async {
    await _mount(
      tester,
      region: OsmRegionPlaceRepository(
        () async =>
            File('assets/osm/hanoi_urban_places.json').readAsStringSync(),
      ),
    );
    await tester.tap(find.text('Xem Chợ Phùng Khoang'));
    await tester.pumpAndSettle();
    expect(find.text('556 quán phù hợp trong 5 km'), findsOneWidget);
  });

  testWidgets('Home-selected center opens Map at the same location', (
    tester,
  ) async {
    await _mount(tester, nearby: _Nearby());
    await tester.tap(find.text('Xem Chợ Phùng Khoang'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Mở bản đồ'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mở bản đồ'));
    await tester.pumpAndSettle();
    final canvas = tester.widget<PlaceMapCanvas>(find.byType(PlaceMapCanvas));
    expect(
      canvas.center.latitude,
      closeTo(phungKhoangCenter.latitude, 0.00001),
    );
    expect(
      canvas.center.longitude,
      closeTo(phungKhoangCenter.longitude, 0.00001),
    );
  });
}
