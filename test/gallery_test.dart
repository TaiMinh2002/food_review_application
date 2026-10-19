import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_review/app/food_review_app.dart';
import 'package:food_review/core/errors/app_exception.dart';
import 'package:food_review/core/router/app_router.dart';
import 'package:food_review/core/theme/theme_mode_provider.dart';
import 'package:food_review/features/places/data/demo_place_repository.dart';
import 'package:food_review/features/places/data/demo_place_fixtures.dart';
import 'package:food_review/features/places/data/place_gallery_repository.dart';
import 'package:food_review/features/places/domain/gallery.dart';
import 'package:food_review/features/places/domain/gallery_repository.dart';
import 'package:food_review/features/places/domain/place.dart';
import 'package:food_review/features/places/domain/place_repository.dart';
import 'package:food_review/features/places/presentation/gallery_providers.dart';
import 'package:food_review/features/places/presentation/gallery_widgets.dart';
import 'package:food_review/features/places/presentation/map_controller.dart';
import 'package:food_review/features/places/presentation/place_providers.dart';
import 'package:food_review/features/reviews/data/demo_review_repository.dart';

class PendingGallery implements GalleryRepository {
  final requests = <GalleryRequest>[];
  final responses = <Completer<GalleryCollection>>[];
  @override
  Future<GalleryCollection> getPhotos(Place place, GalleryRequest request) {
    requests.add(request);
    final result = Completer<GalleryCollection>();
    responses.add(result);
    return result.future;
  }
}

