import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:food_review/app/food_review_app.dart';
import 'package:food_review/app/app_permissions_startup.dart';
import 'package:food_review/core/errors/app_exception.dart';
import 'package:food_review/core/router/app_router.dart';
import 'package:food_review/core/theme/theme_mode_provider.dart';
import 'package:food_review/features/places/data/device_location_repository.dart';
import 'package:food_review/features/places/domain/place_map_repository.dart';
import 'package:food_review/features/places/presentation/map_controller.dart';
import 'package:food_review/features/places/presentation/map_widgets.dart';
import 'package:food_review/features/places/presentation/user_location_controller.dart';

class StartupLocation extends GeolocatorPlatform {
  bool enabled = true;
  LocationPermission permission = LocationPermission.denied;
  LocationPermission response = LocationPermission.whileInUse;
  int requests = 0, fixes = 0;
  Object? error;
  LocationSettings? settings;

  @override
  Future<bool> isLocationServiceEnabled() async => enabled;
  @override
  Future<LocationPermission> checkPermission() async => permission;
  @override
  Future<LocationPermission> requestPermission() async {
    requests++;
    return permission = response;
  }

  @override
  Future<Position> getCurrentPosition({
    LocationSettings? locationSettings,
  }) async {
    fixes++;
    settings = locationSettings;
    if (error != null) throw error!;
    return Position(
      longitude: 105.8342,
      latitude: 21.0278,
      timestamp: DateTime(2026),
      accuracy: 10,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    );
  }
}

class ControlledLocation implements UserLocationRepository {
  int calls = 0;
  GeoPoint point = const GeoPoint(21.0278, 105.8342);
  Completer<GeoPoint>? pending;
  Object? error;
  bool settingsOpened = true;

  @override
  Future<GeoPoint> locate() async {
    calls++;
    if (error != null) throw error!;
    return pending?.future ?? point;
  }

  @override
  Future<bool> openSettings() async => settingsOpened;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Device foreground location', () {
    late StartupLocation platform;
    late GeolocatorPlatform original;
    setUp(() {
      original = GeolocatorPlatform.instance;
      platform = StartupLocation();
      GeolocatorPlatform.instance = platform;
    });
    tearDown(() => GeolocatorPlatform.instance = original);

    test(
      'first access requests permission and returns the device fix',
      () async {
        final point = await DeviceLocationRepository().locate();
        expect(platform.requests, 1);
        expect(platform.fixes, 1);
        expect(point.latitude, 21.0278);
        expect(point.longitude, 105.8342);
        expect(platform.settings?.timeLimit, const Duration(seconds: 15));
        await DeviceLocationRepository().locate();
        expect(
          platform.requests,
          1,
          reason: 'Already granted: no repeated prompt',
        );
      },
    );

    test(
      'denied, permanently denied and disabled GPS never produce a fix',
      () async {
        final repository = DeviceLocationRepository();
        platform.response = LocationPermission.denied;
        await expectLater(repository.locate(), throwsA(isA<AppException>()));
        platform.permission = LocationPermission.deniedForever;
        await expectLater(repository.locate(), throwsA(isA<AppException>()));
        expect(platform.requests, 1);
        platform.permission = LocationPermission.whileInUse;
        platform.enabled = false;
        await expectLater(repository.locate(), throwsA(isA<AppException>()));
        expect(platform.fixes, 0);
      },
    );

