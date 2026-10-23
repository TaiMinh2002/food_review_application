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
import 'package:food_review/features/places/data/osm_region_place_repository.dart';
import 'package:food_review/features/places/data/osm_region_search_repository.dart';
import 'package:food_review/features/places/domain/nearby_place_repository.dart';
import 'package:food_review/features/places/domain/place.dart';
import 'package:food_review/features/places/domain/place_category.dart';
import 'package:food_review/features/places/domain/place_map_repository.dart';
import 'package:food_review/features/places/domain/place_search.dart';
import 'package:food_review/features/places/domain/place_search_repository.dart';
import 'package:food_review/features/places/presentation/category_screen.dart';
import 'package:food_review/features/places/presentation/discovery_center.dart';
import 'package:food_review/features/places/presentation/map_controller.dart';
import 'package:food_review/features/places/presentation/map_screen.dart';
import 'package:food_review/features/places/presentation/place_providers.dart';
import 'package:food_review/features/places/presentation/search_controller.dart';
import 'package:food_review/features/places/presentation/search_filters_screen.dart';
import 'package:food_review/shared/widgets/app_restaurant_card.dart';

import 'support/auth_fixtures.dart';

class ControlledSearch implements PlaceSearchRepository {
  final requests = <PlaceSearchRequest>[];
  final pending = <Completer<PlaceSearchPage>>[];
  @override
  Future<PlaceSearchPage> searchPlaces(
    PlaceSearchRequest request, {
    String? cursor,
    int pageSize = 20,
  }) {
    requests.add(request);
    final response = Completer<PlaceSearchPage>();
    pending.add(response);
    return response.future;
  }
}

