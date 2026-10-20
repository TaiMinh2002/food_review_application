import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_review/core/errors/app_exception.dart';
import 'package:food_review/core/router/app_router.dart';
import 'package:food_review/features/profile/domain/user_profile.dart';
import 'package:food_review/features/reviews/data/demo_review_repository.dart';
import 'package:food_review/features/reviews/domain/user_review_repository.dart';
import 'package:food_review/features/reviews/presentation/my_reviews_controller.dart';
import 'package:food_review/shared/design_system/design_system.dart';

import 'support/auth_harness.dart';
import 'support/my_review_fixtures.dart';

class _FailingDelete extends DemoReviewRepository {
  _FailingDelete() : super(data: ownedReviews(count: 1));
  int deletes = 0;
  @override
  Future<void> delete({
    required String userId,
    required String placeId,
    required String reviewId,
  }) async {
    deletes++;
    throw const AppException('Không thể xóa đánh giá. Thử lại sau.');
  }
}

void main() {
  setUpAll(loadAuthFonts);

  for (final width in [320.0, 390.0, 428.0]) {
    for (final mode in [ThemeMode.light, ThemeMode.dark]) {
      testWidgets('My Reviews fits $width ${mode.name} at large text', (
        tester,
      ) async {
        final repository = DemoReviewRepository(data: ownedReviews(count: 3));
        addTearDown(repository.dispose);
        await mountAuth(
          tester,
          ControlledAuth(user: authTestUser),
          route: '/my-reviews',
          reviews: repository,
          width: width,
          scale: 1.6,
          mode: mode,
        );
        expect(
          tester
              .widget<NavigationBar>(find.byType(NavigationBar))
              .selectedIndex,
          3,
        );
        await tester.drag(find.byType(Scrollable).first, const Offset(0, -400));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('Filters use total counts and detail Back retains the filter', (
    tester,
  ) async {
    final repository = DemoReviewRepository(data: ownedReviews());
    addTearDown(repository.dispose);
    final container = await mountAuth(
      tester,
      ControlledAuth(user: authTestUser),
      route: '/my-reviews',
      reviews: repository,
    );
    expect(find.text('Tất cả (23)'), findsOneWidget);
    expect(find.text('Có ảnh (12)'), findsOneWidget);
    await tester.tap(find.widgetWithText(AppChip, 'Có ảnh (12)'));
    await tester.pumpAndSettle();
    expect(container.read(myReviewsControllerProvider).items.length, 10);
    expect(
      container
          .read(myReviewsControllerProvider)
          .items
          .every((r) => r.imageUrls.isNotEmpty),
      isTrue,
    );
    await tester.tap(find.byTooltip('Tùy chọn đánh giá').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Xem trang quán'));
    await tester.pumpAndSettle();
    expect(
      container.read(appRouterProvider).state.uri.path,
      '/restaurants/pho-demo',
    );
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(container.read(appRouterProvider).state.uri.path, '/my-reviews');
    expect(
      container.read(myReviewsControllerProvider).filter,
      UserReviewFilter.withPhotos,
    );
    await tester.tap(find.widgetWithText(AppChip, 'Đã chỉnh sửa (8)'));
    await tester.pumpAndSettle();
    expect(container.read(myReviewsControllerProvider).items.length, 8);
  });

  testWidgets(
    'Create review asks for a restaurant and opens the selected place',
    (tester) async {
      final repository = DemoReviewRepository(data: []);
      addTearDown(repository.dispose);
      final container = await mountAuth(
        tester,
        ControlledAuth(user: authTestUser),
        route: '/my-reviews',
        reviews: repository,
      );
      await tester.tap(find.byTooltip('Tạo đánh giá mới'));
      await tester.pumpAndSettle();
      expect(find.text('Chọn quán để viết đánh giá'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'ca phe');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      expect(find.text('Phở Nhà Mình'), findsNothing);
      await tester.tap(find.text('Góc Cà Phê'));
      await tester.pumpAndSettle();
      expect(
        container.read(appRouterProvider).state.uri.path,
        '/restaurants/coffee-demo/reviews/create',
      );
    },
  );

  testWidgets(
    'Load-more button appends bounded pages without changing total count',
    (tester) async {
      final repository = DemoReviewRepository(data: ownedReviews());
      addTearDown(repository.dispose);
      final container = await mountAuth(
        tester,
        ControlledAuth(user: authTestUser),
        route: '/my-reviews',
        reviews: repository,
      );
      for (final count in [20, 23]) {
        await tester.scrollUntilVisible(
          find.text('Tải thêm đánh giá'),
          550,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(find.text('Tải thêm đánh giá'));
        await tester.pumpAndSettle();
        expect(container.read(myReviewsControllerProvider).items.length, count);
        expect(
          container
              .read(myReviewsControllerProvider)
              .summary
              .asData!
              .value
              .total,
          23,
        );
      }
      expect(container.read(myReviewsControllerProvider).nextCursor, isNull);
    },
  );

  testWidgets(
    'Delete errors keep the card and a changed account cannot confirm old deletion',
    (tester) async {
      final repository = _FailingDelete();
      addTearDown(repository.dispose);
      final auth = ControlledAuth(user: authTestUser);
      final container = await mountAuth(
        tester,
        auth,
        route: '/my-reviews',
        reviews: repository,
      );
      await tester.tap(find.byTooltip('Tùy chọn đánh giá'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Xóa đánh giá'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(AppButton, 'Xóa đánh giá'));
      await tester.pumpAndSettle();
      expect(repository.deletes, 1);
      expect(container.read(myReviewsControllerProvider).items.length, 1);
      await tester.ensureVisible(
        find.text('Không thể xóa đánh giá. Thử lại sau.'),
      );
      expect(find.text('Không thể xóa đánh giá. Thử lại sau.'), findsOneWidget);
      await tester.ensureVisible(find.byTooltip('Tùy chọn đánh giá'));
      await tester.tap(find.byTooltip('Tùy chọn đánh giá'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Xóa đánh giá'));
      await tester.pumpAndSettle();
      auth.setUser(const UserProfile(id: 'user-b', displayName: 'B'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(AppButton, 'Xóa đánh giá'));
      await tester.pumpAndSettle();
      expect(repository.deletes, 1);
      expect(find.text('Trải nghiệm 0'), findsNothing);
    },
  );

  testWidgets(
    'Restaurant picker scrolls in a short viewport with keyboard and large text',
    (tester) async {
      final repository = DemoReviewRepository(data: []);
      addTearDown(repository.dispose);
      await mountAuth(
        tester,
        ControlledAuth(user: authTestUser),
        route: '/my-reviews',
        reviews: repository,
        width: 640,
        height: 430,
        scale: 1.6,
      );
      await tester.tap(find.byTooltip('Tạo đánh giá mới'));
      await tester.pumpAndSettle();
      tester.view.viewInsets = const FakeViewPadding(bottom: 220);
      addTearDown(tester.view.resetViewInsets);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Capture My Reviews light and dark for visual comparison', (
    tester,
  ) async {
    for (final mode in [ThemeMode.light, ThemeMode.dark]) {
      final repository = DemoReviewRepository(data: ownedReviews(count: 3));
      addTearDown(repository.dispose);
      await mountAuth(
        tester,
        ControlledAuth(user: authTestUser),
        route: '/my-reviews',
        reviews: repository,
        mode: mode,
      );
      final boundary =
          loginCaptureKey.currentContext!.findRenderObject()
              as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final rendered = await boundary.toImage(pixelRatio: 2);
        final bytes = await rendered.toByteData(format: ui.ImageByteFormat.png);
        await Directory('/tmp/t19-stitch').create(recursive: true);
        await File('/tmp/t19-stitch/flutter-${mode.name}.png')
            .writeAsBytes(bytes!.buffer.asUint8List());
        rendered.dispose();
      });
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    }
  });
}
