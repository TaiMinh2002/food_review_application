import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'support/auth_fixtures.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:food_review/app/food_review_app.dart';
import 'package:food_review/core/router/app_route.dart';
import 'package:food_review/core/router/app_router.dart';
import 'package:food_review/features/favorites/presentation/favorite_providers.dart';
import 'package:food_review/features/places/data/demo_place_fixtures.dart';
import 'package:food_review/features/places/data/demo_place_repository.dart';
import 'package:food_review/features/places/presentation/map_controller.dart';
import 'package:go_router/go_router.dart';

void main() {
  Future<GoRouter> mount(WidgetTester tester, {bool signedIn = true}) async {
    final container = ProviderContainer(
      overrides: [
        mapTilesEnabledProvider.overrideWithValue(false),
        signedIn ? signedInSession : guestSession,
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const FoodReviewApp(),
      ),
    );
    await tester.pumpAndSettle();
    return container.read(appRouterProvider);
  }

  test(
    'Return-to accepts known internal routes and rejects unsafe destinations',
    () {
      const target = '/restaurants/pho-demo/reviews/create?source=detail';
      expect(safeReturnTo(target), target);
      for (final target in [
        'https://example.com/home',
        '//example.com/home',
        '/unknown',
        '/login',
        '/register',
        '/forgot-password',
        '/admin/reports',
        '/admin/reports/123',
        '/home#fragment',
        '/home/../profile',
        '/%2fexample.com',
        '/%5cevil',
        '/home%0a',
      ]) {
        expect(safeReturnTo(target), isNull, reason: target);
      }
    },
  );

  test(
    'Opt-in demo fixtures support images, missing images, and empty data',
    () async {
      final repository = DemoPlaceRepository(
        data: DemoPlaceFixtures.withImages,
      );
      final places = await repository.fetchPlaces();
      expect(places.first.imageUrls, isNotEmpty);
      expect((await repository.getPlace(places.first.id))?.id, places.first.id);
      expect(await repository.getPlace('missing'), isNull);
      expect(
        await DemoPlaceRepository(data: DemoPlaceFixtures.empty).fetchPlaces(),
        isEmpty,
      );
      expect(DemoPlaceFixtures.withoutImages.first.imageUrls, isEmpty);
      expect(() => places.clear(), throwsUnsupportedError);
    },
  );

  testWidgets('Four tabs preserve discovery query through tab switches', (
    tester,
  ) async {
    final router = await mount(tester);
    await tester.enterText(find.byType(TextField), 'phở');
    for (final tab in ['Bản đồ', 'Yêu thích', 'Cá nhân']) {
      await tester.tap(find.text(tab));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.text('Trang chủ'));
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, '/home');
    expect(
      tester.widget<EditableText>(find.byType(EditableText)).controller.text,
      'phở',
    );
    expect(find.text('Góc Cà Phê'), findsNothing);
  });

  testWidgets('Legacy URLs redirect and preserve login action context', (
    tester,
  ) async {
    final router = await mount(tester, signedIn: false);
    router.go('/places?category=pho');
    await tester.pumpAndSettle();
    expect(
      router.routeInformationProvider.value.uri.toString(),
      '/home?category=pho',
    );
    router.go('/places/pho-demo?source=favorites');
    await tester.pumpAndSettle();
    expect(
      router.routeInformationProvider.value.uri.path,
      '/restaurants/pho-demo',
    );
    expect(
      router.routeInformationProvider.value.uri.queryParameters['source'],
      'favorites',
    );
    const target = '/restaurants/pho-demo/reviews/create';
    router.go(
      Uri(path: '/sign-in', queryParameters: {'returnTo': target}).toString(),
    );
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, '/login');
    expect(
      router.routeInformationProvider.value.uri.queryParameters['returnTo'],
      target,
    );
    router.go('/login?returnTo=https%3A%2F%2Fexample.com');
    await tester.pumpAndSettle();
    expect(
      router.routeInformationProvider.value.uri.queryParameters,
      isNot(contains('returnTo')),
    );
  });

  testWidgets('Detail pushed from Favorites returns to the same tab', (
    tester,
  ) async {
    final container = ProviderContainer(overrides: [signedInSession]);
    addTearDown(container.dispose);
    container.read(favoriteIdsProvider.notifier).toggle('pho-demo');
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const FoodReviewApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Yêu thích'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Phở Nhà Mình'));
    await tester.pumpAndSettle();
    expect(find.text('Chi tiết quán'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(
      container.read(appRouterProvider).routeInformationProvider.value.uri.path,
      '/favorites',
    );
    expect(find.text('Phở Nhà Mình'), findsOneWidget);
  });

  testWidgets('Detail direct links have toolbar and system Back fallbacks', (
    tester,
  ) async {
    final router = await mount(tester);
    router.go('/restaurants/pho-demo');
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, '/home');
    router.go('/restaurants/missing');
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, '/home');
  });

  testWidgets('Pending destinations resolve and admin is denied by default', (
    tester,
  ) async {
    final router = await mount(tester);
    for (final route in AppRoute.values.where((route) => route.task != null)) {
      final parameters = <String, String>{
        for (final match in RegExp(r':(\w+)').allMatches(route.path))
          match[1]!: 'demo',
      };
      router.go(route.location(parameters: parameters));
      await tester.pumpAndSettle();
      expect(
        find.text('Không tìm thấy trang.'),
        findsNothing,
        reason: route.name,
      );
      expect(
        find.text(
          route == AppRoute.register
              ? 'Tạo tài khoản'
              : route == AppRoute.forgotPassword
              ? 'Quên mật khẩu?'
              : route == AppRoute.createReview
              ? 'Không tìm thấy quán.'
              : route == AppRoute.editReview
              ? 'Không tìm thấy đánh giá.'
              : route == AppRoute.myReviews
              ? 'Đánh giá của tôi'
              : route.isAdmin
              ? 'Không có quyền truy cập. Quyền quản trị chưa được xác minh.'
              : 'Chức năng chưa triển khai · ${route.task}.',
        ),
        findsOneWidget,
        reason: route.name,
      );
    }
  });
}
