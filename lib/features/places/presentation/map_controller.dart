import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_error_message.dart';
import '../../../core/errors/app_exception.dart';
import '../domain/place_map_repository.dart';
import '../domain/place_search.dart';
import 'place_providers.dart';
import 'user_location_controller.dart';

export 'user_location_controller.dart' show userLocationRepositoryProvider;

final placeMapRepositoryProvider = Provider<PlaceMapRepository?>((ref) {
  final source = ref.watch(placeRepositoryProvider);
  return source is PlaceMapRepository ? source as PlaceMapRepository : null;
});
// Override in deterministic tests; production always renders the native basemap.
final mapTilesEnabledProvider = Provider<bool>((ref) => true);

class PlaceMapState {
  PlaceMapState({
    PlaceSearchRequest? filters,
    this.result,
    this.loading = false,
    this.error,
    this.location,
    this.locating = false,
    this.locationError,
    this.nearby = false,
  }) : filters = filters ?? PlaceSearchRequest();
  final PlaceSearchRequest filters;
  final PlaceMapResult? result;
  final bool loading, locating, nearby;
  final String? error, locationError;
  final GeoPoint? location;

  PlaceMapState copyWith({
    PlaceSearchRequest? filters,
    PlaceMapResult? result,
    bool? loading,
    String? error,
    bool clearError = false,
    GeoPoint? location,
    bool? locating,
    String? locationError,
    bool clearLocationError = false,
    bool? nearby,
    bool clearLocation = false,
  }) => PlaceMapState(
    filters: filters ?? this.filters,
    result: result ?? this.result,
    loading: loading ?? this.loading,
    error: clearError ? null : error ?? this.error,
    location: clearLocation ? null : location ?? this.location,
    locating: locating ?? this.locating,
    locationError: clearLocationError
        ? null
        : locationError ?? this.locationError,
    nearby: nearby ?? this.nearby,
  );
}

final placeMapControllerProvider =
    NotifierProvider<PlaceMapController, PlaceMapState>(PlaceMapController.new);

class PlaceMapController extends Notifier<PlaceMapState> {
  MapViewport? _viewport;
  Timer? _debounce;
  int _generation = 0;

  @override
  PlaceMapState build() {
    ref.watch(placeMapRepositoryProvider);
    ref.listen(userLocationControllerProvider, (previous, next) {
      final wasNearby = state.nearby;
      state = state.copyWith(
        location: next.point,
        clearLocation: next.point == null,
        locating: next.locating,
        locationError: next.error,
        clearLocationError: next.error == null,
        nearby: next.point == null ? false : state.nearby,
      );
      if (previous?.point != next.point && wasNearby) {
        apply(state.filters);
      }
    });
    ref.onDispose(() {
      _debounce?.cancel();
      _generation++;
    });
    final location = ref.read(userLocationControllerProvider);
    return PlaceMapState(
      location: location.point,
      locating: location.locating,
      locationError: location.error,
    );
  }

  void searchArea(MapViewport viewport) {
    _viewport = viewport;
    apply(state.filters);
  }

  void query(String query) =>
      apply(state.filters.copyWith(query: query), debounce: true);

  void apply(PlaceSearchRequest filters, {bool debounce = false}) {
    _debounce?.cancel();
    final generation = ++_generation;
    state = state.copyWith(filters: filters, loading: true, clearError: true);
    if (debounce) {
      _debounce = Timer(
        const Duration(milliseconds: 300),
        () => _load(generation),
      );
    } else {
      _load(generation);
    }
  }

  Future<void> _load(int generation) async {
    final viewport = _viewport;
    if (viewport == null) {
      state = state.copyWith(loading: false);
      return;
    }
    final filters = state.filters;
    final near = state.nearby ? state.location : null;
    try {
      final repository = ref.read(placeMapRepositoryProvider);
      if (repository == null) {
        throw const AppException(
          'Nguồn dữ liệu hiện tại chưa hỗ trợ tìm quán theo vùng bản đồ.',
        );
      }
      final result = await repository.findInViewport(
        viewport,
        filters: filters,
        near: near,
      );
      if (!ref.mounted || generation != _generation) return;
      state = state.copyWith(result: result, loading: false, clearError: true);
    } catch (error) {
      if (!ref.mounted || generation != _generation) return;
      state = state.copyWith(
        loading: false,
        error: AppErrorMessage.from(
          error,
          fallback: 'Không tải được quán trong vùng này.',
        ),
      );
    }
  }

  Future<GeoPoint?> locate() async {
    return ref.read(userLocationControllerProvider.notifier).locate();
  }

  void nearby(bool enabled) {
    if (enabled && state.location == null) return;
    state = state.copyWith(nearby: enabled);
    apply(state.filters);
  }

  void resetFilters() {
    state = state.copyWith(nearby: false);
    apply(PlaceSearchRequest());
  }
}