void main() {
  final captureKey = GlobalKey();
  late OsmRegionPlaceRepository source;
  late String package;
  late List<Place> nearby, restaurants;
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await (FontLoader(
      'Inter',
    )..addFont(rootBundle.load('assets/fonts/Inter.ttf'))).load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    package = await File('assets/osm/hanoi_urban_places.json').readAsString();
    source = OsmRegionPlaceRepository(() async => package);
    nearby = await source.findNearby(phungKhoangCenter);
    restaurants = nearby
        .where((place) => place.category == 'Nhà hàng')
        .toList();
  });

  test(
    'actual OSM scopes filter the full region before total and cursor',
    () async {
      final repository = OsmRegionSearchRepository(source, phungKhoangCenter);
      for (final category in PlaceCategory.osmValues) {
        final request = PlaceSearchRequest(categoryScope: category.id);
        final expected = nearby
            .where(category.contains)
            .map((place) => place.id)
            .toList();
        final ids = <String>[];
        String? cursor;
        do {
          final page = await repository.searchPlaces(
            request,
            pageSize: 7,
            cursor: cursor,
          );
          expect(page.totalCount, expected.length);
          expect(page.isDemo, isFalse);
          expect(
            page.categories.every((label) => label == category.label),
            isTrue,
          );
          ids.addAll(page.items.map((place) => place.id));
          cursor = page.nextCursor;
        } while (cursor != null);
        expect(ids, expected);
        expect(ids.toSet().length, ids.length);
      }
      final mismatch = await repository.searchPlaces(
        PlaceSearchRequest(categoryScope: 'nha-hang', categories: {'Cà phê'}),
      );
      expect(mismatch.totalCount, 0);
      final named = await repository.searchPlaces(
        PlaceSearchRequest(
          categoryScope: 'nha-hang',
          query: normalizePlaceSearchText(restaurants.first.name),
        ),
      );
      expect(
        named.items.map((place) => place.id),
        contains(restaurants.first.id),
      );
      expect(
        named.items.every((place) => place.category == 'Nhà hàng'),
        isTrue,
      );
      await expectLater(
        repository.searchPlaces(PlaceSearchRequest(categoryScope: 'pho')),
        throwsA(
          isA<AppException>().having(
            (e) => e.code,
            'code',
            'unsupported_category',
          ),
        ),
      );
    },
  );

  Future<ProviderContainer> mount(
    WidgetTester tester, {
    String route = '/categories/nha-hang',
    double width = 390,
    double height = 844,
    double scale = 1,
    ThemeMode mode = ThemeMode.light,
    PlaceSearchRepository? repository,
    bool withCenter = true,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = Size(width, height);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final region = OsmRegionPlaceRepository(() async => package);
    final container = ProviderContainer(
      overrides: [
        signedInSession,
        mapTilesEnabledProvider.overrideWithValue(false),
        osmRegionPlaceRepositoryProvider.overrideWithValue(region),
        nearbyPlaceRepositoryProvider.overrideWithValue(region),
        if (repository != null)
          osmPlaceSearchRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);
    if (withCenter) {
      container
          .read(discoveryCenterProvider.notifier)
          .choose(phungKhoangCenter);
    }
    container.read(themeModeProvider.notifier).setMode(mode);
    container.read(appRouterProvider).go(route);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: RepaintBoundary(
          key: captureKey,
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
      ),
    );
    if (repository == null) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump(const Duration(milliseconds: 350));
    }
    return container;
  }

  Finder scroll() => find
      .descendant(
        of: find.byType(CustomScrollView).first,
        matching: find.byType(Scrollable),
      )
      .first;
  Future<void> reveal(WidgetTester tester, Finder target) async {
    if (target.evaluate().isEmpty) {
      tester.state<ScrollableState>(scroll()).position.jumpTo(0);
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(target, 200, scrollable: scroll());
    }
    await tester.ensureVisible(target);
    await tester.pumpAndSettle();
  }

  SearchSeed seed(WidgetTester tester) {
    final widget = tester.widget<CategoryScreen>(find.byType(CategoryScreen));
    return (
      scope: widget.scope,
      request: PlaceSearchRequest.fromUri(widget.uri)
          .copyWith(categoryScope: widget.categoryId),
    );
  }

  for (final mode in [ThemeMode.light, ThemeMode.dark]) {
    for (final width in [320.0, 390.0, 428.0]) {
      for (final scale in [1.0, 1.6]) {
        testWidgets('OSM category fits $width at ${scale}x in ${mode.name}', (
          tester,
        ) async {
          await mount(tester, width: width, scale: scale, mode: mode);
          expect(find.byType(NavigationBar), findsOneWidget);
          expect(tester.takeException(), isNull);
          await reveal(tester, find.text(restaurants.first.name));
          final card = tester.widget<AppRestaurantCard>(
            find.byType(AppRestaurantCard).first,
          );
          expect(card.imageUrl, isNull);
          expect(card.showReviewSummary, isFalse);
          expect(card.onFavorite, isNull);
          expect(find.text('Ảnh minh họa'), findsNothing);
          expect(tester.takeException(), isNull);
        });
      }
    }
  }

  testWidgets('missing center waits for explicit selection without querying', (
    tester,
  ) async {
    final repository = ControlledSearch();
    final container = await mount(
      tester,
      repository: repository,
      withCenter: false,
    );
    expect(repository.requests, isEmpty);
    expect(find.text('Chọn khu vực để xem quán thật.'), findsOneWidget);
    await tester.tap(find.text('Xem Chợ Phùng Khoang'));
    await tester.pump();
    expect(container.read(activeDiscoveryCenterProvider), phungKhoangCenter);
    expect(repository.requests.single.categoryScope, 'nha-hang');
    repository.pending.single.complete(
      PlaceSearchPage(items: [restaurants.first]),
    );
    await tester.pumpAndSettle();
    await reveal(tester, find.text(restaurants.first.name));
  });

  testWidgets(
    'legacy cuisine and invalid IDs never query or infer cuisine from names',
    (tester) async {
      final repository = ControlledSearch();
      final container = await mount(
        tester,
        route: '/categories/pho',
        repository: repository,
      );
      expect(repository.requests, isEmpty);
      expect(find.textContaining('OSM chưa phân loại món ăn'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilterChip, 'Cà phê'));
      await tester.pump(const Duration(milliseconds: 350));
      expect(repository.requests.single.categoryScope, 'ca-phe');
      repository.pending.single.complete(PlaceSearchPage(items: []));
      await tester.pumpAndSettle();
      container.read(appRouterProvider).go('/categories/missing');
      await tester.pumpAndSettle();
      expect(find.text('Danh mục không tồn tại.'), findsOneWidget);
      expect(repository.requests, hasLength(1));
    },
  );

  testWidgets('scope is pinned during filter Cancel Apply Reset and sorting', (
    tester,
  ) async {
    final container = await mount(tester, height: 1200);
    final routeSeed = seed(tester);
    final provider = osmSearchControllerProvider(routeSeed);
    expect(container.read(provider).request.sort, PlaceSearchSort.relevance);
    await tester.tap(find.text('Bộ lọc'));
    await tester.pumpAndSettle();
    expect(find.text('Trong danh mục Nhà hàng'), findsOneWidget);
    expect(find.widgetWithText(FilterChip, 'Cà phê'), findsNothing);
    await tester.enterText(
      find.descendant(
        of: find.byType(SearchFiltersScreen),
        matching: find.byType(TextField),
      ),
      restaurants.first.name,
    );
    await tester.tap(find.text('Hủy'));
    await tester.pumpAndSettle();
    expect(container.read(provider).request.query, isEmpty);
    await tester.tap(find.text('Bộ lọc'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.descendant(
        of: find.byType(SearchFiltersScreen),
        matching: find.byType(TextField),
      ),
      restaurants.first.name,
    );
    await tester.tap(find.text('Áp dụng bộ lọc'));
    await tester.pumpAndSettle();
    expect(
      container.read(provider).items.every((p) => p.category == 'Nhà hàng'),
      isTrue,
    );
    expect(container.read(provider).request.query, restaurants.first.name);
    await reveal(tester, find.text('Bộ lọc'));
    await tester.tap(find.text('Bộ lọc'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Đặt lại'));
    await tester.tap(find.text('Áp dụng bộ lọc'));
    await tester.pumpAndSettle();
    expect(container.read(provider).request.categoryScope, 'nha-hang');
    expect(container.read(provider).request.sort, PlaceSearchSort.relevance);
    // Filter Reset preserves the query; controller Reset clears it.
    container.read(provider.notifier).reset();
    await tester.pumpAndSettle();
    expect(container.read(provider).totalCount, restaurants.length);
    await reveal(tester, find.text('Gần tâm đã chọn').first);
    await tester.tap(find.text('Gần tâm đã chọn').first);
    await tester.pumpAndSettle();
    for (final label in [
      'Đánh giá cao nhất',
      'Giá thấp đến cao',
      'Nhiều đánh giá nhất',
    ]) {
      expect(
        tester.widget<ListTile>(find.widgetWithText(ListTile, label)).onTap,
        isNull,
      );
    }
  });

  testWidgets(
    'real result opens the same OSM ID on Map and Back restores category',
    (tester) async {
      final container = await mount(tester);
      final routeSeed = seed(tester);
      await reveal(tester, find.text(restaurants.first.name));
      final position = tester.state<ScrollableState>(scroll()).position.pixels;
      await tester.tap(find.text(restaurants.first.name));
      await tester.pumpAndSettle();
      expect(
        tester.widget<PlaceMapScreen>(find.byType(PlaceMapScreen)).restaurantId,
        restaurants.first.id,
      );
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byType(CategoryScreen), findsOneWidget);
      expect(
        tester.state<ScrollableState>(scroll()).position.pixels,
        closeTo(position, 1),
      );
      expect(
        container
            .read(osmSearchControllerProvider(routeSeed))
            .request
            .categoryScope,
        'nha-hang',
      );
    },
  );

  testWidgets(
    'old rating URLs report unsupported and clearing sort reloads real places',
    (tester) async {
      final container = await mount(
        tester,
        route: '/categories/nha-hang?sort=rating',
        height: 1200,
      );
      expect(
        find.textContaining('OSM chưa có dữ liệu đánh giá'),
        findsOneWidget,
      );
      await tester.tap(find.byTooltip('Bỏ lọc Đánh giá cao nhất'));
      await tester.pumpAndSettle();
      final state = container.read(osmSearchControllerProvider(seed(tester)));
      expect(state.error, isNull);
      expect(state.request.sort, PlaceSearchSort.relevance);
      expect(state.totalCount, restaurants.length);
      expect(state.isDemo, isFalse);
    },
  );

  testWidgets('Home opens a real category and Back returns to Home', (
    tester,
  ) async {
    await mount(tester, route: '/home');
    await tester.tap(find.text('Xem danh mục'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<CategoryScreen>(find.byType(CategoryScreen)).categoryId,
      'nha-hang',
    );
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Hôm nay ăn gì?'), findsOneWidget);
  });

  testWidgets(
    'first page and pagination failures retry without losing scope or items',
    (tester) async {
      final repository = ControlledSearch();
      await mount(tester, repository: repository, height: 1200);
      expect(find.text('Đang tìm quán…'), findsWidgets);
      repository.pending.last.completeError(
        const AppException('Lỗi thử nghiệm'),
      );
      await tester.pumpAndSettle();
      await reveal(tester, find.text('Thử lại'));
      await tester.tap(find.text('Thử lại'));
      await tester.pump();
      repository.pending.last.complete(
        PlaceSearchPage(items: [restaurants.first], nextCursor: 'more'),
      );
      await tester.pumpAndSettle();
      await reveal(tester, find.text('Tải thêm quán'));
      await tester.tap(find.text('Tải thêm quán'));
      await tester.pump();
      repository.pending.last.completeError(
        const AppException('Lỗi trang thử nghiệm'),
      );
      await tester.pumpAndSettle();
      await reveal(tester, find.text('Thử lại'));
      await tester.tap(find.text('Thử lại'));
      await tester.pump();
      expect(repository.requests.last.categoryScope, 'nha-hang');
      repository.pending.last.complete(
        PlaceSearchPage(items: [restaurants.first, restaurants[1]]),
      );
      await tester.pumpAndSettle();
      await reveal(tester, find.text(restaurants[1].name));
      expect(find.text(restaurants.first.name), findsOneWidget);
    },
  );

  testWidgets(
    'changing discovery center retains query and ignores a late old region',
    (tester) async {
      final delayed = _DelayedNearby();
      final container = ProviderContainer(
        overrides: [nearbyPlaceRepositoryProvider.overrideWithValue(delayed)],
      );
      addTearDown(container.dispose);
      container
          .read(discoveryCenterProvider.notifier)
          .choose(phungKhoangCenter);
      final routeSeed = (
        request: PlaceSearchRequest(categoryScope: 'nha-hang'),
        scope: 'region-test',
      );
      final provider = osmSearchControllerProvider(routeSeed);
      final subscription = container.listen(provider, (_, _) {});
      addTearDown(subscription.close);
      await tester.pump();
      delayed.pending.last.complete([restaurants.first]);
      await tester.pump();
      container.read(provider.notifier).submit(restaurants.first.name);
      await tester.pump();
      final old = delayed.pending.last;
      container
          .read(discoveryCenterProvider.notifier)
          .choose(const GeoPoint(21.01, 105.81));
      await tester.pump();
      container.read(provider);
      await tester.pump();
      expect(delayed.pending, hasLength(3));
      delayed.pending.last.complete([]);
      await tester.pump();
      old.complete([restaurants.first]);
      await tester.pump();
      expect(container.read(provider).request.query, restaurants.first.name);
      expect(container.read(provider).request.categoryScope, 'nha-hang');
      expect(container.read(provider).items, isEmpty);
      await tester.pump(const Duration(milliseconds: 1));
    },
  );

  if (const bool.fromEnvironment('CATEGORY_CAPTURE')) {
    for (final mode in [ThemeMode.light, ThemeMode.dark]) {
      testWidgets('Capture real Category ${mode.name}', (tester) async {
        await mount(tester, height: 1200, mode: mode);
        final boundary = tester.renderObject<RenderRepaintBoundary>(
          find.byKey(captureKey),
        );
        boundary.markNeedsPaint();
        await tester.pump();
        await tester.runAsync(() async {
          final image = await boundary.toImage();
          final data = await image.toByteData(format: ui.ImageByteFormat.png);
          final directory = Directory('build/category-screenshots')
            ..createSync(recursive: true);
          File('${directory.path}/category-real-${mode.name}.png')
              .writeAsBytesSync(data!.buffer.asUint8List());
          image.dispose();
        });
      });
    }
  }
}

class _DelayedNearby implements NearbyPlaceRepository {
  final pending = <Completer<List<Place>>>[];
  @override
  Future<List<Place>> findNearby(GeoPoint center, {int radiusMeters = 5000}) {
    final response = Completer<List<Place>>();
    pending.add(response);
    return response.future;
  }
}
