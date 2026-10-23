import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_review/app/food_review_app.dart';
import 'package:food_review/core/router/app_router.dart';
import 'package:food_review/core/theme/theme_mode_provider.dart';
import 'package:food_review/features/places/data/osm_region_place_repository.dart';
import 'package:food_review/features/places/domain/place_map_repository.dart';
import 'package:food_review/features/places/presentation/discovery_center.dart';
import 'package:food_review/features/places/presentation/map_controller.dart';
import 'package:food_review/features/places/presentation/place_providers.dart';

import 'support/auth_fixtures.dart';

void main() {
  final captureKey = GlobalKey();
  final package = File('assets/osm/hanoi_urban_places.json').readAsStringSync();
  const phungKhoang = GeoPoint(20.9859, 105.7938);

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await (FontLoader(
      'Inter',
    )..addFont(rootBundle.load('assets/fonts/Inter.ttf'))).load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });

  Future<ProviderContainer> mount(
    WidgetTester tester, {
    required String placeId,
    double width = 390,
    double height = 844,
    double scale = 1,
    ThemeMode mode = ThemeMode.light,
    bool withCenter = true,
    OsmRegionPlaceRepository? customRegion,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = Size(width, height);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final region =
        customRegion ?? OsmRegionPlaceRepository(() async => package);
    final container = ProviderContainer(
      overrides: [
        signedInSession,
        mapTilesEnabledProvider.overrideWithValue(false),
        osmRegionPlaceRepositoryProvider.overrideWithValue(region),
        nearbyPlaceRepositoryProvider.overrideWithValue(region),
      ],
    );
    addTearDown(container.dispose);

    if (withCenter) {
      container.read(discoveryCenterProvider.notifier).choose(phungKhoang);
    }
    container.read(themeModeProvider.notifier).setMode(mode);
    container.read(appRouterProvider).go('/restaurants/$placeId');

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: RepaintBoundary(
          key: captureKey,
          child: MediaQuery(
            data: MediaQueryData(
              textScaler: TextScaler.linear(scale),
              padding: const EdgeInsets.only(top: 44, bottom: 24),
              viewPadding: const EdgeInsets.only(top: 44, bottom: 24),
            ),
            child: const FoodReviewApp(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  testWidgets(
    'Loads real OSM place with address, category, distance, and attribution',
    (tester) async {
      // node 10098130619 is "Youone Hotdog", fast_food, with address
      final container = await mount(tester, placeId: 'osm_node_10098130619');

      expect(find.text('Youone Hotdog'), findsOneWidget);
      expect(find.text('Ăn nhanh'), findsOneWidget);
      expect(find.text('18, Phố Ô Chợ Dừa, Hà Nội'), findsOneWidget);
      expect(find.textContaining('đường chim bay'), findsOneWidget);
      expect(find.textContaining('OpenStreetMap'), findsOneWidget);
      expect(find.text('Chưa có đánh giá'), findsOneWidget);
      expect(find.text('Quán chưa cập nhật thực đơn.'), findsOneWidget);
      expect(find.text('Chưa cập nhật giá'), findsWidgets);
      expect(find.text('Xem trên bản đồ'), findsOneWidget);
      expect(find.text('Chỉ đường ngoài'), findsOneWidget);

      final router = container.read(appRouterProvider);
      await tester.ensureVisible(find.text('Xem trên bản đồ'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Xem trên bản đồ'));
      await tester.pumpAndSettle();
      expect(router.routeInformationProvider.value.uri.path, '/map');
      expect(
        router
            .routeInformationProvider
            .value
            .uri
            .queryParameters['restaurantId'],
        'osm_node_10098130619',
      );
    },
  );

  testWidgets(
    'Bottom bar Chỉ đường button navigates to map with OSM place identity',
    (tester) async {
      final container = await mount(tester, placeId: 'osm_node_10098130619');
      final router = container.read(appRouterProvider);

      await tester.tap(find.widgetWithText(FilledButton, 'Chỉ đường'));
      await tester.pumpAndSettle();
      expect(router.routeInformationProvider.value.uri.path, '/map');
      expect(
        router
            .routeInformationProvider
            .value
            .uri
            .queryParameters['restaurantId'],
        'osm_node_10098130619',
      );
    },
  );

  testWidgets('OSM place without address tags shows graceful fallback', (
    tester,
  ) async {
    // way 1330108348 is "Mikado Sushi", restaurant, without address tags
    await mount(tester, placeId: 'osm_way_1330108348');

    expect(find.text('Mikado Sushi'), findsOneWidget);
    expect(find.text('Nhà hàng'), findsOneWidget);
    expect(find.text('Chưa cập nhật địa chỉ cụ thể'), findsOneWidget);
    expect(find.textContaining('OpenStreetMap'), findsOneWidget);
  });

  testWidgets('Without active discovery center, coordinates are displayed', (
    tester,
  ) async {
    await mount(tester, placeId: 'osm_node_10098130619', withCenter: false);

    expect(find.text('Youone Hotdog'), findsOneWidget);
    expect(find.textContaining('Tọa độ: 21.0191, 105.8283'), findsOneWidget);
  });

  testWidgets('Non-existent place ID displays empty state', (tester) async {
    await mount(tester, placeId: 'osm_node_999999999999');

    expect(find.text('Quán không tồn tại.'), findsOneWidget);
  });

  testWidgets('Failed package read shows error state and allows retry', (
    tester,
  ) async {
    var fail = true;
    final flaky = OsmRegionPlaceRepository(() async {
      if (fail) throw const FormatException('Corrupted OSM package');
      return package;
    });

    await mount(tester, placeId: 'osm_node_10098130619', customRegion: flaky);

    expect(find.textContaining('Không đọc được dữ liệu quán'), findsOneWidget);

    fail = false;
    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();

    expect(find.text('Youone Hotdog'), findsOneWidget);
  });

  for (final mode in [ThemeMode.light, ThemeMode.dark]) {
    for (final width in [320.0, 390.0, 428.0]) {
      testWidgets(
        'OSM Detail renders at $width px ${mode.name} with 1.6x text scaling',
        (tester) async {
          await mount(
            tester,
            placeId: 'osm_node_10098130619',
            width: width,
            scale: 1.6,
            mode: mode,
          );

          expect(find.text('Youone Hotdog'), findsOneWidget);
          expect(tester.takeException(), isNull);

          for (var i = 0; i < 8; i++) {
            await tester.drag(
              find.byType(CustomScrollView),
              const Offset(0, -300),
            );
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
          }

          expect(find.text('Viết đánh giá').hitTestable(), findsOneWidget);
        },
      );
    }
  }

  if (const bool.fromEnvironment('DETAIL_CAPTURE')) {
    for (final mode in [ThemeMode.light, ThemeMode.dark]) {
      testWidgets('Capture OSM Restaurant Detail ${mode.name}', (tester) async {
        await mount(
          tester,
          placeId: 'osm_node_10098130619',
          height: 1800,
          mode: mode,
        );
        await tester.runAsync(() async {
          final image = await tester
              .renderObject<RenderRepaintBoundary>(find.byKey(captureKey))
              .toImage();
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          Directory('build/detail-screenshots').createSync(recursive: true);
          File('build/detail-screenshots/osm-detail-${mode.name}.png')
              .writeAsBytesSync(bytes!.buffer.asUint8List());
          image.dispose();
        });
      });
    }
  }
}
