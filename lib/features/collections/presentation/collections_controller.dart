import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_error_message.dart';
import '../../../core/errors/app_exception.dart';
import '../../auth/presentation/auth_providers.dart';
import '../data/demo_collection_repository.dart';
import '../domain/collection_repository.dart';

final collectionRepositoryProvider = Provider<CollectionRepository>(
  (ref) => DemoCollectionRepository(),
);

class CollectionsState {
  const CollectionsState({
    this.items = const [],
    this.sort = CollectionSort.recent,
    this.total = 0,
    this.loading = true,
    this.loadingMore = false,
    this.refreshing = false,
    this.nextCursor,
    this.error,
    this.pageError,
    this.isDemo = false,
  });
  final List<PlaceCollection> items;
  final CollectionSort sort;
  final int total;
  final bool loading, loadingMore, refreshing, isDemo;
  final String? nextCursor, error, pageError;

  CollectionsState copyWith({
    List<PlaceCollection>? items,
    int? total,
    bool? loadingMore,
    bool? refreshing,
    String? nextCursor,
    bool clearCursor = false,
    String? error,
    String? pageError,
  }) => CollectionsState(
    items: items ?? this.items,
    sort: sort,
    total: total ?? this.total,
    loading: loading,
    loadingMore: loadingMore ?? this.loadingMore,
    refreshing: refreshing ?? this.refreshing,
    isDemo: isDemo,
    nextCursor: clearCursor ? null : nextCursor ?? this.nextCursor,
    error: error,
    pageError: pageError,
  );
}

final collectionsControllerProvider =
    NotifierProvider.autoDispose<CollectionsController, CollectionsState>(
      CollectionsController.new,
    );

class CollectionsController extends Notifier<CollectionsState> {
  int _generation = 0;
  String? _owner;
  late CollectionRepository _repository;

  @override
  CollectionsState build() {
    final session = ref.watch(authSessionProvider);
    _owner = session.isLoading || session.hasError
        ? null
        : session.asData?.value?.id;
    _repository = ref.watch(collectionRepositoryProvider);
    final generation = ++_generation;
    ref.onDispose(() => _generation++);
    if (_owner != null) {
      scheduleMicrotask(() {
        if (ref.mounted && generation == _generation) refresh();
      });
    }
    return const CollectionsState();
  }

  Future<void> applySort(CollectionSort sort) => _first(sort, retain: false);
  Future<void> refresh() => _first(state.sort, retain: true);

  Future<void> _first(CollectionSort sort, {required bool retain}) async {
    final owner = _owner;
    if (owner == null) return;
    final generation = ++_generation;
    final old = state;
    state = CollectionsState(
      items: retain ? old.items : const [],
      sort: sort,
      total: old.total,
      loading: !retain || old.items.isEmpty,
      refreshing: retain && old.items.isNotEmpty,
      isDemo: old.isDemo,
    );
    try {
      final page = await _repository.getCollections(ownerId: owner, sort: sort);
      if (!ref.mounted || generation != _generation) return;
      _validate(page, owner);
      state = CollectionsState(
        items: page.items,
        total: page.total,
        sort: sort,
        loading: false,
        nextCursor: page.nextCursor,
        isDemo: page.isDemo,
      );
    } catch (error) {
      if (!ref.mounted || generation != _generation) return;
      state = CollectionsState(
        items: retain ? old.items : const [],
        total: old.total,
        sort: sort,
        loading: false,
        isDemo: old.isDemo,
        error: AppErrorMessage.from(
          error,
          fallback: 'Không tải được bộ sưu tập. Vui lòng thử lại.',
        ),
      );
    }
  }

  Future<void> loadMore() async {
    final old = state;
    final owner = _owner;
    final cursor = old.nextCursor;
    if (owner == null ||
        cursor == null ||
        old.loading ||
        old.refreshing ||
        old.loadingMore) {
      return;
    }
    final generation = _generation;
    state = old.copyWith(loadingMore: true);
    try {
      final page = await _repository.getCollections(
        ownerId: owner,
        sort: old.sort,
        cursor: cursor,
      );
      if (!ref.mounted || generation != _generation) return;
      _validate(page, owner);
      if (page.items.any(
            (item) => old.items.any((existing) => existing.id == item.id),
          ) ||
          page.nextCursor == cursor ||
          page.total != old.total ||
          old.items.length + page.items.length > page.total) {
        throw const AppException('Danh sách đã thay đổi. Vui lòng tải lại.');
      }
      state = CollectionsState(
        items: List.unmodifiable([...old.items, ...page.items]),
        total: page.total,
        sort: old.sort,
        loading: false,
        nextCursor: page.nextCursor,
        isDemo: page.isDemo,
      );
    } catch (error) {
      if (!ref.mounted || generation != _generation) return;
      state = old.copyWith(
        loadingMore: false,
        pageError: AppErrorMessage.from(
          error,
          fallback: 'Không tải thêm được bộ sưu tập.',
        ),
      );
    }
  }

  void _validate(CollectionPage page, String owner) {
    if ((page.nextCursor != null &&
            (page.items.isEmpty || page.nextCursor!.isEmpty)) ||
        page.total < page.items.length ||
        page.items.length > 12 ||
        page.items.map((item) => item.id).toSet().length != page.items.length ||
        page.items.any(
          (item) =>
              item.ownerId != owner || item.id.isEmpty || item.placeCount < 0,
        )) {
      throw const AppException('Không đọc được dữ liệu bộ sưu tập của bạn.');
    }
  }

  Future<void> deleted(String id) async {
    ++_generation; // Discard requests made before the mutation.
    state = state.copyWith(
      items: state.items.where((item) => item.id != id).toList(),
      total: state.total > 0 ? state.total - 1 : 0,
      clearCursor: true,
    );
    await refresh();
  }
}

final collectionDeletionProvider =
    NotifierProvider.autoDispose<CollectionDeletion, AsyncValue<void>>(
      CollectionDeletion.new,
    );

class CollectionDeletion extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() {
    ref.watch(
      authSessionProvider.select((session) => session.asData?.value?.id),
    );
    return const AsyncData(null);
  }

  Future<bool> remove({
    required String ownerId,
    required String collectionId,
  }) async {
    final session = ref.read(authSessionProvider);
    if (state.isLoading ||
        session.isLoading ||
        session.hasError ||
        session.asData?.value?.id != ownerId) {
      return false;
    }
    final repository = ref.read(collectionRepositoryProvider);
    final reference = ref;
    state = const AsyncLoading();
    final result = await AsyncValue.guard(
      () => repository.deleteCollection(
        ownerId: ownerId,
        collectionId: collectionId,
      ),
    );
    if (!reference.mounted) return false;
    if (result.hasError) {
      state = result;
      return false;
    }
    await ref
        .read(collectionsControllerProvider.notifier)
        .deleted(collectionId);
    if (!reference.mounted) return false;
    state = result;
    return true;
  }
}