void main() {
  final key = GlobalKey();
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
    String route = '/restaurants/pho-demo/gallery',
    PlaceRepository? places,
    GalleryRepository? gallery,
  }) async {
    tester.view.physicalSize = Size(width, height);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final container = ProviderContainer(
      overrides: [
        mapTilesEnabledProvider.overrideWithValue(false),
        if (places != null) placeRepositoryProvider.overrideWithValue(places),
        if (gallery != null)
          galleryRepositoryProvider.overrideWithValue(gallery),
      ],
    );
    addTearDown(container.dispose);
    container.read(themeModeProvider.notifier).setMode(mode);
    container.read(appRouterProvider).go(route);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: RepaintBoundary(
          key: key,
          child: MediaQuery.fromView(
            view: tester.view,
            child: Builder(
              builder: (context) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.linear(scale),
                  disableAnimations: true,
                  padding: const EdgeInsets.only(top: 44, bottom: 24),
                  viewPadding: const EdgeInsets.only(top: 44, bottom: 24),
                ),
                child: const FoodReviewApp(),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  Finder scroll() => find
      .descendant(
        of: find.byType(CustomScrollView).first,
        matching: find.byType(Scrollable),
      )
      .first;
  Future<void> reveal(WidgetTester tester, Finder finder) async {
    await tester.scrollUntilVisible(finder, 180, scrollable: scroll());
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
  }

  test(
    'Gallery preserves detail photo order and appends metadata once',
    () async {
      final place = DemoPlaceRepository.places.first;
      final gallery = await PlaceGalleryRepository(DemoReviewRepository())
          .getPhotos(place, const GalleryRequest(placeId: 'pho-demo'));
      expect(gallery.photos.length, 7);
      expect(gallery.photos.take(4).map((p) => p.url), place.imageUrls);
      expect(
        gallery.photos.where((p) => p.category == PhotoCategory.space).length,
        2,
      );
      expect(() => gallery.photos.clear(), throwsUnsupportedError);
      expect(gallery.safeIndex(-3), 0);
      expect(gallery.safeIndex(1000), 6);
      expect(GalleryCollection([]).safeIndex(4), 0);
      final duplicate = Place(
        id: 'p',
        name: 'p',
        description: '',
        address: '',
        category: '',
        latitude: 0,
        longitude: 0,
        imageUrls: ['a', 'a', ''],
      );
      final result = await PlaceGalleryRepository(DemoReviewRepository())
          .getPhotos(duplicate, const GalleryRequest(placeId: 'p'));
      expect(result.photos.map((p) => p.url), ['a', 'a', '']);
    },
  );

  test(
    'Review lookup is exact, scoped and independent of preview limit',
    () async {
      final repo = PlaceGalleryRepository(DemoReviewRepository());
      final place = DemoPlaceRepository.places.first;
      final photos = await repo.getPhotos(
        place,
        const GalleryRequest(
          placeId: 'pho-demo',
          fromReview: true,
          reviewId: 'review-chau-demo',
        ),
      );
      expect(photos.photos.single.author, 'Minh Châu');
      expect(photos.photos.single.url, 'assets/images/demo/dish_chin.jpg');
      expect(
        () => repo.getPhotos(place, const GalleryRequest(placeId: 'other')),
        throwsA(isA<AppException>()),
      );
      expect(
        () => repo.getPhotos(
          place,
          const GalleryRequest(placeId: 'pho-demo', fromReview: true),
        ),
        throwsA(isA<AppException>()),
      );
      expect(
        () => repo.getPhotos(
          DemoPlaceRepository.places[1],
          const GalleryRequest(
            placeId: 'coffee-demo',
            fromReview: true,
            reviewId: 'review-chau-demo',
          ),
        ),
        throwsA(isA<AppException>()),
      );
    },
  );

  test('Index URI parses safely and scope participates in identity', () {
    for (final value in ['abc', '', '1.2']) {
      expect(GalleryRequest.fromUri('p', Uri.parse('/?index=$value')).index, 0);
    }
    expect(GalleryRequest.fromUri('p', Uri.parse('/')).index, isNull);
    expect(
      GalleryRequest.fromUri(
        'p',
        Uri.parse('/?source=review&reviewId=r&index=1'),
      ),
      const GalleryRequest(
        placeId: 'p',
        fromReview: true,
        reviewId: 'r',
        index: 1,
      ),
    );
    expect(
      const GalleryRequest(placeId: 'p'),
      isNot(const GalleryRequest(placeId: 'q')),
    );
  });

  for (final mode in [ThemeMode.light, ThemeMode.dark]) {
    for (final width in [320.0, 390.0, 428.0]) {
      for (final scale in [1.0, 1.6]) {
        testWidgets(
          'Gallery and viewer fit $width at ${scale}x in ${mode.name}',
          (tester) async {
            await mount(tester, width: width, scale: scale, mode: mode);
            expect(find.byType(NavigationBar), findsNothing);
            expect(tester.takeException(), isNull);
            await tester.tap(find.byTooltip('Xem ảnh nổi bật'));
            await tester.pumpAndSettle();
            expect(find.text('1 / 7'), findsWidgets);
            await tester.drag(
              find.byKey(const ValueKey('gallery-pages')),
              const Offset(-350, 0),
            );
            await tester.pumpAndSettle();
            expect(find.text('2 / 7'), findsOneWidget);
            expect(find.byType(InteractiveViewer), findsWidgets);
            expect(tester.takeException(), isNull);
            await tester.tap(find.byTooltip('Đóng ảnh'));
            await tester.pumpAndSettle();
            await reveal(tester, find.text('Đăng ảnh'));
            expect(tester.takeException(), isNull);
          },
        );
      }
    }
  }

  testWidgets(
    'Filter opens matching subset, preserves grid scroll and share index',
    (tester) async {
      await mount(tester);
      final chip = find.text('Không gian (2)');
      await tester.ensureVisible(chip);
      await tester.tap(chip);
      await tester.pumpAndSettle();
      await reveal(tester, find.byType(GalleryTile).first);
      final tiles = tester.widgetList<GalleryTile>(find.byType(GalleryTile));
      expect(tiles.length, 2);
      expect(
        tiles.every((tile) => tile.photo.category == PhotoCategory.space),
        isTrue,
      );
      final position = tester.state<ScrollableState>(scroll()).position;
      final before = position.pixels;
      await tester.tap(find.byType(GalleryTile).first);
      await tester.pumpAndSettle();
      expect(find.text('1 / 2'), findsOneWidget);
      await tester.tap(find.byTooltip('Chia sẻ ảnh'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('/restaurants/pho-demo/gallery?index=4'),
        findsOneWidget,
      );
      // Close share then lightbox; the grid's scroll/filter remain unchanged.
      Navigator.of(tester.element(find.text('Chia sẻ quán'))).pop();
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Đóng ảnh'));
      await tester.pumpAndSettle();
      expect(position.pixels, before);
      expect(
        tester
            .widgetList<GalleryTile>(find.byType(GalleryTile))
            .every((tile) => tile.photo.category == PhotoCategory.space),
        isTrue,
      );
    },
  );

  for (final index in ['-10', '999', 'bad']) {
    testWidgets('Direct index $index clamps and closes to gallery', (
      tester,
    ) async {
      await mount(tester, route: '/restaurants/pho-demo/gallery?index=$index');
      expect(find.byKey(const ValueKey('gallery-counter')), findsOneWidget);
      expect(find.text(index == '999' ? '7 / 7' : '1 / 7'), findsWidgets);
      await tester.tap(find.byTooltip('Đóng ảnh'));
      await tester.pumpAndSettle();
      expect(find.byType(GalleryFeatured), findsOneWidget);
    });
  }

  testWidgets(
    'Missing review does not silently fall back to restaurant photos',
    (tester) async {
      await mount(
        tester,
        route: '/restaurants/pho-demo/gallery?source=review&reviewId=missing&index=0',
      );
      expect(
        find.text('Không tìm thấy đánh giá của quán này.'),
        findsOneWidget,
      );
      expect(find.byType(GalleryFeatured), findsNothing);
      expect(find.byType(PageView), findsNothing);
    },
  );

  testWidgets('No photos and missing restaurant keep distinct states', (
    tester,
  ) async {
    final container = await mount(
      tester,
      places: DemoPlaceRepository(data: DemoPlaceFixtures.withoutImages),
    );
    expect(find.text('Chưa có ảnh'), findsOneWidget);
    container.read(appRouterProvider).go('/restaurants/missing/gallery');
    await tester.pumpAndSettle();
    expect(find.text('Không tìm thấy quán.'), findsOneWidget);
  });

  testWidgets(
    'Photo failure stays usable with retry and contribution explains pending integration',
    (tester) async {
      await mount(
        tester,
        places: DemoPlaceRepository(data: DemoPlaceFixtures.brokenImages),
        route: '/restaurants/pho-demo/gallery?index=0',
      );
      expect(find.text('Không tải được ảnh'), findsWidgets);
      await tester.tap(find.byTooltip('Thử tải lại ảnh').last);
      await tester.pumpAndSettle();
      expect(find.byTooltip('Đóng ảnh'), findsOneWidget);
      await tester.tap(find.byTooltip('Đóng ảnh'));
      await tester.pumpAndSettle();
      await reveal(tester, find.text('Đăng ảnh'));
      await tester.tap(find.text('Đăng ảnh'));
      await tester.pumpAndSettle();
      expect(find.textContaining('hiện chưa gửi hay lưu ảnh'), findsOneWidget);
      await tester.tap(find.text('Mở màn viết đánh giá'));
      await tester.pumpAndSettle();
      expect(find.text('Chức năng chưa triển khai · T13.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Loading retry and route change ignore old gallery completion', (
    tester,
  ) async {
    final gallery = PendingGallery();
    final container = await mount(tester, gallery: gallery);
    expect(gallery.requests.length, 1);
    gallery.responses.first.completeError(
      const AppException('Lỗi ảnh thử nghiệm'),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();
    expect(gallery.requests.length, 2);
    container.read(appRouterProvider).go('/restaurants/coffee-demo/gallery');
    await tester.pumpAndSettle();
    expect(gallery.requests.last.placeId, 'coffee-demo');
    gallery.responses[1].complete(
      GalleryCollection([
        const GalleryPhoto(url: 'assets/images/demo/pho.jpg', title: 'STALE'),
      ]),
    );
    gallery.responses.last.complete(
      GalleryCollection([
        const GalleryPhoto(
          url: 'assets/images/demo/coffee.jpg',
          title: 'Coffee',
        ),
      ]),
    );
    await tester.pumpAndSettle();
    expect(find.text('STALE'), findsNothing);
    expect(find.text('Coffee'), findsOneWidget);
  });

  testWidgets(
    'Missing place never queries gallery and direct Back returns Home',
    (tester) async {
      final gallery = PendingGallery();
      final container = await mount(
        tester,
        gallery: gallery,
        route: '/restaurants/missing/gallery',
      );
      expect(gallery.requests, isEmpty);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(container.read(appRouterProvider).state.uri.path, '/home');
    },
  );

  testWidgets('Viewer fits a short landscape viewport with large text', (
    tester,
  ) async {
    await mount(
      tester,
      width: 844,
      height: 390,
      scale: 1.6,
      route: '/restaurants/pho-demo/gallery?index=2',
    );
    expect(find.byTooltip('Đóng ảnh'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.byTooltip('Ảnh sau'));
    await tester.pumpAndSettle();
    expect(find.text('4 / 7'), findsOneWidget);
  });

  if (const bool.fromEnvironment('GALLERY_CAPTURE')) {
    for (final mode in [ThemeMode.light, ThemeMode.dark]) {
      testWidgets('Capture Gallery ${mode.name}', (tester) async {
        await mount(tester, height: 1400, mode: mode);
        tester
            .renderObject<RenderRepaintBoundary>(find.byKey(key))
            .markNeedsPaint();
        await tester.pump();
        await tester.runAsync(() async {
          final image = await tester
              .renderObject<RenderRepaintBoundary>(find.byKey(key))
              .toImage();
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          final directory = Directory('build/gallery-screenshots')
            ..createSync(recursive: true);
          File('${directory.path}/gallery-${mode.name}.png')
              .writeAsBytesSync(bytes!.buffer.asUint8List());
          image.dispose();
        });
        await tester.tap(find.byTooltip('Xem ảnh nổi bật'));
        await tester.pumpAndSettle();
        tester
            .renderObject<RenderRepaintBoundary>(find.byKey(key))
            .markNeedsPaint();
        await tester.pump();
        await tester.runAsync(() async {
          final image = await tester
              .renderObject<RenderRepaintBoundary>(find.byKey(key))
              .toImage();
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          File('build/gallery-screenshots/viewer-${mode.name}.png')
              .writeAsBytesSync(bytes!.buffer.asUint8List());
          image.dispose();
        });
      });
    }
  }
}
