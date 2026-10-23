import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'support/auth_fixtures.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:food_review/app/food_review_app.dart';
import 'package:food_review/core/router/app_router.dart';
import 'package:food_review/core/theme/theme_mode_provider.dart';
import 'package:food_review/features/favorites/presentation/favorite_providers.dart';
import 'package:food_review/features/places/data/demo_place_repository.dart';
import 'package:food_review/features/places/domain/place_search.dart';
import 'package:food_review/features/places/domain/place_search_repository.dart';
import 'package:food_review/features/places/presentation/search_controller.dart';
import 'package:food_review/features/places/presentation/search_screen.dart';
import 'package:food_review/features/places/presentation/search_widgets.dart';
import 'package:food_review/shared/widgets/app_skeleton.dart';

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
    String url = '/search',
    double width = 390,
    double height = 844,
    double scale = 1,
    ThemeMode mode = ThemeMode.light,
    PlaceSearchRepository? repo,
    bool settle = true,
    bool safeInsets = false,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = Size(width, height);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final container = ProviderContainer(
      overrides: [
        signedInSession,
        osmPlaceSearchRepositoryProvider.overrideWithValue(
          repo ?? DemoPlaceRepository(),
        ),
      ],
    );
    addTearDown(container.dispose);
    container.read(themeModeProvider.notifier).setMode(mode);
    container.read(appRouterProvider).go(url);
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

  Finder rootView() => find.byType(ListView).evaluate().isNotEmpty
      ? find.byType(ListView).first
      : find.byType(CustomScrollView).first;
  Finder rootScroll() =>
      find.descendant(of: rootView(), matching: find.byType(Scrollable)).first;
  Future<void> reveal(WidgetTester tester, Finder target) async {
    if (target.evaluate().isEmpty) {
      tester.state<ScrollableState>(rootScroll()).position.jumpTo(0);
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(target, 250, scrollable: rootScroll());
    }
    await tester.ensureVisible(target);
    await tester.pumpAndSettle();
  }

  PlaceSearchState current(WidgetTester tester, ProviderContainer container) =>
      container.read(
        osmSearchControllerProvider(
          tester.widget<SearchScreen>(find.byType(SearchScreen)).seed,
        ),
      );

  for (final url in ['/search', '/search/filters']) {
    for (final mode in [ThemeMode.light, ThemeMode.dark]) {
      for (final width in [320.0, 390.0, 428.0]) {
        testWidgets(
          '$url fits $width, 1.6x text and safe insets in ${mode.name}',
          (tester) async {
            await mount(
              tester,
              url: url,
              width: width,
              scale: 1.6,
              mode: mode,
              safeInsets: true,
            );
            expect(tester.takeException(), isNull);
            for (var i = 0; i < 12; i++) {
              await tester.drag(rootView(), const Offset(0, -300));
              await tester.pumpAndSettle();
              expect(tester.takeException(), isNull);
            }
            final label = url == '/search' ? 'Tìm kiếm' : 'Áp dụng bộ lọc';
            expect(
              tester.getRect(find.widgetWithText(FilledButton, label)).bottom,
              lessThanOrEqualTo(820),
            );
          },
        );
      }
    }
  }

  testWidgets(
    'Search query preserves results, detail Back, scroll and favorites',
    (tester) async {
      final container = await mount(tester, url: '/search');
      await tester.enterText(find.byType(TextField), 'pho');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();
      expect(find.byType(SearchScreen), findsOneWidget);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'pho',
      );
      await reveal(tester, find.text('Phở Nhà Mình'));
      final offset = tester
          .state<ScrollableState>(rootScroll())
          .position
          .pixels;
      await tester.tap(find.text('Phở Nhà Mình'));
      await tester.pumpAndSettle();
      expect(find.text('Chi tiết quán'), findsOneWidget);
      await tester.tap(find.byTooltip('Lưu yêu thích'));
      await tester.pumpAndSettle();
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(current(tester, container).request.query, 'pho');
      expect(
        tester.state<ScrollableState>(rootScroll()).position.pixels,
        closeTo(offset, 1),
      );
      expect(container.read(favoriteIdsProvider), contains('pho-demo'));
    },
  );

  testWidgets(
    'Typing, clear, category, sort and recent history update actual results',
    (tester) async {
      final container = await mount(tester);
      await tester.enterText(find.byType(TextField), 'không có quán');
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();
      await reveal(tester, find.text('Không tìm thấy quán phù hợp.'));
      expect(find.text('Không tìm thấy quán phù hợp.'), findsOneWidget);
      await reveal(tester, find.byTooltip('Xoá nội dung'));
      await tester.tap(find.byTooltip('Xoá nội dung'));
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();
      expect(current(tester, container).items, hasLength(3));
      await reveal(tester, find.widgetWithText(FilterChip, 'Cà phê'));
      await tester.tap(find.widgetWithText(FilterChip, 'Cà phê'));
      await tester.pumpAndSettle();
      expect(current(tester, container).items.single.id, 'coffee-demo');
      await tester.tap(find.widgetWithText(FilterChip, 'Cà phê'));
      await tester.pumpAndSettle();
      await reveal(tester, find.text('Sắp xếp'));
      await tester.tap(find.text('Sắp xếp'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Gần tâm đã chọn').last);
      await tester.pumpAndSettle();
      expect(current(tester, container).items.first.id, 'banh-mi-demo');
      await reveal(tester, find.byType(TextField));
      await tester.enterText(find.byType(TextField), 'ca phe');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();
      expect(current(tester, container).items.single.id, 'coffee-demo');
      expect(container.read(recentSearchesProvider), contains('ca phe'));
      await reveal(tester, find.byTooltip('Xóa tìm kiếm ca phe'));
      await tester.tap(find.byTooltip('Xóa tìm kiếm ca phe'));
      await tester.pumpAndSettle();
      expect(container.read(recentSearchesProvider), isEmpty);
    },
  );

  testWidgets(
    'Draft cancel preserves filters; apply commits and reset is local until applied',
    (tester) async {
      final container = await mount(tester, url: '/search');
      final original = current(tester, container).request;
      await tester.tap(find.byTooltip('Bộ lọc'));
      await tester.pumpAndSettle();
      await reveal(tester, find.widgetWithText(FilterChip, 'Cà phê'));
      await tester.tap(find.widgetWithText(FilterChip, 'Cà phê'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Hủy'));
      await tester.pumpAndSettle();
      expect(current(tester, container).request, original);
      await reveal(tester, find.byTooltip('Bộ lọc'));
      await tester.tap(find.byTooltip('Bộ lọc'));
      await tester.pumpAndSettle();
      await reveal(tester, find.widgetWithText(FilterChip, 'Cà phê'));
      await tester.tap(find.widgetWithText(FilterChip, 'Cà phê'));
      await tester.tap(find.text('Áp dụng bộ lọc'));
      await tester.pumpAndSettle();
      expect(current(tester, container).request.categories, contains('Cà phê'));
      expect(current(tester, container).items.single.id, 'coffee-demo');
      await reveal(tester, find.byTooltip('Bộ lọc'));
      await tester.tap(find.byTooltip('Bộ lọc'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Đặt lại'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Hủy'));
      await tester.pumpAndSettle();
      expect(current(tester, container).request.categories, contains('Cà phê'));
    },
  );

  testWidgets(
    'Search filter apply opens results and direct filter links work',
    (tester) async {
      final container = await mount(tester, url: '/search');
      await tester.tap(find.byTooltip('Bộ lọc'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilterChip, 'Cà phê'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Áp dụng bộ lọc'));
      await tester.pumpAndSettle();
      expect(current(tester, container).items.single.id, 'coffee-demo');
      container.read(appRouterProvider).go('/search/filters?q=banh%20mi');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Áp dụng bộ lọc'));
      await tester.pumpAndSettle();
      expect(current(tester, container).items.single.id, 'banh-mi-demo');
    },
  );

  testWidgets(
    'Unavailable real-data filters are explained and keyboard keeps input usable',
    (tester) async {
      await mount(tester, url: '/search/filters');
      await reveal(tester, find.text('Dữ liệu bộ lọc'));
      expect(find.text('Đánh giá'), findsNothing);
      expect(find.text('Khoảng giá (VND)'), findsNothing);
      expect(
        tester
            .widget<ListTile>(find.widgetWithText(ListTile, 'Gần tôi nhất'))
            .enabled,
        isFalse,
      );
      await reveal(tester, find.byType(TextField));
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      addTearDown(tester.view.resetViewInsets);
      await tester.tap(find.byType(TextField));
      await tester.enterText(find.byType(TextField), 'phở');
      await tester.pump();
      expect(find.byType(SearchBottomBar), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();
      expect(find.byType(SearchScreen), findsOneWidget);
    },
  );

  testWidgets(
    'Loading, initial error/retry and pagination error do not discard the query or items',
    (tester) async {
      final pending = Completer<PlaceSearchPage>();
      var firstCalls = 0, pageCalls = 0;
      final repo = _SearchRepo((request, cursor, size) {
        if (cursor == null) {
          firstCalls++;
          return firstCalls == 1
              ? pending.future
              : Future.value(
                  PlaceSearchPage(
                    items: [DemoPlaceRepository.places.first],
                    nextCursor: 'next',
                  ),
                );
        }
        pageCalls++;
        return pageCalls == 1
            ? Future.error(StateError('private backend error'))
            : Future.value(
                PlaceSearchPage(items: [DemoPlaceRepository.places.last]),
              );
      });
      final container = await mount(
        tester,
        url: '/search?q=pho',
        repo: repo,
        settle: false,
      );
      expect(find.byType(AppRestaurantSkeleton), findsNWidgets(2));
      pending.completeError(StateError('private initial error'));
      await tester.pumpAndSettle();
      await reveal(tester, find.text('Thử lại'));
      await tester.tap(find.text('Thử lại'));
      await tester.pumpAndSettle();
      await reveal(tester, find.text('Tải thêm quán'));
      await tester.tap(find.text('Tải thêm quán'));
      await tester.pumpAndSettle();
      expect(current(tester, container).items.single.id, 'pho-demo');
      expect(find.textContaining('private'), findsNothing);
      await reveal(tester, find.text('Thử lại'));
      await tester.tap(find.text('Thử lại'));
      await tester.pumpAndSettle();
      expect(current(tester, container).items, hasLength(2));
      expect(current(tester, container).request.query, 'pho');
    },
  );

  testWidgets('Options failure retries without losing the draft query', (
    tester,
  ) async {
    var calls = 0;
    final repo = _SearchRepo(
      (request, cursor, size) => ++calls == 1
          ? Future.error(StateError('private option error'))
          : DemoPlaceRepository().searchPlaces(
              request,
              cursor: cursor,
              pageSize: size,
            ),
    );
    await mount(tester, url: '/search/filters?q=pho', repo: repo);
    await tester.enterText(find.byType(TextField), 'ca phe');
    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'ca phe',
    );
    expect(find.widgetWithText(FilterChip, 'Phở'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  if (const bool.fromEnvironment('SEARCH_CAPTURE')) {
    for (final mode in [ThemeMode.light, ThemeMode.dark]) {
      for (final url in [
        '/search',
        '/search/filters?category=Ph%E1%BB%9F&rating=4&minPrice=50000&maxPrice=100000',
      ]) {
        testWidgets('Capture $url ${mode.name}', (tester) async {
          await mount(tester, url: url, height: 1707, mode: mode);
          await tester.runAsync(() async {
            final context = tester.element(find.byType(FoodReviewApp));
            for (final name in ['pho', 'coffee', 'banh_mi']) {
              await precacheImage(
                AssetImage('assets/images/demo/$name.jpg'),
                context,
              );
            }
          });
          await tester.pumpAndSettle();
          Future<void> capture(String suffix) async {
            await tester.runAsync(() async {
              final image = await tester
                  .renderObject<RenderRepaintBoundary>(find.byKey(captureKey))
                  .toImage();
              final bytes = await image.toByteData(
                format: ui.ImageByteFormat.png,
              );
              Directory('build/search-screenshots').createSync(recursive: true);
              File(
                'build/search-screenshots/${url.contains('filters') ? 'filters' : 'search'}-${mode.name}$suffix.png',
              ).writeAsBytesSync(bytes!.buffer.asUint8List());
              image.dispose();
            });
          }

          await capture('');
          if (url.contains('filters')) {
            await tester.drag(rootView(), const Offset(0, -1600));
            await tester.pumpAndSettle();
            await capture('-bottom');
          }
        });
      }
    }
  }
}

class _SearchRepo implements PlaceSearchRepository {
  _SearchRepo(this.run);
  final Future<PlaceSearchPage> Function(PlaceSearchRequest, String?, int) run;
  @override
  Future<PlaceSearchPage> searchPlaces(
    PlaceSearchRequest request, {
    String? cursor,
    int pageSize = 20,
  }) => run(request, cursor, pageSize);
}
