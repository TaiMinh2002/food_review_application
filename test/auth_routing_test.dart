import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_review/core/errors/app_exception.dart';
import 'package:food_review/features/auth/presentation/auth_providers.dart';
import 'package:food_review/core/router/app_route.dart';
import 'package:food_review/core/router/app_router.dart';
import 'package:food_review/features/favorites/presentation/favorite_providers.dart';
import 'package:food_review/shared/widgets/app_button.dart';

import 'support/auth_harness.dart';

void main() {
  setUpAll(loadAuthFonts);
  Future<void> login(WidgetTester tester) async {
    await fillLogin(tester);
    final button = find.widgetWithText(AppButton, 'Đăng nhập');
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();
  }

  testWidgets(
    'Guest private destinations preserve complete context; public reads remain accessible',
    (tester) async {
      final container = await mountAuth(
        tester,
        ControlledAuth(),
        route: '/home',
      );
      final router = container.read(appRouterProvider);
      for (final route in AppRoute.values.where(
        (route) => route.requiresAuth,
      )) {
        final params = {
          for (final match in RegExp(r':(\w+)').allMatches(route.path))
            match[1]!: 'demo',
        };
        final target = route.location(
          parameters: params,
          query: {'restaurantId': 'pho-demo', 'reviewId': 'review-linh-demo'},
        );
        router.go(target);
        await tester.pumpAndSettle();
        expect(router.state.uri.path, '/login', reason: route.name);
        expect(router.state.uri.queryParameters['returnTo'], target);
        expect(
          find.text('Chức năng chưa triển khai · ${route.task}.'),
          findsNothing,
        );
      }
      for (final path in [
        '/home',
        '/restaurants/pho-demo',
        '/restaurants/pho-demo/reviews',
        '/restaurants/pho-demo/gallery',
        '/users/linh-demo',
      ]) {
        router.go(path);
        await tester.pumpAndSettle();
        expect(router.state.uri.path, path);
      }
      router.go('/admin/reports');
      await tester.pumpAndSettle();
      expect(
        find.text(
          'Không có quyền truy cập. Quyền quản trị chưa được xác minh.',
        ),
        findsOneWidget,
      );
    },
  );

  for (final authenticated in [false, true]) {
    testWidgets(
      'Initial session loading never flashes private content; restored signedIn=$authenticated',
      (tester) async {
        final repo = ControlledAuth(initialReady: false);
        final container = await mountAuth(
          tester,
          repo,
          route: '/restaurants/pho-demo/reviews/create',
        );
        expect(find.text('Chức năng chưa triển khai · T13.'), findsNothing);
        repo.setUser(authenticated ? authTestUser : null);
        await tester.pumpAndSettle();
        expect(
          container.read(appRouterProvider).state.uri.path,
          authenticated ? '/restaurants/pho-demo/reviews/create' : '/login',
        );
        expect(find.text('Chức năng chưa triển khai · T13.'), findsNothing);
        expect(
          find.text('Bạn đánh giá quán thế nào?'),
          authenticated ? findsOneWidget : findsNothing,
        );
      },
    );
  }

  testWidgets(
    'Login returns to original report IDs and Back source without recreating router',
    (tester) async {
      final repo = ControlledAuth()..autoSignIn = true;
      final container = await mountAuth(
        tester,
        repo,
        route: '/restaurants/pho-demo',
      );
      final router = container.read(appRouterProvider);
      final target = AppRoute.createReport.location(
        query: {
          'targetType': 'review',
          'restaurantId': 'pho-demo',
          'reviewId': 'review-linh-demo',
        },
      );
      unawaited(router.push(target));
      await tester.pumpAndSettle();
      expect(router.state.uri.path, '/login');
      await login(tester);
      expect(router.state.uri.path, '/reports/create');
      expect(router.state.uri.queryParameters['reviewId'], 'review-linh-demo');
      expect(identical(container.read(appRouterProvider), router), isTrue);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(router.state.uri.path, '/restaurants/pho-demo');
    },
  );

  testWidgets(
    'Cancel does not reopen target or act when pending sign-in later completes',
    (tester) async {
      final repo = ControlledAuth()
        ..pendingSignIn = Completer<void>()
        ..autoSignIn = true;
      final container = await mountAuth(
        tester,
        repo,
        route: '/restaurants/pho-demo',
      );
      final router = container.read(appRouterProvider);
      unawaited(router.push('/restaurants/pho-demo/reviews/create'));
      await tester.pumpAndSettle();
      await fillLogin(tester);
      final submit = find.widgetWithText(AppButton, 'Đăng nhập');
      await tester.ensureVisible(submit);
      await tester.tap(submit);
      await tester.pump();
      await tester.tap(find.byTooltip('Quay lại'));
      await tester.pumpAndSettle();
      repo.pendingSignIn!.complete();
      await tester.pumpAndSettle();
      expect(router.state.uri.path, '/restaurants/pho-demo');
      expect(find.text('Chức năng chưa triển khai · T13.'), findsNothing);
      expect(container.read(favoriteIdsProvider), isEmpty);
    },
  );

  testWidgets(
    'Favorite asks for login once and requires another tap after success',
    (tester) async {
      final repo = ControlledAuth()..autoSignIn = true;
      final container = await mountAuth(
        tester,
        repo,
        route: '/restaurants/pho-demo',
      );
      final router = container.read(appRouterProvider);
      await tester.tap(find.byTooltip('Lưu yêu thích'));
      await tester.pumpAndSettle();
      expect(router.state.uri.path, '/login');
      expect(find.textContaining('chạm lại biểu tượng tim'), findsOneWidget);
      await login(tester);
      expect(router.state.uri.path, '/restaurants/pho-demo');
      expect(container.read(favoriteIdsProvider), isEmpty);
      await tester.tap(find.byTooltip('Lưu yêu thích'));
      await tester.pumpAndSettle();
      expect(container.read(favoriteIdsProvider), {'pho-demo'});
      repo.setUser(null);
      await tester.pumpAndSettle();
      expect(container.read(favoriteIdsProvider), isEmpty);
    },
  );

  testWidgets(
    'Guest favorites invite login; successful logout clears private content and errors allow retry',
    (tester) async {
      final repo = ControlledAuth();
      final container = await mountAuth(tester, repo, route: '/favorites');
      expect(find.text('Đăng nhập để tiếp tục'), findsOneWidget);
      final router = container.read(appRouterProvider);
      repo.setUser(authTestUser);
      await tester.pumpAndSettle();
      container.read(favoriteIdsProvider.notifier).toggle('pho-demo');
      router.go('/profile');
      await tester.pumpAndSettle();
      expect(find.text('Chào Người thử nghiệm!'), findsOneWidget);
      repo.pendingSignOut = Completer<void>();
      await tester.tap(find.text('Đăng xuất'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Đăng xuất'),
        ),
      );
      await tester.pump();
      repo.pendingSignOut!.completeError(Exception('SDK private detail'));
      await tester.pumpAndSettle();
      expect(
        find.text('Không đăng xuất được. Vui lòng thử lại.'),
        findsOneWidget,
      );
      repo.pendingSignOut = null;
      await tester.tap(find.text('Đăng xuất'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Đăng xuất'),
        ),
      );
      await tester.pumpAndSettle();
      expect(container.read(favoriteIdsProvider), isEmpty);
      expect(find.text('Đăng xuất'), findsNothing);
      router.go('/my-reviews');
      await tester.pumpAndSettle();
      expect(router.state.uri.path, '/login');
    },
  );

  testWidgets('Unsafe return-to is discarded even after successful sign-in', (
    tester,
  ) async {
    final repo = ControlledAuth()..autoSignIn = true;
    final container = await mountAuth(
      tester,
      repo,
      route: '/login?returnTo=https%3A%2F%2Fevil.example',
    );
    await login(tester);
    expect(container.read(appRouterProvider).state.uri.path, '/home');
  });

  testWidgets(
    'Refresh and session errors hide cached private content until retry resolves',
    (tester) async {
      final repo = ControlledAuth(user: authTestUser);
      final container = await mountAuth(tester, repo, route: '/my-reviews');
      expect(find.text('Đánh giá của tôi'), findsOneWidget);
      repo.initialReady = false;
      container.invalidate(authSessionProvider);
      await tester.pumpAndSettle();
      expect(find.text('Đánh giá của tôi'), findsNothing);
      repo.events.addError(const AppException('Phiên chưa xác định'));
      await tester.pumpAndSettle();
      expect(find.text('Phiên chưa xác định'), findsOneWidget);
      expect(find.text('Đánh giá của tôi'), findsNothing);
      repo.initialReady = true;
      await tester.tap(find.text('Thử lại'));
      await tester.pumpAndSettle();
      expect(find.text('Đánh giá của tôi'), findsOneWidget);
    },
  );
}
