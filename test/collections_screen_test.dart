import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_review/shared/widgets/app_bottom_navigation.dart';
import 'package:food_review/core/router/app_router.dart';
import 'package:food_review/features/collections/domain/collection_repository.dart';
import 'package:food_review/features/collections/presentation/collection_card.dart';
import 'package:food_review/features/collections/presentation/collections_controller.dart';
import 'package:food_review/features/favorites/presentation/favorite_providers.dart';
import 'package:food_review/features/want_to_visit/presentation/want_to_visit_providers.dart';
import 'package:food_review/features/profile/domain/user_profile.dart';

import 'support/auth_harness.dart';
import 'support/collections_harness.dart';

Future<void> menu(WidgetTester tester, String name) async {
  final finder = find.byTooltip('Tùy chọn $name');
  await tester.scrollUntilVisible(
    finder,
    220,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> deleteDialog(WidgetTester tester, String name) async {
  await menu(tester, name);
  await tester.tap(find.text('Xóa bộ sưu tập'));
  await tester.pumpAndSettle();
}

Future<void> confirm(WidgetTester tester) async {
  await tester.tap(
    find.descendant(of: find.byType(AlertDialog), matching: find.text('Xóa')),
  );
  await tester.pump();
}

void main() {
  setUpAll(loadAuthFonts);
  testWidgets(
    'Profile opens Collections with favorites tab; sort and editor IDs preserve Back',
    (tester) async {
      final container = await mountAuth(
        tester,
        ControlledAuth(user: authTestUser),
        route: '/profile',
      );
      await tester.scrollUntilVisible(
        find.text('Bộ sưu tập'),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Bộ sưu tập'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bộ sưu tập'));
      await tester.pumpAndSettle();
      final router = container.read(appRouterProvider);
      expect(router.state.uri.path, '/collections');
      expect(
        tester
            .widget<AppBottomNavigation>(find.byType(AppBottomNavigation))
            .selectedIndex,
        2,
      );
      expect(find.byType(CollectionCard), findsNWidgets(4));
      expect(find.text('4 bộ sưu tập'), findsOneWidget);
      expect(
        find.text('Bộ sưu tập mẫu • Chỉ lưu trong phiên ứng dụng'),
        findsOneWidget,
      );
      await tester.tap(find.byTooltip('Sắp xếp bộ sưu tập'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.widgetWithText(CheckedPopupMenuItem<CollectionSort>, 'Tên A–Z'),
      );
      await tester.pumpAndSettle();
      expect(
        container.read(collectionsControllerProvider).sort,
        CollectionSort.name,
      );
      await tester.tap(find.text('Quán ngon Hà Nội'));
      await tester.pumpAndSettle();
      expect(router.state.uri.path, '/collections/hanoi-demo/edit');
      expect(find.text('Chỉnh sửa bộ sưu tập'), findsOneWidget);
      router.pop();
      await tester.pumpAndSettle();
      expect(
        container.read(collectionsControllerProvider).sort,
        CollectionSort.name,
      );
      await tester.tap(find.byTooltip('Tạo bộ sưu tập mới'));
      await tester.pumpAndSettle();
      expect(router.state.uri.path, '/collections/create');
      router.pop();
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Quay lại'));
      await tester.pumpAndSettle();
      expect(router.state.uri.path, '/profile');
    },
  );

  testWidgets(
    'Delete cancel/success changes collection count but preserves both saved lists',
    (tester) async {
      final container = await mountAuth(
        tester,
        ControlledAuth(user: authTestUser),
        route: '/collections',
      );
      container.read(favoriteIdsProvider.notifier).toggle('pho-demo');
      container.read(wantToVisitIdsProvider.notifier).toggle('pho-demo');
      await deleteDialog(tester, 'Quán ngon Hà Nội');
      await tester.tap(find.text('Huỷ'));
      await tester.pumpAndSettle();
      expect(container.read(collectionsControllerProvider).total, 4);
      await deleteDialog(tester, 'Quán ngon Hà Nội');
      await confirm(tester);
      await tester.pumpAndSettle();
      expect(find.text('Quán ngon Hà Nội'), findsNothing);
      expect(find.text('3 bộ sưu tập'), findsOneWidget);
      expect(container.read(favoriteIdsProvider), {'pho-demo'});
      expect(container.read(wantToVisitIdsProvider), {'pho-demo'});
      await menu(tester, 'Đi hẹn hò');
      final share = tester.widget<PopupMenuItem<CollectionAction>>(
        find.ancestor(
          of: find.text('Chia sẻ với bạn bè'),
          matching: find.byType(PopupMenuItem<CollectionAction>),
        ),
      );
      expect(share.enabled, isFalse);
    },
  );

  testWidgets('Delete errors keep the card and retry cannot submit twice', (
    tester,
  ) async {
    var deleted = false;
    final repository = ScriptedCollections()
      ..deleteError = Exception('private SDK detail');
    repository.onQuery = (_) async => CollectionPage(
      items: deleted ? [] : [sampleCollection('a')],
      total: deleted ? 0 : 1,
    );
    await mountAuth(
      tester,
      ControlledAuth(user: authTestUser),
      route: '/collections',
      collections: repository,
    );
    await deleteDialog(tester, 'Bộ sưu tập a');
    await confirm(tester);
    await tester.pumpAndSettle();
    expect(
      find.text('Không xóa được bộ sưu tập. Vui lòng thử lại.'),
      findsOneWidget,
    );
    expect(find.text('Bộ sưu tập a'), findsOneWidget);
    repository.deleteError = null;
    repository.pendingDelete = Completer<void>();
    await deleteDialog(tester, 'Bộ sưu tập a');
    await confirm(tester);
    await tester.pump(const Duration(milliseconds: 100));
    expect(repository.deletes, hasLength(2));
    expect(
      tester
          .widget<PopupMenuButton<CollectionAction>>(
            find.byType(PopupMenuButton<CollectionAction>),
          )
          .enabled,
      isFalse,
    );
    deleted = true;
    repository.pendingDelete!.complete();
    await tester.pumpAndSettle();
    expect(find.text('Bạn chưa có bộ sưu tập nào'), findsOneWidget);
  });

  testWidgets(
    'Old account dialog cannot delete new account collections; logout hides cache',
    (tester) async {
      final auth = ControlledAuth(user: authTestUser);
      final repository = ScriptedCollections()
        ..onQuery = (q) async => CollectionPage(
          items: [sampleCollection(q.ownerId, owner: q.ownerId)],
          total: 1,
        );
      final container = await mountAuth(
        tester,
        auth,
        route: '/collections',
        collections: repository,
      );
      await deleteDialog(tester, 'Bộ sưu tập user-a');
      auth.setUser(const UserProfile(id: 'b', displayName: 'B'));
      await tester.pumpAndSettle();
      await confirm(tester);
      await tester.pumpAndSettle();
      expect(repository.deletes, isEmpty);
      expect(find.text('Bộ sưu tập user-a'), findsNothing);
      expect(find.text('Bộ sưu tập b'), findsOneWidget);
      auth.setUser(null);
      await tester.pumpAndSettle();
      expect(container.read(appRouterProvider).state.uri.path, '/login');
      expect(find.text('Bộ sưu tập b'), findsNothing);
    },
  );

  testWidgets(
    'Guest is redirected, loading session makes no private query; empty action reaches T22',
    (tester) async {
      final auth = ControlledAuth(initialReady: false);
      final repository = ScriptedCollections();
      final container = await mountAuth(
        tester,
        auth,
        route: '/collections',
        collections: repository,
      );
      expect(repository.queries, isEmpty);
      auth.setUser(null);
      await tester.pumpAndSettle();
      expect(
        container.read(appRouterProvider).state.uri.queryParameters['returnTo'],
        '/collections',
      );
      auth.setUser(authTestUser);
      container.read(appRouterProvider).go('/collections');
      await tester.pumpAndSettle();
      expect(find.text('Bạn chưa có bộ sưu tập nào'), findsOneWidget);
      await tester.tap(find.text('Tạo bộ sưu tập'));
      await tester.pumpAndSettle();
      expect(
        container.read(appRouterProvider).state.uri.path,
        '/collections/create',
      );
    },
  );

  testWidgets(
    'Late delete result cannot refresh or report success into another account',
    (tester) async {
      final auth = ControlledAuth(user: authTestUser);
      final repository = ScriptedCollections()
        ..pendingDelete = Completer<void>();
      repository.onQuery = (q) async => CollectionPage(
        items: [sampleCollection(q.ownerId, owner: q.ownerId)],
        total: 1,
      );
      final container = await mountAuth(
        tester,
        auth,
        route: '/collections',
        collections: repository,
      );
      await deleteDialog(tester, 'Bộ sưu tập user-a');
      await confirm(tester);
      auth.setUser(const UserProfile(id: 'b', displayName: 'B'));
      await tester.pumpAndSettle();
      final queriesBefore = repository.queries.length;
      repository.pendingDelete!.complete();
      await tester.pumpAndSettle();
      expect(repository.queries.length, queriesBefore);
      expect(
        container.read(collectionsControllerProvider).items.single.ownerId,
        'b',
      );
      expect(find.text('Đã xóa bộ sưu tập'), findsNothing);
    },
  );

  for (final mode in [ThemeMode.light, ThemeMode.dark]) {
    for (final width in [320.0, 390.0, 428.0]) {
      testWidgets('Collection grid and menu fit $width $mode at large text', (
        tester,
      ) async {
        await mountAuth(
          tester,
          ControlledAuth(user: authTestUser),
          route: '/collections',
          mode: mode,
          width: width,
          scale: 1.6,
        );
        await menu(tester, 'Quán ngon Hà Nội');
        expect(tester.takeException(), isNull);
        await tester.tap(find.text('Xóa bộ sưu tập'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.tap(find.text('Huỷ'));
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          find.text('Ăn ngon tiết kiệm'),
          250,
          scrollable: find.byType(Scrollable).first,
        );
        expect(tester.takeException(), isNull);
      });
    }
    testWidgets('Render Collections $mode for Stitch comparison', (
      tester,
    ) async {
      await mountAuth(
        tester,
        ControlledAuth(user: authTestUser),
        route: '/collections',
        mode: mode,
        height: 960,
      );
      if (Platform.environment['CAPTURE_COLLECTIONS'] == '1') {
        final boundary =
            loginCaptureKey.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
        await tester.runAsync(() async {
          final image = await boundary.toImage(pixelRatio: 2);
          final data = await image.toByteData(format: ui.ImageByteFormat.png);
          await File('/tmp/t21-stitch/flutter-${mode.name}.png')
              .writeAsBytes(data!.buffer.asUint8List());
          image.dispose();
        });
      }
      expect(tester.takeException(), isNull);
    });
  }
}
