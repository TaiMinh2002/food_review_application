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
import 'package:food_review/features/favorites/presentation/favorite_providers.dart';
import 'package:food_review/features/places/data/demo_place_repository.dart';
import 'package:food_review/features/places/domain/place_category.dart';
import 'package:food_review/features/places/domain/place_search.dart';
import 'package:food_review/features/places/domain/place_search_repository.dart';
import 'package:food_review/features/places/presentation/category_screen.dart';
import 'package:food_review/features/places/presentation/map_controller.dart';
import 'package:food_review/features/places/presentation/place_detail_screen.dart';
import 'package:food_review/features/places/presentation/search_controller.dart';
import 'package:food_review/features/places/presentation/search_filters_screen.dart';
import 'package:food_review/shared/widgets/app_restaurant_card.dart';

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
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await (FontLoader(
      'Inter',
    )..addFont(rootBundle.load('assets/fonts/Inter.ttf'))).load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });

  test(
    'Root scope intersects subtype/query/price before count and paging',
    () async {
      final repo = DemoPlaceRepository();
      final root = PlaceSearchRequest(categoryScope: 'mon-viet');
      final page = await repo.searchPlaces(root, pageSize: 1);
      expect(page.totalCount, 2);
      expect(page.nextCursor, isNotNull);
      final next = await repo.searchPlaces(
        root,
        pageSize: 1,
        cursor: page.nextCursor,
      );
      expect(
        {...page.items, ...next.items}.map((p) => p.id),
        isNot(contains('coffee-demo')),
      );
      expect(
        (await repo.searchPlaces(root.copyWith(categories: {'Phở'})))
            .items
            .single
            .id,
        'pho-demo',
      );
      expect(
        (await repo.searchPlaces(root.copyWith(categories: {'Cà phê'}))).items,
        isEmpty,
      );
      expect(
        (await repo.searchPlaces(root.copyWith(query: 'ca phe'))).items,
        isEmpty,
      );
      expect(
        (await repo.searchPlaces(root.copyWith(maxPrice: 49999)))
            .items
            .single
            .id,
        'banh-mi-demo',
      );
      expect(
        (await repo.searchPlaces(PlaceSearchRequest(categoryScope: 'ca-phe')))
            .items
            .single
            .id,
        'coffee-demo',
      );
      expect(
        (await repo.searchPlaces(PlaceSearchRequest(categoryScope: 'bun')))
            .items,
        isEmpty,
      );
      expect(
        () => repo.searchPlaces(PlaceSearchRequest(categoryScope: 'missing')),
        throwsA(isA<AppException>()),
      );
      expect(PlaceCategory.byId('missing'), isNull);
    },
  );

  test(
    'Scope participates in URI roundtrip, equality and controller isolation',
    () async {
      final request = PlaceSearchRequest(
        categoryScope: 'mon-viet',
        categories: {'Phở'},
        query: 'bo tai',
      );
      final parsed = PlaceSearchRequest.fromUri(
        Uri(path: '/search/filters', queryParameters: request.queryParameters),
      );
      expect(parsed, request);
      expect(request, isNot(request.copyWith(categoryScope: 'ca-phe')));
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final seed = (request: request, scope: 'category-test');
      final subscription = container.listen(
        searchControllerProvider(seed),
        (_, _) {},
      );
      addTearDown(subscription.close);
      await Future<void>.delayed(Duration.zero);
      final controller = container.read(
        searchControllerProvider(seed).notifier,
      );
      controller.apply(PlaceSearchRequest(categoryScope: 'ca-phe'));
      await Future<void>.delayed(Duration.zero);
      expect(
        container.read(searchControllerProvider(seed)).request.categoryScope,
        'mon-viet',
      );
      controller.reset();
      await Future<void>.delayed(Duration.zero);
      final state = container.read(searchControllerProvider(seed));
      expect(state.request.categoryScope, 'mon-viet');
      expect(state.request.categories, isEmpty);
      expect(
        state.items.map((place) => place.id),
        isNot(contains('coffee-demo')),
      );
    },
  );

  Future<ProviderContainer> mount(
    WidgetTester tester, {
    String route = '/categories/mon-viet',
    double width = 390,
    double height = 844,
    double scale = 1,
    ThemeMode mode = ThemeMode.light,
    PlaceSearchRepository? repository,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = Size(width, height);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final container = ProviderContainer(
      overrides: [
        mapTilesEnabledProvider.overrideWithValue(false),
        if (repository != null)
          placeSearchRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);
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
  Future<void> reveal(WidgetTester tester, Finder target) async {
    await tester.scrollUntilVisible(target, 180, scrollable: scroll());
    await tester.ensureVisible(target);
    await tester.pumpAndSettle();
  }

  for (final mode in [ThemeMode.light, ThemeMode.dark]) {
    for (final width in [320.0, 390.0, 428.0]) {
      for (final scale in [1.0, 1.6]) {
        testWidgets('Category fits $width at ${scale}x in ${mode.name}', (
          tester,
        ) async {
          await mount(tester, width: width, scale: scale, mode: mode);
          expect(find.byType(NavigationBar), findsOneWidget);
          expect(tester.takeException(), isNull);
          await reveal(tester, find.text('Bánh Mì Buổi Sáng'));
          expect(tester.takeException(), isNull);
          expect(find.text('Góc Cà Phê'), findsNothing);
        });
      }
    }
  }

  testWidgets(
    'Home entry retains quick filtering; detail Back and tabs retain category state',
    (tester) async {
      final container = await mount(tester, route: '/home');
      await tester.tap(find.widgetWithText(FilterChip, 'Món Việt'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Xem danh mục'));
      await tester.pumpAndSettle();
      expect(find.byType(CategoryScreen), findsOneWidget);
      await tester.tap(find.widgetWithText(FilterChip, 'Phở'));
      await tester.pumpAndSettle();
      await reveal(tester, find.byTooltip('Lưu yêu thích'));
      await tester.tap(find.byTooltip('Lưu yêu thích'));
      await tester.pumpAndSettle();
      expect(container.read(favoriteIdsProvider), contains('pho-demo'));
      final position = tester.state<ScrollableState>(scroll()).position.pixels;
      await tester.tap(find.text('Phở Nhà Mình'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<PlaceDetailScreen>(find.byType(PlaceDetailScreen))
            .placeId,
        'pho-demo',
      );
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(tester.state<ScrollableState>(scroll()).position.pixels, position);
      expect(find.byTooltip('Bỏ yêu thích'), findsOneWidget);
      await tester.tap(find.text('Cá nhân').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Trang chủ').last);
      await tester.pumpAndSettle();
      expect(find.byType(CategoryScreen), findsOneWidget);
      expect(find.text('Góc Cà Phê'), findsNothing);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Kết quả khám phá'), findsOneWidget);
    },
  );

  testWidgets(
    'Scoped search, form Cancel Apply Reset and subtype All never leak categories',
    (tester) async {
      final container = await mount(tester, height: 1100);
      await tester.tap(find.byTooltip('Tìm kiếm trong danh mục'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'ca phe');
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();
      expect(find.text('Chưa tìm thấy nhà hàng'), findsOneWidget);
      await tester.tap(find.text('Xóa bộ lọc'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bộ lọc'));
      await tester.pumpAndSettle();
      expect(find.text('Trong danh mục Món Việt'), findsOneWidget);
      expect(find.text('Cà phê'), findsNothing);
      await tester.tap(
        find.descendant(
          of: find.byType(SearchFiltersScreen),
          matching: find.widgetWithText(FilterChip, 'Phở'),
        ),
      );
      await tester.tap(find.text('Hủy'));
      await tester.pumpAndSettle();
      expect(find.text('2 địa điểm'), findsWidgets);
      await tester.tap(find.text('Bộ lọc'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(SearchFiltersScreen),
          matching: find.widgetWithText(FilterChip, 'Phở'),
        ),
      );
      await tester.tap(find.text('Áp dụng bộ lọc'));
      await tester.pumpAndSettle();
      expect(find.text('1 địa điểm'), findsWidgets);
      await tester.tap(find.text('Bộ lọc'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Đặt lại'));
      await tester.tap(find.text('Áp dụng bộ lọc'));
      await tester.pumpAndSettle();
      expect(find.text('2 địa điểm'), findsWidgets);
      expect(
        container
            .read(appRouterProvider)
            .routerDelegate
            .currentConfiguration
            .last
            .matchedLocation,
        '/categories/mon-viet',
      );
    },
  );

  testWidgets(
    'Unknown category never queries; leaf IDs and route changes update scope; direct Back returns Home',
    (tester) async {
      final repo = ControlledSearch();
      final container = await mount(
        tester,
        route: '/categories/missing',
        repository: repo,
      );
      expect(repo.requests, isEmpty);
      expect(find.text('Danh mục không tồn tại.'), findsOneWidget);
      container.read(appRouterProvider).go('/categories/ca-phe?scope=mon-viet');
      await tester.pumpAndSettle();
      expect(repo.requests.single.categoryScope, 'ca-phe');
      repo.pending.last.complete(
        PlaceSearchPage(items: [DemoPlaceRepository.places[1]]),
      );
      await tester.pumpAndSettle();
      expect(find.text('Góc Cà Phê'), findsOneWidget);
      container.read(appRouterProvider).go('/categories/bun');
      await tester.pumpAndSettle();
      expect(repo.requests.last.categoryScope, 'bun');
      repo.pending.last.complete(PlaceSearchPage(items: []));
      await tester.pumpAndSettle();
      expect(find.text('Chưa tìm thấy nhà hàng'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(
        container
            .read(appRouterProvider)
            .routeInformationProvider
            .value
            .uri
            .path,
        '/home',
      );
    },
  );

  testWidgets('Sort and keyboard search keep the required category scope', (
    tester,
  ) async {
    await mount(tester, height: 1200);
    await tester.tap(find.text('Đánh giá cao'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Giá thấp đến cao'));
    await tester.pumpAndSettle();
    final first = tester
        .widgetList<AppRestaurantCard>(find.byType(AppRestaurantCard))
        .first;
    expect(first.name, 'Bánh Mì Buổi Sáng');
    await tester.tap(find.byTooltip('Tìm kiếm trong danh mục'));
    await tester.pumpAndSettle();
    tester.view.viewInsets = const FakeViewPadding(bottom: 350);
    addTearDown(tester.view.resetViewInsets);
    await tester.enterText(find.byType(TextField), 'bo tai lan');
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await reveal(tester, find.text('Phở Nhà Mình'));
    expect(find.text('Góc Cà Phê'), findsNothing);
  });

  testWidgets(
    'Loading first-page failure and pagination retry preserve category and records',
    (tester) async {
      final repo = ControlledSearch();
      await mount(tester, repository: repo, height: 1200);
      expect(find.text('Đang tìm quán…'), findsWidgets);
      repo.pending.last.completeError(
        const AppException('Lỗi danh mục thử nghiệm'),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Thử lại'));
      await tester.pumpAndSettle();
      repo.pending.last.complete(
        PlaceSearchPage(
          items: [DemoPlaceRepository.places.first],
          nextCursor: 'more',
        ),
      );
      await tester.pumpAndSettle();
      await reveal(tester, find.text('Tải thêm quán'));
      await tester.tap(find.text('Tải thêm quán'));
      await tester.pump();
      repo.pending.last.completeError(
        const AppException('Lỗi trang thử nghiệm'),
      );
      await tester.pumpAndSettle();
      expect(find.text('Phở Nhà Mình'), findsOneWidget);
      await reveal(tester, find.text('Thử lại'));
      await tester.tap(find.text('Thử lại'));
      await tester.pump();
      expect(repo.requests.last.categoryScope, 'mon-viet');
      repo.pending.last.complete(
        PlaceSearchPage(items: [DemoPlaceRepository.places.last]),
      );
      await tester.pumpAndSettle();
      await reveal(tester, find.text('Bánh Mì Buổi Sáng'));
      expect(find.byType(AppRestaurantCard), findsWidgets);
    },
  );

  if (const bool.fromEnvironment('CATEGORY_CAPTURE')) {
    for (final mode in [ThemeMode.light, ThemeMode.dark]) {
      testWidgets('Capture Category ${mode.name}', (tester) async {
        await mount(tester, height: 1738, mode: mode);
        tester
            .renderObject<RenderRepaintBoundary>(find.byKey(captureKey))
            .markNeedsPaint();
        await tester.pump();
        await tester.runAsync(() async {
          final boundary = tester.renderObject<RenderRepaintBoundary>(
            find.byKey(captureKey),
          );
          final image = await boundary.toImage();
          final data = await image.toByteData(format: ui.ImageByteFormat.png);
          final directory = Directory('build/category-screenshots')
            ..createSync(recursive: true);
          File('${directory.path}/category-${mode.name}.png')
              .writeAsBytesSync(data!.buffer.asUint8List());
          image.dispose();
        });
      });
    }
  }
}
