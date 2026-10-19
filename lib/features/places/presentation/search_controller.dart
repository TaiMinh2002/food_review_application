import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_error_message.dart';
import '../../../core/errors/app_exception.dart';
import '../domain/place.dart';
import '../domain/place_search.dart';
import '../domain/place_search_repository.dart';
import 'place_providers.dart';

typedef SearchSeed = ({PlaceSearchRequest request, String scope});

final placeSearchRepositoryProvider = Provider<PlaceSearchRepository?>((ref) {
  final repository = ref.watch(placeRepositoryProvider);
  return repository is PlaceSearchRepository
      ? repository as PlaceSearchRepository
      : null;
});

class PlaceSearchState {
  const PlaceSearchState({
    required this.request,
    this.items = const [],
    this.categories = const [],
    this.availableAmenities = const [],
    this.isLoading = true,
    this.isLoadingMore = false,
    this.error,
    this.pageError,
    this.nextCursor,
    this.totalCount,
    this.isDemo = false,
  });
  final PlaceSearchRequest request;
  final List<Place> items;
  final List<String> categories, availableAmenities;
  final bool isLoading, isLoadingMore, isDemo;
  final String? error, pageError, nextCursor;
  final int? totalCount;

  PlaceSearchState copyWith({
    List<Place>? items,
    bool? isLoadingMore,
    String? pageError,
    bool clearPageError = false,
    String? nextCursor,
    bool clearCursor = false,
  }) => PlaceSearchState(
    request: request,
    items: items ?? this.items,
    categories: categories,
    availableAmenities: availableAmenities,
    isLoading: isLoading,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    error: error,
    pageError: clearPageError ? null : pageError ?? this.pageError,
    nextCursor: clearCursor ? null : nextCursor ?? this.nextCursor,
    totalCount: totalCount,
    isDemo: isDemo,
  );
}

final searchControllerProvider = NotifierProvider.autoDispose
    .family<PlaceSearchController, PlaceSearchState, SearchSeed>(
      PlaceSearchController.new,
    );

class PlaceSearchController extends Notifier<PlaceSearchState> {
  PlaceSearchController(this.seed);
  final SearchSeed seed;
  Timer? _debounce;
  int _generation = 0;
  PlaceSearchRepository? _repository;

  @override
  PlaceSearchState build() {
    _repository = ref.watch(placeSearchRepositoryProvider);
    final generation = ++_generation;
    final reference = ref;
    final request = seed.request;
    ref.onDispose(() {
      _debounce?.cancel();
      _generation++;
    });
    scheduleMicrotask(() {
      if (reference.mounted && generation == _generation) {
        _first(request, generation);
      }
    });
    return PlaceSearchState(request: request);
  }

  void setQuery(String query) =>
      _start(state.request.copyWith(query: query), debounce: true);
  void toggleCategory(String category) {
    final categories = {...state.request.categories};
    if (!categories.remove(category)) {
      categories.add(category);
    }
    _start(state.request.copyWith(categories: categories));
  }

  void apply(PlaceSearchRequest request) => _start(request);
  void setSort(PlaceSearchSort sort) =>
      _start(state.request.copyWith(sort: sort));
  void reset() => _start(
    PlaceSearchRequest(
      sort: seed.request.categoryScope == null
          ? PlaceSearchSort.relevance
          : PlaceSearchSort.rating,
    ),
  );
  void retry() => _start(state.request);

  void submit(String query) {
    if (query != state.request.query ||
        _debounce?.isActive == true ||
        state.error != null) {
      _start(state.request.copyWith(query: query));
    }
  }

  void _start(PlaceSearchRequest request, {bool debounce = false}) {
    if (seed.request.categoryScope != null) {
      request = request.copyWith(categoryScope: seed.request.categoryScope);
    }
    _debounce?.cancel();
    final generation = ++_generation;
    state = PlaceSearchState(
      request: request,
      categories: state.categories,
      availableAmenities: state.availableAmenities,
      isDemo: state.isDemo,
    );
    if (debounce) {
      _debounce = Timer(
        const Duration(milliseconds: 300),
        () => _first(request, generation),
      );
    } else {
      _first(request, generation);
    }
  }

  Future<void> _first(PlaceSearchRequest request, int generation) async {
    final reference = ref;
    try {
      final repository = _repository;
      if (repository == null) {
        throw const AppException(
          'Tìm kiếm chưa khả dụng với nguồn dữ liệu hiện tại.',
        );
      }
      final page = await repository.searchPlaces(request);
      if (!reference.mounted || generation != _generation) return;
      state = PlaceSearchState(
        request: request,
        items: page.items,
        categories: page.categories,
        availableAmenities: page.amenities,
        isLoading: false,
        nextCursor: page.nextCursor,
        totalCount: page.totalCount,
        isDemo: page.isDemo,
      );
    } catch (error) {
      if (!reference.mounted || generation != _generation) return;
      state = PlaceSearchState(
        request: request,
        categories: state.categories,
        availableAmenities: state.availableAmenities,
        isLoading: false,
        error: AppErrorMessage.from(
          error,
          fallback: 'Không tải được kết quả tìm kiếm.',
        ),
        isDemo: state.isDemo,
      );
    }
  }

  Future<void> loadMore() async {
    final cursor = state.nextCursor;
    if (cursor == null || state.isLoading || state.isLoadingMore) return;
    final generation = _generation;
    final reference = ref;
    final request = state.request;
    state = state.copyWith(isLoadingMore: true, clearPageError: true);
    try {
      final repository = _repository;
      if (repository == null) {
        throw const AppException('Tìm kiếm chưa khả dụng.');
      }
      final page = await repository.searchPlaces(request, cursor: cursor);
      if (!reference.mounted || generation != _generation) return;
      final items = {for (final place in state.items) place.id: place};
      for (final place in page.items) {
        items.putIfAbsent(place.id, () => place);
      }
      state = state.copyWith(
        items: List.unmodifiable(items.values),
        isLoadingMore: false,
        nextCursor: page.nextCursor,
        clearCursor: page.nextCursor == null || page.nextCursor == cursor,
      );
    } catch (error) {
      if (!reference.mounted || generation != _generation) return;
      state = state.copyWith(
        isLoadingMore: false,
        pageError: AppErrorMessage.from(
          error,
          fallback: 'Không tải được thêm quán. Vui lòng thử lại.',
        ),
      );
    }
  }
}

final recentSearchesProvider = NotifierProvider<RecentSearches, List<String>>(
  RecentSearches.new,
);

/// Only actual submitted searches; no fixtures or persistent account history.
class RecentSearches extends Notifier<List<String>> {
  @override
  List<String> build() => const [];

  void remember(String query) {
    final value = query.trim();
    if (value.isEmpty) return;
    final normalized = normalizePlaceSearchText(value);
    state = List.unmodifiable(
      [
        value,
        ...state.where((item) => normalizePlaceSearchText(item) != normalized),
      ].take(5),
    );
  }

  void remove(String query) =>
      state = List.unmodifiable(state.where((item) => item != query));
  void clear() => state = const [];
}

final searchOptionsProvider = FutureProvider.autoDispose<PlaceSearchPage>((
  ref,
) {
  final repository = ref.watch(placeSearchRepositoryProvider);
  if (repository == null) {
    throw const AppException('Chưa tải được các lựa chọn tìm kiếm.');
  }
  return repository.searchPlaces(PlaceSearchRequest(), pageSize: 1);
}, retry: (count, error) => null);
