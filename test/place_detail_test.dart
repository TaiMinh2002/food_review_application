import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:food_review/features/places/presentation/gallery_screen.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'support/auth_fixtures.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:food_review/app/food_review_app.dart';
import 'package:food_review/core/router/app_router.dart';
import 'package:food_review/core/router/route_placeholder_screen.dart';
import 'package:food_review/core/theme/theme_mode_provider.dart';
import 'package:food_review/features/favorites/presentation/favorite_providers.dart';
import 'package:food_review/features/places/domain/place.dart';
import 'package:food_review/features/places/domain/place_repository.dart';
import 'package:food_review/features/places/presentation/place_providers.dart';
import 'package:food_review/features/places/presentation/map_controller.dart';
import 'package:food_review/features/places/presentation/place_detail_overview.dart';
import 'package:food_review/features/reviews/domain/review.dart';
import 'package:food_review/shared/widgets/app_review_card.dart';
import 'package:food_review/features/reviews/domain/review_repository.dart';
import 'package:food_review/features/reviews/presentation/review_providers.dart';

void main() {
  final captureKey = GlobalKey();
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
    double width = 390,
    double height = 844,
    double scale = 1,
    ThemeMode mode = ThemeMode.light,
    PlaceRepository? places,
    ReviewRepository? reviews,
    bool settle = true,
    bool safeInsets = false,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = Size(width, height);
    if (safeInsets) {
      tester.view.padding = const FakeViewPadding(top: 44, bottom: 24);
    }
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPadding);
    final container = ProviderContainer(
      overrides: [
        signedInSession,
        mapTilesEnabledProvider.overrideWithValue(false),
        if (places != null) placeRepositoryProvider.overrideWithValue(places),
        if (reviews != null)
          reviewRepositoryProvider.overrideWithValue(reviews),
      ],
    );
    addTearDown(container.dispose);
    container.read(themeModeProvider.notifier).setMode(mode);
    container.read(appRouterProvider).go('/restaurants/pho-demo');
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: RepaintBoundary(
          key: captureKey,
          child: MediaQuery(
            data: MediaQueryData(
              textScaler: TextScaler.linear(scale),
              padding: safeInsets
                  ? const EdgeInsets.only(top: 44, bottom: 24)
                  : EdgeInsets.zero,
              viewPadding: safeInsets
                  ? const EdgeInsets.only(top: 44, bottom: 24)
                  : EdgeInsets.zero,
            ),
            child: const FoodReviewApp(),
          ),
        ),
      ),
    );
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump();
    }
    return container;
  }

  for (final mode in [ThemeMode.light, ThemeMode.dark]) {
    for (final width in [320.0, 390.0, 428.0]) {
      testWidgets(
        'Detail scrolls with safe insets, 1.6x text, $width ${mode.name}',
        (tester) async {
          await mount(
            tester,
            width: width,
            scale: 1.6,
            mode: mode,
            safeInsets: true,
          );
          expect(find.text('Phở Nhà Mình'), findsOneWidget);
          expect(tester.takeException(), isNull);
          for (var i = 0; i < 12; i++) {
            await tester.drag(
              find.byType(CustomScrollView),
              const Offset(0, -300),
            );
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
          }
          expect(find.text('Viết đánh giá').hitTestable(), findsOneWidget);
          final button = tester.getRect(
            find.widgetWithText(FilledButton, 'Chỉ đường'),
          );
          expect(button.bottom, lessThanOrEqualTo(844 - 24));
        },
      );
    }
  }

  testWidgets(
    'Saving from toolbar updates quick action and shared favorite state',
    (tester) async {
      final container = await mount(tester);
      await tester.tap(find.byTooltip('Lưu yêu thích'));
      await tester.pumpAndSettle();
      expect(container.read(favoriteIdsProvider), contains('pho-demo'));
      expect(find.text('Bỏ yêu thích'), findsOneWidget);
      await tester.ensureVisible(find.text('Bỏ yêu thích'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bỏ yêu thích'));
      await tester.pumpAndSettle();
      expect(container.read(favoriteIdsProvider), isNot(contains('pho-demo')));
      expect(find.byTooltip('Lưu yêu thích'), findsOneWidget);
    },
  );

  testWidgets('Gallery preserves the swiped photo index and detail on Back', (
    tester,
  ) async {
    await mount(tester);
    await tester.drag(find.byType(PageView), const Offset(-350, 0));
    await tester.pumpAndSettle();
    expect(find.text('2/4 ảnh'), findsOneWidget);
    await tester.tap(find.text('2/4 ảnh'));
    await tester.pumpAndSettle();
    final state = GoRouterState.of(tester.element(find.byType(GalleryScreen)));
    expect(state.uri.path, '/restaurants/pho-demo/gallery');
    expect(state.uri.queryParameters['index'], '1');
    expect(find.text('2 / 7'), findsOneWidget);
    await tester.tap(find.byTooltip('Đóng ảnh'));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('2/4 ảnh'), findsOneWidget);
  });

  testWidgets(
    'Menu shortcut scrolls to dishes and opens information, not an order',
    (tester) async {
      await mount(tester);
      await tester.ensureVisible(find.text('Thực đơn'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Thực đơn'));
      await tester.pumpAndSettle();
      expect(find.text('Món ăn nổi bật').hitTestable(), findsOneWidget);
      await tester.ensureVisible(
        find.byTooltip('Thông tin món Phở Bò Tái Lăn'),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Thông tin món Phở Bò Tái Lăn'));
      await tester.pumpAndSettle();
      expect(
        find.text('Món và giá minh họa · Không hỗ trợ đặt món.'),
        findsOneWidget,
      );
    },
  );

  testWidgets('Review, report and map CTAs keep the restaurant identity', (
    tester,
  ) async {
    final container = await mount(tester);
    final router = container.read(appRouterProvider);
    await tester.tap(find.byTooltip('Tùy chọn quán'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Báo cáo quán'));
    await tester.pumpAndSettle();
    var state = GoRouterState.of(
      tester.element(find.byType(RoutePlaceholderScreen)),
    );
    expect(state.uri.path, '/reports/create');
    expect(state.uri.queryParameters, {
      'targetType': 'place',
      'restaurantId': 'pho-demo',
    });
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Viết đánh giá'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Viết đánh giá'));
    await tester.pumpAndSettle();
    state = GoRouterState.of(
      tester.element(find.byType(RoutePlaceholderScreen)),
    );
    expect(state.uri.path, '/restaurants/pho-demo/reviews/create');
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Chỉ đường'));
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, '/map');
    expect(
      router.routeInformationProvider.value.uri.queryParameters['restaurantId'],
      'pho-demo',
    );
  });

  testWidgets('Share copies the real name, address and internal route', (
    tester,
  ) async {
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String;
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await mount(tester);
    await tester.tap(find.byTooltip('Chia sẻ quán'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sao chép thông tin'));
    await tester.pumpAndSettle();
    expect(copied, contains('Phở Nhà Mình'));
    expect(copied, contains('/restaurants/pho-demo'));
    expect(find.text('Đã sao chép thông tin quán.'), findsOneWidget);
  });

  testWidgets(
    'Place failure retries, pending loads, and absent ID has no action bar',
    (tester) async {
      final result = Completer<Place?>();
      final repository = _PlaceRepository(result: result.future);
      final container = await mount(tester, places: repository, settle: false);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      result.completeError(StateError('private backend failure'));
      await tester.pumpAndSettle();
      expect(find.text('Không tải được thông tin quán.'), findsOneWidget);
      expect(find.textContaining('private backend'), findsNothing);
      await tester.tap(find.text('Thử lại'));
      await tester.pumpAndSettle();
      expect(repository.calls, 2);
      expect(find.text('Quán không tồn tại.'), findsOneWidget);
      expect(find.byType(PlaceDetailPriceBar), findsNothing);
      container.read(appRouterProvider).go('/restaurants/absent');
      await tester.pumpAndSettle();
      expect(find.text('Quán không tồn tại.'), findsOneWidget);
    },
  );

  testWidgets('Missing metadata, images and reviews display fallbacks', (
    tester,
  ) async {
    const place = Place(
      id: 'pho-demo',
      name: 'Quán thiếu dữ liệu',
      description: '',
      address: 'Địa chỉ minh họa',
      category: 'Món Việt',
      latitude: 0,
      longitude: 0,
    );
    await mount(tester, places: _PlaceRepository(place: place));
    expect(find.text('Chưa cập nhật giờ phục vụ'), findsOneWidget);
    expect(find.text('Chưa có đánh giá'), findsOneWidget);
    expect(find.text('Chưa cập nhật giá'), findsNWidgets(2));
    expect(find.textContaining('Bản demo'), findsNothing);
    await tester.ensureVisible(find.text('Quán chưa cập nhật thực đơn.'));
    await tester.pumpAndSettle();
    expect(find.text('Chưa có mô tả về quán.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Review failure is isolated, retry is bounded to two preview entries',
    (tester) async {
      final reviews = _ReviewRepository();
      await mount(tester, reviews: reviews);
      expect(find.text('Phở Nhà Mình'), findsOneWidget);
      await tester.ensureVisible(find.text('Không tải được đánh giá.'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Thử lại'));
      await tester.pumpAndSettle();
      expect(reviews.calls, 2);
      expect(reviews.requestedLimit, 2);
      expect(
        find.text('Chưa có nội dung đánh giá để xem trước.'),
        findsOneWidget,
      );
    },
  );

  testWidgets('Broken gallery asset keeps detail content and fallback usable', (
    tester,
  ) async {
    const place = Place(
      id: 'pho-demo',
      name: 'Quán có ảnh lỗi',
      description: 'Mô tả còn hiển thị',
      address: 'Địa chỉ minh họa',
      category: 'Món Việt',
      latitude: 0,
      longitude: 0,
      imageUrls: ['assets/images/demo/not_found.jpg'],
    );
    await mount(tester, places: _PlaceRepository(place: place));
    expect(find.text('Quán có ảnh lỗi'), findsOneWidget);
    expect(find.text('1/1 ảnh'), findsOneWidget);
    expect(find.byIcon(Icons.restaurant_outlined), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Preview review reporting retains both restaurant and review IDs',
    (tester) async {
      await mount(tester);
      final more = find.descendant(
        of: find.byType(AppReviewCard).first,
        matching: find.byTooltip('Tùy chọn nhận xét'),
      );
      await tester.ensureVisible(more);
      await tester.pumpAndSettle();
      await tester.tap(more);
      await tester.pumpAndSettle();
      final state = GoRouterState.of(
        tester.element(find.byType(RoutePlaceholderScreen)),
      );
      expect(state.uri.path, '/reports/create');
      expect(state.uri.queryParameters, {
        'targetType': 'review',
        'restaurantId': 'pho-demo',
        'reviewId': 'review-linh-demo',
      });
    },
  );

  if (const bool.fromEnvironment('DETAIL_CAPTURE')) {
    for (final mode in [ThemeMode.light, ThemeMode.dark]) {
      testWidgets('Capture detail ${mode.name}', (tester) async {
        await mount(tester, height: 2553, mode: mode);
        await tester.runAsync(() async {
          final context = tester.element(find.byType(FoodReviewApp));
          for (final file in Directory(
            'assets/images/demo',
          ).listSync().whereType<File>()) {
            await precacheImage(AssetImage(file.path), context);
          }
        });
        await tester.pumpAndSettle();
        await tester.runAsync(() async {
          final image = await tester
              .renderObject<RenderRepaintBoundary>(find.byKey(captureKey))
              .toImage();
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          Directory('build/detail-screenshots').createSync(recursive: true);
          File('build/detail-screenshots/detail-${mode.name}.png')
              .writeAsBytesSync(bytes!.buffer.asUint8List());
          image.dispose();
        });
      });
    }
  }
}

class _PlaceRepository implements PlaceRepository {
  _PlaceRepository({this.place, this.result});
  final Place? place;
  final Future<Place?>? result;
  int calls = 0;
  @override
  Future<List<Place>> fetchPlaces() async => [?place];
  @override
  Future<Place?> getPlace(String id) {
    calls++;
    return calls == 1 && result != null ? result! : Future.value(place);
  }
}

class _ReviewRepository implements ReviewRepository {
  int calls = 0;
  int? requestedLimit;
  @override
  Stream<List<Review>> watchForPlace(String id, {int limit = 20}) {
    requestedLimit = limit;
    return ++calls == 1
        ? Stream.error(StateError('internal review failure'))
        : Stream.value([]);
  }

  @override
  Future<void> create(Review review) async => throw UnimplementedError();
}
