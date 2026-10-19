import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_review/core/router/app_route.dart';
import 'package:food_review/features/places/data/demo_place_repository.dart';
import 'package:food_review/features/places/domain/place.dart';
import 'package:food_review/features/places/domain/place_search.dart';
import 'package:food_review/features/places/domain/place_search_repository.dart';
import 'package:food_review/features/places/presentation/search_controller.dart';

const _a = Place(
  id: 'a',
  name: 'Quán A',
  description: '',
  address: '',
  category: 'Món Việt',
  latitude: 0,
  longitude: 0,
);
const _b = Place(
  id: 'b',
  name: 'Quán B',
  description: '',
  address: '',
  category: 'Cà phê',
  latitude: 0,
  longitude: 0,
);

void main() {
  test('Vietnamese names and menu searches accept accents, case and decomposed input', () async {
    final repo = DemoPlaceRepository();
    for (final query in ['  PHO  ', 'Phở', 'pho\u0309', 'bo tai lan']) {
      expect(
        (await repo.searchPlaces(PlaceSearchRequest(query: query)))
            .items
            .single
            .id,
        'pho-demo',
      );
    }
    expect(normalizePlaceSearchText('ĐỒ NƯỚNG'), 'do nuong');
    expect(
      (await repo.searchPlaces(PlaceSearchRequest(query: 'CA PHE')))
          .items
          .single
          .id,
      'coffee-demo',
    );
  });

  test('Filters combine categories by OR, amenities by AND, rating and price overlap', () async {
    final repo = DemoPlaceRepository();
    final page = await repo.searchPlaces(
      PlaceSearchRequest(
        categories: {'Phở', 'Cà phê'},
        minRating: 4,
        minPrice: 50000,
        maxPrice: 100000,
        amenities: {'Mang về', 'Có chỗ để xe'},
      ),
    );
    expect(page.items.single.id, 'pho-demo');
    expect(
      (await repo.searchPlaces(PlaceSearchRequest(categories: {'Bún'}))).items,
      isEmpty,
    );
    expect(
      (await repo.searchPlaces(PlaceSearchRequest(minRating: 4.9))).items,
      isEmpty,
    );
    expect(
      (await repo.searchPlaces(PlaceSearchRequest(sort: PlaceSearchSort.price)))
          .items
          .first
          .id,
      'banh-mi-demo',
    );
    expect(
      (await repo.searchPlaces(
        PlaceSearchRequest(sort: PlaceSearchSort.rating),
      )).items.first.id,
      'pho-demo',
    );
    expect(
      (await repo.searchPlaces(
        PlaceSearchRequest(sort: PlaceSearchSort.reviews),
      )).items.first.id,
      'pho-demo',
    );
    expect(
      (await DemoPlaceRepository(data: [_a])
              .searchPlaces(PlaceSearchRequest(minPrice: 10000)))
          .items,
      isEmpty,
    );
  });

  test(
    'Cursor pages have stable ordering, correct totals and immutable snapshots',
    () async {
      final data = List.generate(
        25,
        (index) => Place(
          id: 'place-${index.toString().padLeft(2, '0')}',
          name: 'Quán $index',
          description: '',
          address: '',
          category: 'Món Việt',
          latitude: 0,
          longitude: 0,
        ),
      );
      final repo = DemoPlaceRepository(data: data);
      final first = await repo.searchPlaces(PlaceSearchRequest());
      final second = await repo.searchPlaces(
        PlaceSearchRequest(),
        cursor: first.nextCursor,
      );
      expect(first.items, hasLength(20));
      expect(second.items, hasLength(5));
      expect(second.nextCursor, isNull);
      expect(first.totalCount, 25);
      expect({
        ...first.items.map((p) => p.id),
        ...second.items.map((p) => p.id),
      }, hasLength(25));
      expect(() => first.items.clear(), throwsUnsupportedError);
      await expectLater(
        repo.searchPlaces(PlaceSearchRequest(), pageSize: 0),
        throwsArgumentError,
      );
      await expectLater(
        repo.searchPlaces(PlaceSearchRequest(), cursor: '-2'),
        throwsA(isA<Exception>()),
      );
    },
  );

  test('Repeated category and amenity parameters round-trip and reject invalid numeric ranges', () {
    final request = PlaceSearchRequest(
      query: 'phở & bò',
      categories: {'Phở', 'Cà phê'},
      amenities: {'Mang về', 'Chuyển khoản / QR'},
      minRating: 4.5,
      minPrice: 10000,
      maxPrice: 100000,
      sort: PlaceSearchSort.price,
    );
    final uri = Uri.parse(
      AppRoute.search.location(query: request.queryParameters),
    );
    expect(PlaceSearchRequest.fromUri(uri), request);
    expect(request.hashCode, PlaceSearchRequest.fromUri(uri).hashCode);
    final invalid = PlaceSearchRequest.fromUri(
      Uri.parse('/search?rating=NaN&minPrice=99&maxPrice=20&sort=unknown'),
    );
    expect(invalid.minRating, isNull);
    expect(invalid.minPrice, isNull);
    expect(invalid.maxPrice, isNull);
    expect(invalid.sort, PlaceSearchSort.relevance);
    expect(
      request.copyWith(clearPrice: true, maxPrice: 49999).minPrice,
      isNull,
    );
    expect(request.copyWith(clearPrice: true, maxPrice: 49999).maxPrice, 49999);
  });

  ({
    ProviderContainer container,
    PlaceSearchController controller,
    SearchSeed seed,
  })
  setup(PlaceSearchRepository repo) {
    final container = ProviderContainer(
      overrides: [placeSearchRepositoryProvider.overrideWithValue(repo)],
    );
    final seed = (request: PlaceSearchRequest(), scope: 'test');
    addTearDown(container.dispose);
    final subscription = container.listen(
      searchControllerProvider(seed),
      (_, _) {},
    );
    addTearDown(subscription.close);
    return (
      container: container,
      controller: container.read(searchControllerProvider(seed).notifier),
      seed: seed,
    );
  }

  testWidgets(
    'Debounced typing batches calls and a late old response cannot replace new results',
    (tester) async {
      final old = Completer<PlaceSearchPage>(),
          latest = Completer<PlaceSearchPage>();
      final requests = <String>[];
      final setupState = setup(
        _SearchRepo((request, cursor) {
          requests.add(request.query);
          if (request.query == 'old') return old.future;
          if (request.query == 'latest') return latest.future;
          return Future.value(PlaceSearchPage(items: []));
        }),
      );
      await tester.pump();
      setupState.controller.setQuery('o');
      setupState.controller.setQuery('old');
      await tester.pump(const Duration(milliseconds: 299));
      expect(requests, ['']);
      await tester.pump(const Duration(milliseconds: 1));
      expect(requests, ['', 'old']);
      setupState.controller.submit('latest');
      latest.complete(PlaceSearchPage(items: [_b]));
      await tester.pump();
      old.complete(PlaceSearchPage(items: [_a]));
      await tester.pump();
      final state = setupState.container.read(
        searchControllerProvider(setupState.seed),
      );
      expect(state.items.single.id, 'b');
      expect(state.request.query, 'latest');
    },
  );

  testWidgets(
    'Pagination retains results after error, rejects duplicate requests and deduplicates retries',
    (tester) async {
      var pageCalls = 0;
      final failedPage = Completer<PlaceSearchPage>();
      final setupState = setup(
        _SearchRepo((request, cursor) {
          if (cursor == null) {
            return Future.value(
              PlaceSearchPage(items: [_a], nextCursor: 'next'),
            );
          }
          pageCalls++;
          return pageCalls == 1
              ? failedPage.future
              : Future.value(
                  PlaceSearchPage(items: [_a, _b], nextCursor: 'next'),
                );
        }),
      );
      await tester.pump();
      final pending = setupState.controller.loadMore();
      await setupState.controller.loadMore();
      expect(pageCalls, 1);
      failedPage.completeError(StateError('private backend detail'));
      await pending;
      var state = setupState.container.read(
        searchControllerProvider(setupState.seed),
      );
      expect(state.items.single.id, 'a');
      expect(state.pageError, 'Không tải được thêm quán. Vui lòng thử lại.');
      await setupState.controller.loadMore();
      state = setupState.container.read(
        searchControllerProvider(setupState.seed),
      );
      expect(state.items.map((place) => place.id), ['a', 'b']);
      expect(state.pageError, isNull);
      expect(state.nextCursor, isNull);
    },
  );

  testWidgets(
    'Late pagination is ignored after a query change and pending work is safe after disposal',
    (tester) async {
      final late = Completer<PlaceSearchPage>();
      final setupState = setup(
        _SearchRepo((request, cursor) {
          if (cursor != null) return late.future;
          return Future.value(
            PlaceSearchPage(
              items: request.query.isEmpty ? [_a] : [_b],
              nextCursor: request.query.isEmpty ? 'next' : null,
            ),
          );
        }),
      );
      await tester.pump();
      final pending = setupState.controller.loadMore();
      setupState.controller.submit('new');
      await tester.pump();
      late.complete(PlaceSearchPage(items: [_a]));
      await pending;
      expect(
        setupState.container
            .read(searchControllerProvider(setupState.seed))
            .items
            .single
            .id,
        'b',
      );
      setupState.controller.setQuery('disposed');
      setupState.container.dispose();
      await tester.pump(const Duration(milliseconds: 500));
      expect(tester.takeException(), isNull);
    },
  );

  test(
    'Recent queries are actual, bounded, accent-deduplicated and removable',
    () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final recent = container.read(recentSearchesProvider.notifier);
      recent.remember('Phở');
      recent.remember(' pho ');
      recent.remember('');
      expect(container.read(recentSearchesProvider), ['pho']);
      for (var i = 0; i < 7; i++) {
        recent.remember('quán $i');
      }
      expect(container.read(recentSearchesProvider), hasLength(5));
      recent.remove('quán 6');
      expect(container.read(recentSearchesProvider), isNot(contains('quán 6')));
      recent.clear();
      expect(container.read(recentSearchesProvider), isEmpty);
    },
  );
}

class _SearchRepo implements PlaceSearchRepository {
  _SearchRepo(this.run);
  final Future<PlaceSearchPage> Function(PlaceSearchRequest, String?) run;
  @override
  Future<PlaceSearchPage> searchPlaces(
    PlaceSearchRequest request, {
    String? cursor,
    int pageSize = 20,
  }) => run(request, cursor);
}
