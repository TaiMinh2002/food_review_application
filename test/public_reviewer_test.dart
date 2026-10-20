import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_review/core/errors/app_exception.dart';
import 'package:food_review/core/router/app_router.dart';
import 'package:food_review/features/profile/domain/public_reviewer_repository.dart';
import 'package:food_review/features/profile/presentation/public_reviewer_controller.dart';
import 'package:food_review/features/reviews/data/demo_review_repository.dart';
import 'package:food_review/features/reviews/domain/review.dart';
import 'package:food_review/features/reviews/domain/review_feed_repository.dart';
import 'package:food_review/shared/design_system/design_system.dart';

import 'support/auth_harness.dart';

Review sample(
  int index, {
  String userId = 'linh-demo',
  String placeId = 'pho-demo',
  bool public = true,
}) => Review(
  id: 'review-$index',
  placeId: placeId,
  userId: userId,
  authorName: 'Hoàng Linh',
  rating: index % 5 + 1,
  content: 'Nội dung đánh giá mẫu số $index đủ dài để hiển thị.',
  createdAt: DateTime(2026, 10, 20).subtract(Duration(days: index)),
  isDemo: public,
  imageUrls: index.isEven ? ['assets/images/demo/review_pho_1.jpg'] : [],
);

void main() {
  setUpAll(loadAuthFonts);

  test('public queries exclude private submissions and other authors before counts/paging', () async {
    final repo = DemoReviewRepository(
      data: [
        for (var i = 0; i < 15; i++) sample(i),
        sample(99, public: false),
        sample(100, userId: 'nam-demo'),
      ],
    );
    addTearDown(repo.dispose);
    final profile = await repo.getPublicReviewer('linh-demo');
    expect(profile!.reviewCount, 15);
    expect(profile.photoReviewCount, 8);
    expect(profile.averageRating, 3);
    final first = await repo.getPublicReviews('linh-demo', pageSize: 6);
    final next = await repo.getPublicReviews(
      'linh-demo',
      cursor: first.nextCursor,
      pageSize: 6,
    );
    expect(first.items.length, 6);
    expect(next.items.length, 6);
    expect(
      {...first.items.map((r) => r.id), ...next.items.map((r) => r.id)}.length,
      12,
    );
    final photos = await repo.getPublicReviews(
      'linh-demo',
      filter: PublicReviewFilter.withPhotos,
    );
    expect(photos.totalCount, 8);
    expect(photos.items.every((r) => r.imageUrls.isNotEmpty), isTrue);
    final high = await repo.getPublicReviews(
      'linh-demo',
      filter: PublicReviewFilter.ratingHigh,
    );
    expect(high.items.first.rating, 5);
    expect(await repo.getPublicReviewer('private-author'), isNull);
    expect((await repo.getPublicReviewer('new-reviewer-demo'))!.reviewCount, 0);
  });

  testWidgets(
    'guest reads public profile, opens restaurant, Back retains profile, report keeps ID through login',
    (tester) async {
      final container = await mountAuth(
        tester,
        ControlledAuth(),
        route: '/users/linh-demo',
      );
      expect(find.text('Hoàng Linh'), findsNWidgets(2));
      expect(find.text('Hồ sơ và số liệu minh họa'), findsOneWidget);
      expect(find.textContaining('@'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('public-place-review-linh-demo-featured')),
        200,
        scrollable: find
            .byWidgetPredicate(
              (widget) =>
                  widget is Scrollable &&
                  widget.axisDirection == AxisDirection.down,
            )
            .first,
      );
      await tester.tap(
        find.byKey(const ValueKey('public-place-review-linh-demo-featured')),
      );
      await tester.pumpAndSettle();
      expect(
        container
            .read(appRouterProvider)
            .routerDelegate
            .currentConfiguration
            .last
            .matchedLocation,
        '/restaurants/pho-demo',
      );
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(
        container
            .read(appRouterProvider)
            .routeInformationProvider
            .value
            .uri
            .path,
        '/users/linh-demo',
      );
      await tester.tap(find.byTooltip('Tùy chọn khác'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Báo cáo người dùng'));
      await tester.pumpAndSettle();
      final uri = container.read(appRouterProvider).state.uri;
      expect(uri.path, '/login');
      final target = Uri.parse(uri.queryParameters['returnTo']!);
      expect(target.path, '/reports/create');
      expect(target.queryParameters, {
        'targetType': 'user',
        'userId': 'linh-demo',
      });
    },
  );

  testWidgets(
    'missing, empty and load failure show distinct states with retry and direct Back',
    (tester) async {
      final repo = _ControlledPublic();
      final container = await mountAuth(
        tester,
        ControlledAuth(),
        route: '/users/missing',
        publicReviewers: repo,
      );
      expect(find.text('Hồ sơ không còn khả dụng'), findsOneWidget);
      final router = container.read(appRouterProvider);
      router.go('/users/new-reviewer-demo');
      await tester.pumpAndSettle();
      expect(find.text('Chưa có bài đánh giá'), findsOneWidget);
      repo.fail = true;
      router.go('/users/linh-demo');
      await tester.pumpAndSettle();
      expect(find.text('Không thể tải dữ liệu'), findsOneWidget);
      repo.fail = false;
      await tester.tap(find.text('Thử lại'));
      await tester.pumpAndSettle();
      expect(find.text('Hoàng Linh'), findsNWidgets(2));
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(router.routeInformationProvider.value.uri.path, '/home');
      repo.dispose();
    },
  );

  testWidgets(
    'filter stale responses, pagination retry and account changes cannot restore old state',
    (tester) async {
      final repo = _ControlledPublic();
      final auth = ControlledAuth();
      final container = await mountAuth(
        tester,
        auth,
        route: '/users/linh-demo',
        publicReviewers: repo,
      );
      final provider = publicReviewerControllerProvider('linh-demo');
      final controller = container.read(provider.notifier);
      expect(container.read(provider).items.length, 10);
      repo.failPage = true;
      await controller.loadMore();
      expect(container.read(provider).items.length, 10);
      expect(container.read(provider).pageError, isNotNull);
      repo.failPage = false;
      await controller.loadMore();
      expect(container.read(provider).items.length, 13);
      expect(container.read(provider).nextCursor, isNull);
      repo.pendingPhotos = Completer<ReviewPage>();
      final old = controller.apply(PublicReviewFilter.withPhotos);
      await tester.pump();
      await controller.apply(PublicReviewFilter.ratingHigh);
      repo.pendingPhotos!.complete(ReviewPage(items: [sample(0)]));
      await old;
      expect(container.read(provider).filter, PublicReviewFilter.ratingHigh);
      expect(container.read(provider).items.first.rating, 5);
      auth.setUser(authTestUser);
      await tester.pumpAndSettle();
      expect(container.read(provider).filter, PublicReviewFilter.newest);
      expect(container.read(provider).items.length, 10);
      repo.dispose();
    },
  );

  testWidgets(
    'wrong-author response is rejected before rendering public reviews',
    (tester) async {
      final repo = _ControlledPublic()..wrongAuthor = true;
      final container = await mountAuth(
        tester,
        ControlledAuth(),
        route: '/users/linh-demo',
        publicReviewers: repo,
      );
      expect(
        find.text('Không đọc được bài đánh giá công khai.'),
        findsOneWidget,
      );
      expect(
        container.read(publicReviewerControllerProvider('linh-demo')).items,
        isEmpty,
      );
      repo.dispose();
    },
  );

  testWidgets(
    'photo chip filters published reviews and bottom tabs open the existing shell',
    (tester) async {
      final repo = _ControlledPublic();
      final container = await mountAuth(
        tester,
        ControlledAuth(),
        route: '/users/linh-demo',
        publicReviewers: repo,
      );
      final photoChip = find.widgetWithText(AppChip, 'Có ảnh');
      for (
        var i = 0;
        i < 8 && photoChip.hitTestable().evaluate().isEmpty;
        i++
      ) {
        await tester.drag(find.byType(CustomScrollView), const Offset(0, -200));
        await tester.pumpAndSettle();
      }
      await tester.tap(photoChip.hitTestable());
      await tester.pumpAndSettle();
      final state = container.read(
        publicReviewerControllerProvider('linh-demo'),
      );
      expect(state.filter, PublicReviewFilter.withPhotos);
      expect(state.profile!.reviewCount, 13);
      expect(state.items.length, 7);
      expect(state.items.every((r) => r.imageUrls.isNotEmpty), isTrue);
      await tester.tap(find.text('Trang chủ'));
      await tester.pumpAndSettle();
      expect(container.read(appRouterProvider).state.uri.path, '/home');
      expect(find.byType(NavigationBar), findsOneWidget);
      repo.dispose();
    },
  );

  testWidgets('deleted restaurant is explicit and disables its target', (
    tester,
  ) async {
    final repo = DemoReviewRepository(data: [sample(0, placeId: 'removed')]);
    addTearDown(repo.dispose);
    final container = await mountAuth(
      tester,
      ControlledAuth(),
      route: '/users/linh-demo',
      reviews: repo,
    );
    final heading = find.byKey(
      const ValueKey('public-place-review-0-featured'),
    );
    await tester.scrollUntilVisible(
      heading,
      200,
      scrollable: find
          .byWidgetPredicate(
            (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
          )
          .first,
    );
    await tester.pumpAndSettle();
    expect(find.text('Quán không còn khả dụng'), findsWidgets);
    expect(tester.widget<InkWell>(heading).onTap, isNull);
    expect(
      container.read(appRouterProvider).state.uri.path,
      '/users/linh-demo',
    );
  });

  for (final mode in [ThemeMode.light, ThemeMode.dark]) {
    for (final width in [320.0, 390.0, 428.0]) {
      testWidgets('public profile fits $width large text in $mode', (
        tester,
      ) async {
        await mountAuth(
          tester,
          ControlledAuth(),
          route: '/users/linh-demo',
          width: width,
          height: 700,
          scale: 1.6,
          mode: mode,
        );
        expect(tester.takeException(), isNull);
        await tester.drag(
          find.byType(CustomScrollView),
          const Offset(0, -1400),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.byType(NavigationBar), findsOneWidget);
      });
    }
    testWidgets('capture public profile $mode', (tester) async {
      await mountAuth(
        tester,
        ControlledAuth(),
        route: '/users/linh-demo',
        height: 1000,
        mode: mode,
      );
      if (Platform.environment['CAPTURE_PUBLIC_REVIEWER'] == '1') {
        await tester.runAsync(() async {
          // Let bundled image decodes finish before recording the comparison.
          await Future<void>.delayed(const Duration(milliseconds: 100));
        });
        await tester.pump();
        final boundary =
            loginCaptureKey.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
        await tester.runAsync(() async {
          final image = await boundary.toImage(pixelRatio: 2);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          await File('/tmp/t24-stitch/flutter-${mode.name}.png')
              .writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }
      expect(tester.takeException(), isNull);
    });
  }
}

class _ControlledPublic implements PublicReviewerRepository {
  final demo = DemoReviewRepository(
    data: [for (var i = 0; i < 13; i++) sample(i)],
  );
  bool fail = false, failPage = false, wrongAuthor = false;
  Completer<ReviewPage>? pendingPhotos;
  void dispose() => demo.dispose();
  @override
  Future<PublicReviewer?> getPublicReviewer(String userId) async {
    if (fail) throw const AppException('Lỗi tải hồ sơ mô phỏng.');
    return demo.getPublicReviewer(userId);
  }

  @override
  Future<ReviewPage> getPublicReviews(
    String userId, {
    PublicReviewFilter filter = PublicReviewFilter.newest,
    String? cursor,
    int pageSize = 10,
  }) async {
    if (wrongAuthor) return ReviewPage(items: [sample(99, userId: 'other')]);
    if (failPage && cursor != null) {
      throw const AppException('Lỗi phân trang mô phỏng.');
    }
    if (filter == PublicReviewFilter.withPhotos && pendingPhotos != null) {
      return pendingPhotos!.future;
    }
    return demo.getPublicReviews(
      userId,
      filter: filter,
      cursor: cursor,
      pageSize: pageSize,
    );
  }

  @override
  Stream<void> watchPublicReviewerChanges(String userId) =>
      demo.watchPublicReviewerChanges(userId);
}
