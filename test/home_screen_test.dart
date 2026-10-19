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
import 'package:food_review/features/places/data/demo_place_fixtures.dart';
import 'package:food_review/features/places/data/demo_place_repository.dart';
import 'package:food_review/features/places/presentation/place_providers.dart';

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
    bool missingImages = false,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = Size(width, height);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final container = ProviderContainer(
      overrides: [
        if (missingImages)
          placeRepositoryProvider.overrideWithValue(
            DemoPlaceRepository(data: DemoPlaceFixtures.withoutImages),
          ),
      ],
    );
    addTearDown(container.dispose);
    container.read(themeModeProvider.notifier).setMode(mode);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: RepaintBoundary(
          key: captureKey,
          child: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(scale)),
            child: const FoodReviewApp(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  for (final mode in [ThemeMode.light, ThemeMode.dark]) {
    for (final width in [320.0, 390.0, 428.0]) {
      testWidgets('Home sections scroll at $width, large text, ${mode.name}', (
        tester,
      ) async {
        await mount(tester, width: width, scale: 1.6, mode: mode);
        expect(find.text('Hôm nay ăn gì?'), findsOneWidget);
        expect(tester.takeException(), isNull);
        for (var i = 0; i < 7; i++) {
          await tester.drag(
            find.byType(CustomScrollView).first,
            const Offset(0, -350),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        }
        expect(find.text('Khám phá gần bạn'), findsOneWidget);
        await tester.tap(find.text('Yêu thích'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Trang chủ'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final scroll = tester.state<ScrollableState>(
          find
              .descendant(
                of: find.byType(CustomScrollView).first,
                matching: find.byType(Scrollable),
              )
              .first,
        );
        expect(scroll.position.pixels, greaterThan(0));
      });
    }
  }

  testWidgets('Category filters and clearing search restore Home sections', (
    tester,
  ) async {
    await mount(tester, missingImages: true);
    await tester.tap(find.widgetWithText(FilterChip, 'Cà phê'));
    await tester.pumpAndSettle();
    expect(find.text('Góc Cà Phê'), findsOneWidget);
    expect(find.text('Phở Nhà Mình'), findsNothing);
    await tester.tap(find.widgetWithText(FilterChip, 'Tất cả'));
    await tester.enterText(find.byType(TextField), 'không có quán');
    await tester.pumpAndSettle();
    expect(find.text('Không tìm thấy quán phù hợp.'), findsOneWidget);
    await tester.tap(find.byTooltip('Xoá nội dung'));
    await tester.pumpAndSettle();
    expect(find.text('Gợi ý cho bạn'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Review CTA selects a restaurant before opening its pending route',
    (tester) async {
      final container = await mount(tester);
      await tester.ensureVisible(find.text('Viết review'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Viết review'));
      await tester.pumpAndSettle();
      expect(find.text('Bạn muốn đánh giá quán nào?'), findsOneWidget);
      await tester.tap(find.widgetWithText(ListTile, 'Góc Cà Phê'));
      await tester.pumpAndSettle();
      expect(
        container
            .read(appRouterProvider)
            .routerDelegate
            .currentConfiguration
            .last
            .matchedLocation,
        '/restaurants/coffee-demo/reviews/create',
      );
      expect(find.text('Chức năng chưa triển khai · T13.'), findsOneWidget);
    },
  );

  testWidgets(
    'Home links use existing search, filter and notifications routes',
    (tester) async {
      final container = await mount(tester);
      final router = container.read(appRouterProvider);
      await tester.enterText(find.byType(TextField), 'phở');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();
      expect(
        router.routerDelegate.currentConfiguration.last.matchedLocation,
        '/search',
      );
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Bộ lọc'));
      await tester.pumpAndSettle();
      expect(
        router.routerDelegate.currentConfiguration.last.matchedLocation,
        '/search/filters',
      );
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Thông báo'));
      await tester.pumpAndSettle();
      expect(
        router.routerDelegate.currentConfiguration.last.matchedLocation,
        '/notifications',
      );
    },
  );

  // Opt-in review artifacts, generated from the same app and demo provider.
  if (const bool.fromEnvironment('HOME_CAPTURE')) {
    for (final mode in [ThemeMode.light, ThemeMode.dark]) {
      testWidgets('Capture ${mode.name} Home', (tester) async {
        await mount(tester, height: 1900, mode: mode);
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
        await tester.runAsync(() async {
          final node = tester.renderObject<RenderRepaintBoundary>(
            find.byKey(captureKey),
          );
          final image = await node.toImage();
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          final directory = Directory('build/home-screenshots')
            ..createSync(recursive: true);
          File('${directory.path}/home-${mode.name}.png')
              .writeAsBytesSync(bytes!.buffer.asUint8List());
          image.dispose();
        });
      });
    }
  }
}
