import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_review/core/router/app_router.dart';
import 'package:food_review/features/collections/data/demo_collection_repository.dart';
import 'package:food_review/features/collections/presentation/collection_editor_widgets.dart';
import 'package:food_review/features/collections/presentation/collections_controller.dart';
import 'package:food_review/features/favorites/presentation/favorite_providers.dart';
import 'package:food_review/features/want_to_visit/presentation/want_to_visit_providers.dart';
import 'package:food_review/features/profile/domain/user_profile.dart';
import 'package:food_review/shared/widgets/app_button.dart';
import 'package:food_review/shared/widgets/app_text_field.dart';

import 'support/auth_harness.dart';
import 'support/collection_editor_harness.dart';

Future<void> collectionInput(
  WidgetTester tester,
  String key,
  String text,
) async {
  final field = find.descendant(
    of: find.byKey(ValueKey(key)),
    matching: find.byType(TextFormField),
  );
  await tester.ensureVisible(field);
  await tester.pumpAndSettle();
  await tester.enterText(field, text);
  await tester.pump();
}

Future<void> addPlaces(WidgetTester tester) async {
  final button = find.text('Thêm địa điểm vào danh sách');
  await tester.scrollUntilVisible(
    button,
    220,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
  await tester.tap(button);
  await tester.pumpAndSettle();
}

Future<void> save(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('save-collection')));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(loadAuthFonts);
  testWidgets(
    'Create validates name, commits picker draft only on Apply, saves once and refreshes list',
    (tester) async {
      final repository = DemoCollectionRepository(seedExamples: false);
      final container = await mountAuth(
        tester,
        ControlledAuth(user: authTestUser),
        route: '/collections',
        collections: repository,
      );
      container.read(favoriteIdsProvider.notifier).toggle('pho-demo');
      container.read(wantToVisitIdsProvider.notifier).toggle('pho-demo');
      await tester.tap(find.byTooltip('Tạo bộ sưu tập mới'));
      await tester.pumpAndSettle();
      await save(tester);
      expect(find.text('Vui lòng nhập tên bộ sưu tập.'), findsOneWidget);
      expect(
        (await repository.getCollections(ownerId: authTestUser.id)).total,
        0,
      );
      await collectionInput(tester, 'collection-name', '  Cuối tuần  ');
      await addPlaces(tester);
      await tester.tap(find.byKey(const ValueKey('pick-pho-demo')));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Đóng danh sách địa điểm'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<CollectionCoverPreview>(find.byType(CollectionCoverPreview))
            .first,
        isNull,
      );
      await addPlaces(tester);
      await tester.tap(find.byKey(const ValueKey('pick-coffee-demo')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Áp dụng (1 địa điểm)'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<CollectionCoverPreview>(find.byType(CollectionCoverPreview))
            .first!
            .id,
        'coffee-demo',
      );
      await save(tester);
      expect(container.read(appRouterProvider).state.uri.path, '/collections');
      expect(find.text('Cuối tuần'), findsOneWidget);
      expect(container.read(collectionsControllerProvider).total, 1);
      expect(container.read(favoriteIdsProvider), {'pho-demo'});
      expect(container.read(wantToVisitIdsProvider), {'pho-demo'});
    },
  );

  testWidgets(
    'Edit preloads, disables unchanged Save, updates existing ID and can remove every place',
    (tester) async {
      final repository = DemoCollectionRepository();
      final container = await mountAuth(
        tester,
        ControlledAuth(user: authTestUser),
        route: '/collections/hanoi-demo/edit',
        collections: repository,
      );
      expect(
        tester
            .widget<AppButton>(find.byKey(const ValueKey('save-collection')))
            .onPressed,
        isNull,
      );
      final original = await repository.getCollection(
        ownerId: authTestUser.id,
        collectionId: 'hanoi-demo',
      );
      for (final place in original!.places) {
        final remove = find.byTooltip('Bỏ ${place.name} khỏi bộ sưu tập');
        await tester.scrollUntilVisible(
          remove,
          240,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
        await tester.tap(remove);
        await tester.pumpAndSettle();
      }
      expect(
        tester
            .widget<CollectionCoverPreview>(find.byType(CollectionCoverPreview))
            .first,
        isNull,
      );
      await collectionInput(tester, 'collection-name', 'Rỗng nhưng hợp lệ');
      await save(tester);
      expect(container.read(appRouterProvider).state.uri.path, '/collections');
      final page = await repository.getCollections(ownerId: authTestUser.id);
      expect(page.total, 4);
      expect(page.items.firstWhere((c) => c.id == 'hanoi-demo').placeCount, 0);
    },
  );

  testWidgets(
    'Cancel and system Back confirm dirty drafts; continuing retains input, discard never writes',
    (tester) async {
      final repository = ControlledCollectionEditor();
      final container = await mountAuth(
        tester,
        ControlledAuth(user: authTestUser),
        route: '/collections/create',
        collections: repository,
      );
      await collectionInput(tester, 'collection-name', 'Nháp riêng');
      await tester.tap(find.text('Hủy'));
      await tester.pumpAndSettle();
      expect(find.text('Bỏ thay đổi?'), findsOneWidget);
      await tester.tap(find.text('Tiếp tục chỉnh sửa'));
      await tester.pumpAndSettle();
      expect(find.text('Nháp riêng'), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bỏ thay đổi'));
      await tester.pumpAndSettle();
      expect(container.read(appRouterProvider).state.uri.path, '/collections');
      expect(repository.creates, 0);
    },
  );

  testWidgets(
    'Save failure retains complete draft, retry uses same request ID and blocks duplicate submit',
    (tester) async {
      final repository = ControlledCollectionEditor()
        ..saveError = Exception('private SDK detail');
      await mountAuth(
        tester,
        ControlledAuth(user: authTestUser),
        route: '/collections/create',
        collections: repository,
      );
      await collectionInput(tester, 'collection-name', 'Giữ lại');
      await collectionInput(tester, 'collection-description', 'Nháp mô tả');
      await addPlaces(tester);
      await tester.tap(find.byKey(const ValueKey('pick-pho-demo')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Áp dụng (1 địa điểm)'));
      await tester.pumpAndSettle();
      await save(tester);
      final error = find.text('Không thể lưu bộ sưu tập. Vui lòng thử lại.');
      await tester.scrollUntilVisible(
        error,
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(error, findsOneWidget);
      expect(repository.lastDraft!.name, 'Giữ lại');
      expect(repository.lastDraft!.description, 'Nháp mô tả');
      expect(repository.lastDraft!.placeIds, ['pho-demo']);
      repository.saveError = null;
      repository.pendingSave = Completer<void>();
      await tester.tap(find.byKey(const ValueKey('save-collection')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('save-collection')));
      await tester.pump();
      expect(repository.creates, 2);
      expect(repository.requestIds.toSet(), hasLength(1));
      repository.pendingSave!.complete();
      await tester.pumpAndSettle();
      expect(
        (await repository.getCollections(ownerId: authTestUser.id)).total,
        1,
      );
    },
  );

  testWidgets(
    'Missing/wrong-owner and load failure states do not show edit form; retry works',
    (tester) async {
      final repository = ControlledCollectionEditor()
        ..loadError = Exception('private detail');
      final container = await mountAuth(
        tester,
        ControlledAuth(user: authTestUser),
        route: '/collections/a/edit',
        collections: repository,
      );
      expect(find.byKey(const ValueKey('collection-name')), findsNothing);
      repository.loadError = null;
      repository.wrongOwner = true;
      await tester.tap(find.text('Thử lại'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Không đọc được bộ sưu tập của bạn.'),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('collection-name')), findsNothing);
      repository.wrongOwner = false;
      repository.missing = true;
      await tester.tap(find.text('Thử lại'));
      await tester.pumpAndSettle();
      expect(find.text('Không tìm thấy bộ sưu tập'), findsOneWidget);
      container.read(appRouterProvider).go('/collections/create');
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('collection-name')), findsOneWidget);
    },
  );

  testWidgets(
    'Picker search does not lose previous selections and cannot add duplicate IDs',
    (tester) async {
      await mountAuth(
        tester,
        ControlledAuth(user: authTestUser),
        route: '/collections/create',
      );
      await addPlaces(tester);
      await tester.tap(find.byKey(const ValueKey('pick-pho-demo')));
      await tester.pumpAndSettle();
      final search = find.descendant(
        of: find.byType(AppSearchField),
        matching: find.byType(TextField),
      );
      await tester.enterText(search, 'zzzzzz');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      expect(find.text('Không tìm thấy địa điểm'), findsOneWidget);
      expect(find.text('Áp dụng (1 địa điểm)'), findsOneWidget);
      await tester.enterText(search, 'ca phe');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('pick-coffee-demo')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Áp dụng (2 địa điểm)'));
      await tester.pumpAndSettle();
      await addPlaces(tester);
      expect(
        tester
            .widget<CheckboxListTile>(
              find.byKey(const ValueKey('pick-pho-demo')),
            )
            .value,
        isTrue,
      );
      expect(
        tester
            .widget<CheckboxListTile>(
              find.byKey(const ValueKey('pick-coffee-demo')),
            )
            .value,
        isTrue,
      );
      await tester.tap(find.text('Áp dụng (2 địa điểm)'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<CollectionCoverPreview>(find.byType(CollectionCoverPreview))
            .first!
            .id,
        'pho-demo',
      );
    },
  );

  testWidgets(
    'Account switch clears drafts and closes picker; late save cannot navigate or toast into new session',
    (tester) async {
      final repository = ControlledCollectionEditor()
        ..pendingSave = Completer<void>();
      final auth = ControlledAuth(user: authTestUser);
      final container = await mountAuth(
        tester,
        auth,
        route: '/collections/create',
        collections: repository,
      );
      await collectionInput(tester, 'collection-name', 'Nháp A');
      await addPlaces(tester);
      auth.setUser(const UserProfile(id: 'b', displayName: 'B'));
      await tester.pumpAndSettle();
      expect(find.text('Nháp A'), findsNothing);
      expect(find.byTooltip('Đóng danh sách địa điểm'), findsNothing);
      await collectionInput(tester, 'collection-name', 'Nháp B');
      await tester.tap(find.byKey(const ValueKey('save-collection')));
      await tester.pump();
      auth.setUser(const UserProfile(id: 'c', displayName: 'C'));
      await tester.pumpAndSettle();
      repository.pendingSave!.complete();
      await tester.pumpAndSettle();
      expect(find.text('Đã tạo bộ sưu tập'), findsNothing);
      expect(
        container.read(appRouterProvider).state.uri.path,
        '/collections/create',
      );
      expect(find.text('Nháp B'), findsNothing);
      auth.setUser(null);
      await tester.pumpAndSettle();
      expect(container.read(appRouterProvider).state.uri.path, '/login');
    },
  );
}
