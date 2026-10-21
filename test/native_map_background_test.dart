import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:maplibre_gl/maplibre_gl.dart' as native;
import 'package:food_review/core/theme/app_theme.dart';
import 'package:food_review/features/places/presentation/map_widgets.dart';
import 'package:food_review/features/places/presentation/native_map_background.dart';

class BasemapPlatform extends native.MapLibrePlatform {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  final moves = <native.CameraUpdate>[];
  Completer<bool?>? pending;

  @override
  Widget buildView(
    Map<String, dynamic> creationParams,
    native.OnPlatformViewCreatedCallback onPlatformViewCreated,
    Set<Factory<OneSequenceGestureRecognizer>>? gestureRecognizers,
  ) => const SizedBox.expand();

  @override
  Future<bool?> moveCamera(native.CameraUpdate cameraUpdate) async {
    moves.add(cameraUpdate);
    return pending?.future ?? true;
  }
}

void main() {
  late BasemapPlatform platform;
  setUp(() {
    platform = BasemapPlatform();
    final original = native.MapLibrePlatform.createInstance;
    native.MapLibrePlatform.createInstance = () => platform;
    addTearDown(() => native.MapLibrePlatform.createInstance = original);
  });

  Future<MapController> mount(WidgetTester tester, {bool dark = false}) async {
    final controller = MapController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: dark ? ThemeMode.dark : ThemeMode.light,
        home: Scaffold(
          body: PlaceMapCanvas(
            controller: controller,
            center: const LatLng(21.0278, 105.8342),
            places: const [],
            selectedId: null,
            tilesEnabled: true,
            onSelect: (_) {},
            onReady: () {},
            onMoved: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return controller;
  }

  testWidgets(
    'online map uses native vector source, preserves GPS ownership and credits',
    (tester) async {
      await mount(tester);
      final map = tester.widget<native.MapLibreMap>(
        find.byType(native.MapLibreMap),
      );
      expect(map.styleString, 'https://tiles.openfreemap.org/styles/liberty');
      expect(
        map.initialCameraPosition!.target,
        const native.LatLng(21.0278, 105.8342),
      );
      expect(map.initialCameraPosition!.zoom, 13);
      expect(map.myLocationEnabled, isFalse);
      expect(find.byType(TileLayer), findsNothing);
      expect(find.text('OpenFreeMap'), findsOneWidget);
      expect(find.text('© OpenMapTiles'), findsOneWidget);
      expect(find.text('© OpenStreetMap'), findsOneWidget);
      expect(find.text('Đang tải bản đồ…'), findsOneWidget);
      map.onMapIdle!();
      await tester.pump();
      expect(find.text('Đang tải bản đồ…'), findsNothing);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'native camera follows Flutter pan and zoom and coalesces pending movements',
    (tester) async {
      final camera = await mount(tester);
      final nativeController = native.MapLibreMapController(
        maplibrePlatform: platform,
        annotationOrder: const [],
        annotationConsumeTapEvents: const [],
      );
      addTearDown(nativeController.dispose);
      tester
          .widget<native.MapLibreMap>(find.byType(native.MapLibreMap))
          .onMapCreated!(nativeController);
      platform.pending = Completer<bool?>();
      camera.move(const LatLng(16.0544, 108.2022), 15);
      await tester.pump();
      camera.move(const LatLng(10.7769, 106.7009), 16);
      await tester.pump();
      platform.pending!.complete(true);
      await tester.pumpAndSettle();
      final last = platform.moves.last.toJson() as List;
      expect(last.first, 'newCameraPosition');
      expect((last[1] as Map)['target'], [
        closeTo(10.7769, 1e-9),
        closeTo(106.7009, 1e-9),
      ]);
      expect((last[1] as Map)['zoom'], 15);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'dark basemap timeout offers retry without replacing the camera',
    (tester) async {
      final camera = await mount(tester, dark: true);
      expect(
        Theme.of(tester.element(find.byType(NativeMapBackground))).brightness,
        Brightness.dark,
      );
      expect(
        tester
            .widget<native.MapLibreMap>(find.byType(native.MapLibreMap))
            .styleString,
        'https://tiles.openfreemap.org/styles/liberty',
      );
      camera.move(const LatLng(16.0544, 108.2022), 15);
      await tester.pump(const Duration(seconds: 26));
      await tester.pump();
      expect(find.text('Không tải được nền bản đồ.'), findsOneWidget);
      await tester.tap(find.text('Thử lại'));
      await tester.pumpAndSettle();
      expect(find.text('Không tải được nền bản đồ.'), findsNothing);
      expect(camera.camera.center, const LatLng(16.0544, 108.2022));
      expect(
        tester
            .widget<native.MapLibreMap>(find.byType(native.MapLibreMap))
            .initialCameraPosition!
            .target,
        const native.LatLng(16.0544, 108.2022),
      );
      expect(find.byType(NativeMapBackground), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
