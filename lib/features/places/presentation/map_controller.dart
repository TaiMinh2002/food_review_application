import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_error_message.dart';
import '../../../core/errors/app_exception.dart';
import '../data/device_location_repository.dart';
import '../domain/place_map_repository.dart';
import '../domain/place_search.dart';
import 'place_providers.dart';

final placeMapRepositoryProvider = Provider<PlaceMapRepository?>((ref) {
  final source = ref.watch(placeRepositoryProvider);
  return source is PlaceMapRepository ? source as PlaceMapRepository : null;
});
final userLocationRepositoryProvider = Provider<UserLocationRepository>(
  (ref) => DeviceLocationRepository(),
);
// Override in deterministic tests; production always renders online tiles.
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
  }) => PlaceMapState(
    filters: filters ?? this.filters,
    result: result ?? this.result,
    loading: loading ?? this.loading,
    error: clearError ? null : error ?? this.error,
    location: location ?? this.location,
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
  int _locationGeneration = 0;

  @override
  PlaceMapState build() {
    ref.watch(placeMapRepositoryProvider);
    ref.onDispose(() {
      _debounce?.cancel();
      _generation++;
      _locationGeneration++;
    });
    return PlaceMapState();
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
    if (state.locating) return null;
    final generation = ++_locationGeneration;
    state = state.copyWith(locating: true, clearLocationError: true);
    try {
      final location = await ref.read(userLocationRepositoryProvider).locate();
      if (!ref.mounted || generation != _locationGeneration) return null;
      state = state.copyWith(
        locating: false,
        location: location,
        clearLocationError: true,
      );
      return location;
    } catch (error) {
      if (ref.mounted && generation == _locationGeneration) {
        state = state.copyWith(
          locating: false,
          locationError: AppErrorMessage.from(
            error,
            fallback: 'Không thể lấy vị trí hiện tại.',
          ),
        );
      }
      return null;
    }
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