    test('GPS timeout returns a safe retry message', () async {
      platform.error = TimeoutException('GPS timeout');
      await expectLater(
        DeviceLocationRepository().locate(),
        throwsA(
          isA<AppException>().having(
            (value) => value.message,
            'message',
            contains('Vui lòng thử lại'),
          ),
        ),
      );
    });
  });

  test(
    'startup initializes once, shares Map state and guards duplicate requests',
    () async {
      final source = ControlledLocation()..pending = Completer<GeoPoint>();
      final container = ProviderContainer(
        overrides: [userLocationRepositoryProvider.overrideWithValue(source)],
      );
      addTearDown(container.dispose);
      final controller = container.read(
        userLocationControllerProvider.notifier,
      );
      final pending = controller.initialize();
      await controller.initialize();
      expect(
        await container.read(placeMapControllerProvider.notifier).locate(),
        isNull,
      );
      expect(source.calls, 1);
      expect(container.read(placeMapControllerProvider).locating, isTrue);
      source.pending!.complete(source.point);
      await pending;
      expect(
        container.read(placeMapControllerProvider).location,
        same(source.point),
      );
      source.error = const AppException('Quyền vị trí đã bị chặn.');
      await controller.locate();
      expect(container.read(userLocationControllerProvider).point, isNull);
      expect(container.read(placeMapControllerProvider).location, isNull);
    },
  );

  test(
    'return from Settings refreshes once; unrelated resumes do not request GPS',
    () async {
      final source = ControlledLocation();
      final container = ProviderContainer(
        overrides: [userLocationRepositoryProvider.overrideWithValue(source)],
      );
      addTearDown(container.dispose);
      final controller = container.read(
        userLocationControllerProvider.notifier,
      );
      await controller.resumeFromSettings();
      expect(source.calls, 0);
      await controller.openSettings();
      await controller.resumeFromSettings();
      await controller.resumeFromSettings();
      expect(source.calls, 1);
      source.settingsOpened = false;
      await controller.openSettings();
      await controller.resumeFromSettings();
      expect(source.calls, 1);
    },
  );

  test('an invalid fix never becomes the user location', () async {
    final source = ControlledLocation()..point = const GeoPoint(double.nan, 0);
    final container = ProviderContainer(
      overrides: [userLocationRepositoryProvider.overrideWithValue(source)],
    );
    addTearDown(container.dispose);
    await container.read(userLocationControllerProvider.notifier).initialize();
    expect(container.read(userLocationControllerProvider).point, isNull);
    expect(container.read(userLocationControllerProvider).error, isNotNull);
  });

  testWidgets(
    'app requests GPS on first frame and Map opens at the same real fix',
    (tester) async {
      final source = ControlledLocation()..pending = Completer<GeoPoint>();
      final container = ProviderContainer(
        overrides: [
          userLocationRepositoryProvider.overrideWithValue(source),
          mapTilesEnabledProvider.overrideWithValue(false),
        ],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const AppPermissionsStartup(child: FoodReviewApp()),
        ),
      );
      await tester.pump();
      expect(source.calls, 1);
      expect(find.text('Đang lấy vị trí hiện tại…'), findsOneWidget);
      expect(find.text('TP. Hồ Chí Minh · Vị trí minh họa'), findsNothing);
      source.pending!.complete(source.point);
      await tester.pumpAndSettle();
      expect(find.text('Vị trí hiện tại · 21.0278, 105.8342'), findsOneWidget);
      container.read(themeModeProvider.notifier).setMode(ThemeMode.dark);
      await tester.pumpAndSettle();
      expect(source.calls, 1);
      container.read(appRouterProvider).go('/map');
      await tester.pumpAndSettle();
      final canvas = tester.widget<PlaceMapCanvas>(find.byType(PlaceMapCanvas));
      expect(
        canvas.controller.camera.center.latitude,
        closeTo(21.0278, 0.00001),
      );
      expect(
        canvas.controller.camera.center.longitude,
        closeTo(105.8342, 0.00001),
      );
      expect(
        canvas.places,
        isEmpty,
        reason: 'Demo restaurants are in HCMC, not near the Hanoi fix',
      );
      expect(source.calls, 1);
      expect(tester.takeException(), isNull);
      source.pending = null;
      source.point = const GeoPoint(16.0544, 108.2022);
      await container
          .read(userLocationControllerProvider.notifier)
          .openSettings();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(source.calls, 2);
      expect(
        canvas.controller.camera.center.latitude,
        closeTo(16.0544, 0.00001),
      );
      expect(
        canvas.controller.camera.center.longitude,
        closeTo(108.2022, 0.00001),
      );
    },
  );

  for (final mode in [ThemeMode.light, ThemeMode.dark]) {
    testWidgets(
      'denied startup stays usable at 320px and large text in ${mode.name}',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(320, 760);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final source = ControlledLocation()
          ..error = const AppException('Quyền vị trí đã bị chặn.');
        final container = ProviderContainer(
          overrides: [
            userLocationRepositoryProvider.overrideWithValue(source),
            mapTilesEnabledProvider.overrideWithValue(false),
          ],
        );
        addTearDown(container.dispose);
        container.read(themeModeProvider.notifier).setMode(mode);
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MediaQuery(
              data: MediaQueryData(textScaler: TextScaler.linear(1.6)),
              child: AppPermissionsStartup(child: FoodReviewApp()),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Quyền vị trí đã bị chặn.'), findsOneWidget);
        expect(find.text('Hôm nay ăn gì?'), findsOneWidget);
        expect(container.read(userLocationControllerProvider).point, isNull);
        expect(tester.takeException(), isNull);
        container.read(appRouterProvider).go('/map');
        await tester.pumpAndSettle();
        expect(find.byType(PlaceMapCanvas), findsNothing);
        expect(find.text('Cài đặt vị trí'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
