import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_review/app/food_review_app.dart';
import 'package:food_review/core/router/app_router.dart';
import 'package:food_review/core/errors/app_exception.dart';
import 'package:food_review/core/theme/theme_mode_provider.dart';
import 'package:food_review/features/places/presentation/map_controller.dart';
import 'package:food_review/features/reviews/presentation/restaurant_review_card.dart';
import 'package:food_review/features/reviews/presentation/review_feed_widgets.dart';
import 'package:food_review/features/reviews/presentation/review_feed_controller.dart';
import 'package:food_review/features/reviews/domain/review_feed_repository.dart';

class RetryReviews implements ReviewFeedRepository {
  int summaries = 0, pages = 0;
  @override
  Future<ReviewSummary> getSummary(String placeId) async {
    if (++summaries == 1) throw const AppException('Lỗi tổng quan thử nghiệm');
    return ReviewSummary(totalCount: 0);
  }

  @override
  Future<ReviewPage> getReviews(
    String placeId, {
    required ReviewFilters filters,
    String? cursor,
    int pageSize = 10,
  }) async {
    if (++pages == 1) throw const AppException('Lỗi danh sách thử nghiệm');
    return ReviewPage(items: [], totalCount: 0);
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

  Future<ProviderContainer> mount(
    WidgetTester tester, {
    double width = 390,
    double height = 844,
    double scale = 1,
    ThemeMode mode = ThemeMode.light,
    String route = '/restaurants/pho-demo/reviews',
    ReviewFeedRepository? repository,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = Size(width, height);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final container = ProviderContainer(
      overrides: [
        mapTilesEnabledProvider.overrideWithValue(false),
        if (repository != null)
          reviewFeedRepositoryProvider.overrideWithValue(repository),
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
        testWidgets('Reviews fit $width at ${scale}x in ${mode.name}', (
          tester,
        ) async {
          await mount(tester, width: width, scale: scale, mode: mode);
          expect(find.byType(NavigationBar), findsNothing);
          expect(find.byType(ReviewWriteBar), findsOneWidget);
          expect(tester.takeException(), isNull);
          await reveal(tester, find.text('Đặng Hải'));
          expect(tester.takeException(), isNull);
        });
      }
    }
  }

  testWidgets(
    'Filter draft cancels, applies AND conditions and leaves summary unchanged',
    (tester) async {
      await mount(tester);
      await tester.tap(find.byTooltip('Lọc và sắp xếp'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('4 sao (2)').last);
      await tester.tap(find.text('Hủy'));
      await tester.pumpAndSettle();
      await reveal(tester, find.text('4 đánh giá phù hợp'));
      await tester.tap(find.byTooltip('Lọc và sắp xếp'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('4 sao (2)').last);
      await tester.pump();
      await tester.tap(find.text('Có ảnh (2)').last);
      await tester.pump();
      await tester.tap(find.text('Áp dụng'));
      await tester.pumpAndSettle();
      await reveal(tester, find.text('Minh Châu'));
      expect(find.byType(RestaurantReviewCard), findsOneWidget);
      await tester.drag(find.byType(CustomScrollView), const Offset(0, 1200));
      await tester.pumpAndSettle();
      expect(find.text('4.5'), findsOneWidget);
      await tester.tap(find.byTooltip('Lọc và sắp xếp'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Đặt lại'));
      await tester.pump();
      await tester.tap(find.text('1 sao (0)').last);
      await tester.pump();
      await tester.tap(find.text('Áp dụng'));
      await tester.pumpAndSettle();
      await reveal(tester, find.text('Chưa có đánh giá phù hợp'));
      await tester.tap(find.text('Xóa bộ lọc'));
      await tester.pumpAndSettle();
      await reveal(tester, find.text('Hoàng Linh'));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Write routes with restaurant ID and Back retains scroll and filter',
    (tester) async {
      final container = await mount(
        tester,
        route: '/restaurants/pho-demo/reviews?rating=4',
      );
      await reveal(tester, find.text('Minh Châu'));
      final position = tester.state<ScrollableState>(scroll()).position;
      final before = position.pixels;
      await tester.tap(
        find.descendant(
          of: find.byType(ReviewWriteBar),
          matching: find.text('Viết đánh giá'),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        container
            .read(appRouterProvider)
            .routerDelegate
            .currentConfiguration
            .last
            .matchedLocation,
        '/restaurants/pho-demo/reviews/create',
      );
      container.read(appRouterProvider).pop();
      await tester.pumpAndSettle();
      expect(position.pixels, before);
      expect(find.text('Minh Châu'), findsOneWidget);
      expect(find.text('Hoàng Linh'), findsNothing);
    },
  );

  testWidgets('Missing restaurant never shows write or reviews', (
    tester,
  ) async {
    await mount(tester, route: '/restaurants/missing/reviews');
    expect(find.text('Không tìm thấy quán.'), findsOneWidget);
    expect(find.byType(ReviewWriteBar), findsNothing);
    expect(find.byType(ReviewSummaryCard), findsNothing);
  });

  testWidgets('Photo, profile and report preserve scoped IDs and Back', (
    tester,
  ) async {
    final container = await mount(tester);
    final router = container.read(appRouterProvider);
    await reveal(tester, find.bySemanticsLabel('Ảnh đánh giá 2').first);
    await tester.tap(find.bySemanticsLabel('Ảnh đánh giá 2').first);
    await tester.pumpAndSettle();
    expect(
      router.routerDelegate.currentConfiguration.last.matchedLocation,
      '/restaurants/pho-demo/gallery',
    );
    expect(
      router.state.uri.queryParameters,
      containsPair('reviewId', 'review-linh-demo'),
    );
    expect(router.state.uri.queryParameters, containsPair('index', '1'));
    expect(find.text('2 / 2'), findsOneWidget);
    await tester.tap(find.byTooltip('Đóng ảnh'));
    await tester.pumpAndSettle();
    router.pop();
    await tester.pumpAndSettle();
    await reveal(tester, find.text('Hoàng Linh'));
    await tester.tap(find.byTooltip('Tùy chọn nhận xét').first);
    await tester.pumpAndSettle();
    expect(
      router.state.uri.queryParameters,
      containsPair('restaurantId', 'pho-demo'),
    );
    expect(
      router.state.uri.queryParameters,
      containsPair('reviewId', 'review-linh-demo'),
    );
    router.pop();
    await tester.pumpAndSettle();
    await tester.tap(find.text('HL').first);
    await tester.pumpAndSettle();
    expect(
      router.routerDelegate.currentConfiguration.last.matchedLocation,
      '/users/linh-demo',
    );
    router.pop();
    await tester.pumpAndSettle();
    expect(find.text('Hoàng Linh'), findsOneWidget);
  });

  testWidgets('Sort applies and sharing preserves active filters', (
    tester,
  ) async {
    await mount(tester);
    await tester.tap(find.byTooltip('Lọc và sắp xếp'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cũ nhất'));
    await tester.pump();
    await tester.tap(find.text('Áp dụng'));
    await tester.pumpAndSettle();
    await reveal(tester, find.text('Đặng Hải'));
    expect(
      tester
          .widget<RestaurantReviewCard>(find.byType(RestaurantReviewCard).first)
          .review
          .authorName,
      'Đặng Hải',
    );
    await tester.tap(find.byTooltip('Chia sẻ'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('/restaurants/pho-demo/reviews?sort=oldest'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Summary and list retry independently; missing distribution stays unknown',
    (tester) async {
      final repository = RetryReviews();
      await mount(tester, repository: repository);
      await tester.tap(
        find.descendant(
          of: find.byKey(const ValueKey('summary-error')),
          matching: find.text('Thử lại'),
        ),
      );
      await tester.pumpAndSettle();
      expect(repository.summaries, 2);
      expect(repository.pages, 1);
      expect(find.text('Chưa có dữ liệu phân bố theo sao.'), findsOneWidget);
      final retry = find.descendant(
        of: find.byKey(const ValueKey('feed-error')),
        matching: find.text('Thử lại'),
      );
      await reveal(tester, retry);
      await tester.tap(retry);
      await tester.pumpAndSettle();
      expect(repository.pages, 2);
      expect(repository.summaries, 2);
      await reveal(tester, find.text('Chưa có đánh giá phù hợp'));
      expect(tester.takeException(), isNull);
    },
  );

  if (const bool.fromEnvironment('REVIEWS_CAPTURE')) {
    for (final mode in [ThemeMode.light, ThemeMode.dark]) {
      testWidgets('Capture reviews ${mode.name}', (tester) async {
        await mount(tester, height: 2064, mode: mode);
        tester
            .renderObject<RenderRepaintBoundary>(find.byKey(captureKey))
            .markNeedsPaint();
        await tester.pump();
        await tester.runAsync(() async {
          final boundary = tester.renderObject<RenderRepaintBoundary>(
            find.byKey(captureKey),
          );
          final image = await boundary.toImage();
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          final dir = Directory('build/reviews-screenshots');
          await dir.create(recursive: true);
          await File('${dir.path}/reviews-${mode.name}.png')
              .writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
      });
    }
  }
}
