import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:food_review/features/collections/domain/collection_repository.dart';
import 'package:food_review/features/collections/presentation/collections_controller.dart';
import 'package:food_review/features/profile/domain/user_profile.dart';

import 'support/auth_harness.dart';
import 'support/collections_harness.dart';

void main() {
  setUpAll(loadAuthFonts);
  testWidgets(
    'First-page error retries; page error retains cards and cursor retry appends once',
    (tester) async {
      var failFirst = true, failPage = true;
      final repository = ScriptedCollections();
      repository.onQuery = (q) async {
        if (failFirst) throw Exception('private SDK detail');
        if (q.cursor == null) {
          return CollectionPage(
            items: [sampleCollection('a')],
            total: 2,
            nextCursor: 'next',
          );
        }
        if (failPage) throw Exception('private SDK detail');
        return CollectionPage(items: [sampleCollection('b')], total: 2);
      };
      final container = await mountAuth(
        tester,
        ControlledAuth(user: authTestUser),
        route: '/collections',
        collections: repository,
      );
      expect(
        find.text('Không tải được bộ sưu tập. Vui lòng thử lại.'),
        findsOneWidget,
      );
      failFirst = false;
      await tester.tap(find.text('Thử lại'));
      await tester.pumpAndSettle();
      final controller = container.read(collectionsControllerProvider.notifier);
      await controller.loadMore();
      await tester.pumpAndSettle();
      expect(
        container.read(collectionsControllerProvider).items.single.id,
        'a',
      );
      expect(
        container.read(collectionsControllerProvider).pageError,
        isNotNull,
      );
      failPage = false;
      await controller.loadMore();
      await tester.pumpAndSettle();
      expect(
        container
            .read(collectionsControllerProvider)
            .items
            .map((item) => item.id),
        ['a', 'b'],
      );
      expect(container.read(collectionsControllerProvider).nextCursor, isNull);
      await controller.loadMore();
      expect(repository.queries, hasLength(4));
    },
  );

  testWidgets(
    'Stale pages cannot overwrite a new sort or another account; wrong-owner pages rejected',
    (tester) async {
      final delayed = Completer<CollectionPage>();
      final repository = ScriptedCollections();
      repository.onQuery = (q) async {
        if (q.cursor != null) return delayed.future;
        return CollectionPage(
          items: [sampleCollection(q.sort.name, owner: q.ownerId)],
          total: 2,
          nextCursor: 'next',
        );
      };
      final auth = ControlledAuth(user: authTestUser);
      final container = await mountAuth(
        tester,
        auth,
        route: '/collections',
        collections: repository,
      );
      final controller = container.read(collectionsControllerProvider.notifier);
      final pending = controller.loadMore();
      await controller.applySort(CollectionSort.name);
      delayed.complete(
        CollectionPage(items: [sampleCollection('stale')], total: 2),
      );
      await pending;
      await tester.pumpAndSettle();
      expect(
        container.read(collectionsControllerProvider).items.single.id,
        'name',
      );
      final accountRequest = Completer<CollectionPage>();
      repository.onQuery = (q) => q.ownerId == 'user-a'
          ? accountRequest.future
          : Future.value(
              CollectionPage(
                items: [sampleCollection('b', owner: q.ownerId)],
                total: 1,
              ),
            );
      final beforeSwitch = controller.refresh();
      auth.setUser(const UserProfile(id: 'b', displayName: 'B'));
      await tester.pumpAndSettle();
      accountRequest.complete(
        CollectionPage(items: [sampleCollection('private')], total: 1),
      );
      await beforeSwitch;
      await tester.pumpAndSettle();
      expect(
        container.read(collectionsControllerProvider).items.single.id,
        'b',
      );
      repository.onQuery = (_) async =>
          CollectionPage(items: [sampleCollection('wrong-owner')], total: 1);
      await container.read(collectionsControllerProvider.notifier).refresh();
      await tester.pumpAndSettle();
      expect(find.text('Bộ sưu tập wrong-owner'), findsNothing);
      expect(container.read(collectionsControllerProvider).error, isNotNull);
    },
  );

  testWidgets(
    'Refresh awaits repository and repeated loadMore cannot issue parallel duplicate requests',
    (tester) async {
      final repository = ScriptedCollections()
        ..onQuery = (_) async => CollectionPage(
          items: [sampleCollection('a')],
          total: 2,
          nextCursor: 'next',
        );
      final container = await mountAuth(
        tester,
        ControlledAuth(user: authTestUser),
        route: '/collections',
        collections: repository,
      );
      final controller = container.read(collectionsControllerProvider.notifier);
      final page = Completer<CollectionPage>();
      repository.onQuery = (_) => page.future;
      final pending = controller.loadMore();
      await controller.loadMore();
      expect(repository.queries, hasLength(2));
      page.complete(CollectionPage(items: [sampleCollection('b')], total: 2));
      await pending;
      final refresh = Completer<CollectionPage>();
      repository.onQuery = (_) => refresh.future;
      var completed = false;
      final request = controller.refresh().then((_) => completed = true);
      await tester.pump();
      expect(completed, isFalse);
      refresh.complete(CollectionPage(items: [], total: 0));
      await request;
      await tester.pumpAndSettle();
      expect(container.read(collectionsControllerProvider).items, isEmpty);
    },
  );
}
