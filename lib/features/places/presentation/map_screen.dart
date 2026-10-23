import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/errors/app_error_message.dart';
import '../../../core/router/app_route.dart';
import '../../../shared/design_system/design_system.dart';
import '../domain/place.dart';
import '../domain/place_map_repository.dart';
import '../domain/place_search.dart';
import 'map_controller.dart';
import 'discovery_center.dart';
import 'map_widgets.dart';
import 'place_providers.dart';
import 'user_location_controller.dart';
import 'user_location_status.dart';

class PlaceMapScreen extends ConsumerStatefulWidget {
  const PlaceMapScreen({super.key, this.restaurantId});
  final String? restaurantId;
  @override
  ConsumerState<PlaceMapScreen> createState() => _PlaceMapScreenState();
}

class _PlaceMapScreenState extends ConsumerState<PlaceMapScreen> {
  final _map = MapController();
  final _text = TextEditingController();
  final _canvasKey = GlobalKey();
  bool _ready = false, _moved = false, _hint = true;
  String? _selectedId, _focusError;
  Place? _focused;
  int _focusGeneration = 0;
  PlaceMapController get _controller =>
      ref.read(placeMapControllerProvider.notifier);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.restaurantId != null) _focus();
    });
  }

  @override
  void didUpdateWidget(covariant PlaceMapScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.restaurantId != widget.restaurantId) _focus();
  }

  @override
  void dispose() {
    _focusGeneration++;
    _map.dispose();
    _text.dispose();
    super.dispose();
  }

  Future<void> _focus() async {
    final generation = ++_focusGeneration;
    final id = widget.restaurantId;
    if (id == null) {
      setState(() {
        _focusError = null;
        _focused = null;
        _selectedId = null;
      });
      _searchArea();
      return;
    }
    setState(() {
      _focusError = null;
      _focused = null;
      _selectedId = null;
    });
    try {
      final place = id.startsWith('osm_')
          ? await ref.read(osmRegionPlaceRepositoryProvider).getById(id)
          : await ref.read(placeRepositoryProvider).getPlace(id);
      if (!mounted || generation != _focusGeneration) return;
      if (place == null || !GeoPoint(place.latitude, place.longitude).isValid) {
        setState(() => _focusError = 'Không tìm thấy vị trí quán này.');
      } else if (place.isDemo && ref.read(mapUsesOsmRegionProvider)) {
        setState(
          () => _focusError = 'Quán minh họa chưa có trên bản đồ dữ liệu thật.',
        );
      } else {
        setState(() {
          _focused = place;
          _selectedId = place.id;
        });
        if (_ready) {
          _map.move(
            LatLng(place.latitude, place.longitude),
            16,
            offset: const Offset(0, 40),
          );
        }
      }
      _searchArea();
    } catch (error) {
      if (!mounted || generation != _focusGeneration) return;
      setState(
        () => _focusError = AppErrorMessage.from(
          error,
          fallback: 'Không tải được vị trí quán.',
        ),
      );
      _searchArea();
    }
  }

  void _searchArea({bool selectCenter = false}) {
    if (!_ready) return;
    final bounds = _map.camera.visibleBounds;
    if (selectCenter) {
      final camera = _map.camera.center;
      ref
          .read(discoveryCenterProvider.notifier)
          .choose(GeoPoint(camera.latitude, camera.longitude));
    }
    _controller.searchArea(
      MapViewport(
        south: bounds.south,
        west: bounds.west,
        north: bounds.north,
        east: bounds.east,
      ),
    );
    setState(() => _moved = false);
  }

  Future<void> _locate({bool nearby = false}) async {
    final point = await _controller.locate();
    if (!mounted || point == null || !_ready) return;
    ref.read(discoveryCenterProvider.notifier).useDeviceLocation();
    _map.move(LatLng(point.latitude, point.longitude), 15);
    if (nearby) _controller.nearby(true);
    _searchArea();
  }

  void _choosePhungKhoang() {
    const center = phungKhoangCenter;
    ref.read(discoveryCenterProvider.notifier).choose(center);
    if (ref.read(placeMapControllerProvider).nearby) {
      _controller.nearby(false);
    }
    setState(() {
      _focused = null;
      _selectedId = null;
      _focusError = null;
    });
    if (_ready) {
      _map.move(LatLng(center.latitude, center.longitude), 15);
      _searchArea();
    }
  }

  void _apply(PlaceSearchRequest filters) {
    _focused = null;
    _selectedId = null;
    _controller.apply(filters);
  }

  Future<void> _filters() async {
    final result = await context.push<PlaceSearchRequest>(
      AppRoute.filters.location(
        query: ref.read(placeMapControllerProvider).filters.queryParameters,
      ),
    );
    if (!mounted || result == null) return;
    _text.text = result.query;
    _apply(result);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(discoveryCenterProvider, (previous, next) {
      if (widget.restaurantId != null || !_ready) return;
      final target = next ?? ref.read(userLocationControllerProvider).point;
      if (target == null) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_ready) return;
        final camera = _map.camera.center;
        if (GeoPoint(camera.latitude, camera.longitude).distanceTo(target) <
            10) {
          return;
        }
        _map.move(LatLng(target.latitude, target.longitude), 15);
        _searchArea();
      });
    });
    ref.listen(placeMapControllerProvider.select((value) => value.location), (
      previous,
      next,
    ) {
      if (next == null ||
          previous == next ||
          widget.restaurantId != null ||
          ref.read(discoveryCenterProvider) != null) {
        return;
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _ready) {
          _map.move(LatLng(next.latitude, next.longitude), 15);
          _searchArea();
        }
      });
    });
    final state = ref.watch(placeMapControllerProvider);
    final items = state.result?.places ?? <Place>[];
    final selected =
        items.where((place) => place.id == _selectedId).firstOrNull ??
        _focused ??
        (items.isEmpty
            ? null
            : items.reduce(
                (a, b) => a.averageRating >= b.averageRating ? a : b,
              ));
    final markers = [
      ...items,
      if (_focused != null && !items.any((place) => place.id == _focused!.id))
        _focused!,
    ];
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 64,
        titleSpacing: AppSpacing.margin,
        title: Row(
          children: [
            Icon(Icons.restaurant, color: context.colors.primary),
            const SizedBox(width: 8),
            const Text('Bản đồ'),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Cá nhân',
            icon: const Icon(Icons.account_circle),
            onPressed: () => context.go(AppRoute.profile.path),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final scroll =
                constraints.maxHeight < 600 ||
                constraints.maxWidth < 370 ||
                _focusError != null ||
                state.error != null ||
                state.locationError != null ||
                MediaQuery.textScalerOf(context).scale(14) > 19;
            final map = _mapArea(state, markers, selected);
            final bottom = _bottom(state, selected);
            if (scroll) {
              return SingleChildScrollView(
                key: const PageStorageKey('map-scroll'),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                child: Column(
                  children: [
                    _header(state),
                    SizedBox(height: 330, child: map),
                    bottom,
                  ],
                ),
              );
            }
            return Column(
              children: [
                _header(state),
                Expanded(child: map),
                bottom,
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _header(PlaceMapState state) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(
              Icons.near_me_outlined,
              size: 18,
              color: context.colors.secondary,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                state.nearby
                    ? 'Trong 1 km quanh vị trí của bạn'
                    : 'Quán trong 5 km quanh tâm bản đồ',
                style: context.textStyles.labelMedium,
              ),
            ),
            IconButton(
              tooltip: 'Thông tin bản đồ',
              icon: const Icon(Icons.layers_outlined),
              onPressed: () => showAppBottomSheet<void>(
                context,
                title: 'Bản đồ đường phố',
                builder: (_) => const Text(
                  'Nền bản đồ OpenFreeMap, dữ liệu OpenStreetMap và OpenMapTiles, hiển thị bằng MapLibre. Kéo hoặc zoom, rồi bấm Tìm vùng này.',
                ),
              ),
            ),
          ],
        ),
        AppSearchField(
          controller: _text,
          hintText: ref.watch(mapUsesOsmRegionProvider)
              ? 'Tìm tên quán trong vùng...'
              : 'Tìm quán ăn, món ngon...',
          onChanged: (query) {
            _focused = null;
            _selectedId = null;
            _controller.query(query);
          },
          onSubmitted: (_) {
            FocusScope.of(context).unfocus();
            _searchArea();
          },
          filterCount: state.filters.activeFilterCount,
          onFilter: ref.watch(mapUsesOsmRegionProvider) ? null : _filters,
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              AppChip(
                label: 'Gần tôi (< 1km)',
                icon: Icons.near_me,
                selected: state.nearby,
                onSelected: state.locating
                    ? null
                    : (value) {
                        if (!value) {
                          _controller.nearby(false);
                        } else {
                          _locate(nearby: true);
                        }
                      },
              ),
              const SizedBox(width: 6),
              const Tooltip(
                message: 'Chưa có dữ liệu giờ mở cửa đáng tin cậy',
                child: AppChip(label: 'Đang mở cửa', icon: Icons.schedule),
              ),
              if (!ref.watch(mapUsesOsmRegionProvider)) ...[
                const SizedBox(width: 6),
                AppChip(
                  label: 'Đánh giá từ 4.5',
                  icon: Icons.star,
                  selected: state.filters.minRating == 4.5,
                  onSelected: (value) => _apply(
                    state.filters.copyWith(minRating: 4.5, clearRating: !value),
                  ),
                ),
                const SizedBox(width: 6),
                AppChip(
                  label: 'Dưới 50.000đ',
                  icon: Icons.payments_outlined,
                  selected: state.filters.maxPrice == 49999,
                  onSelected: (value) => _apply(
                    state.filters.copyWith(
                      clearPrice: true,
                      maxPrice: value ? 49999 : null,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                AppChip(
                  label: 'Phở & Bún',
                  icon: Icons.ramen_dining,
                  selected: state.filters.categories.containsAll({
                    'Phở',
                    'Bún',
                  }),
                  onSelected: (value) => _apply(
                    state.filters.copyWith(
                      categories: value
                          ? {...state.filters.categories, 'Phở', 'Bún'}
                          : ({...state.filters.categories}
                              ..removeAll({'Phở', 'Bún'})),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    ),
  );

  Widget _mapArea(PlaceMapState state, List<Place> markers, Place? selected) {
    // Keep a map the user has already opened usable after GPS denial or panning.
    // This is the current camera viewport, never a fallback user coordinate.
    final camera = _ready ? _map.camera.center : null;
    final point = _focused == null
        ? ref.watch(discoveryCenterProvider) ??
              state.location ??
              (camera == null
                  ? null
                  : GeoPoint(camera.latitude, camera.longitude))
        : GeoPoint(_focused!.latitude, _focused!.longitude);
    if (point == null) {
      _ready = false;
      return Center(
        child: SingleChildScrollView(
          padding: AppSpacing.page,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Bản đồ quanh bạn', style: context.textStyles.titleLarge),
              const SizedBox(height: AppSpacing.sm),
              const Text(
                'Dùng vị trí thiết bị hoặc chọn khu vực thử nghiệm để xem bản đồ.',
              ),
              const SizedBox(height: AppSpacing.sm),
              TextButton(
                onPressed: _choosePhungKhoang,
                child: const Text('Xem quán quanh Chợ Phùng Khoang'),
              ),
              const SizedBox(height: AppSpacing.sm),
              const UserLocationStatus(),
            ],
          ),
        ),
      );
    }
    return Stack(
      children: [
        Positioned.fill(
          child: PlaceMapCanvas(
            key: _canvasKey,
            controller: _map,
            center: LatLng(point.latitude, point.longitude),
            places: markers,
            selectedId: selected?.id,
            location: state.location,
            tilesEnabled: ref.watch(mapTilesEnabledProvider),
            onReady: () {
              _ready = true;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                final focused = _focused;
                if (focused != null) {
                  _map.move(
                    LatLng(focused.latitude, focused.longitude),
                    16,
                    offset: const Offset(0, 40),
                  );
                }
                _searchArea();
              });
            },
            onMoved: () {
              if (_ready && mounted && !_moved) setState(() => _moved = true);
            },
            onSelect: (place) {
              setState(() {
                _selectedId = place.id;
                _focused = null;
              });
              _map.move(
                LatLng(place.latitude, place.longitude),
                _map.camera.zoom,
                offset: const Offset(0, 40),
              );
            },
          ),
        ),
        Positioned(
          top: 8,
          left: 12,
          right: 64,
          child: Align(
            alignment: Alignment.topLeft,
            child: Material(
              color: context.colors.surface,
              borderRadius: BorderRadius.circular(24),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                child: Text(
                  state.loading
                      ? 'Đang tìm quán…'
                      : '${state.result?.places.length ?? 0}${state.result?.hasMore == true ? "+" : ""} quán trong vùng đã tìm',
                  style: context.textStyles.labelSmall,
                ),
              ),
            ),
          ),
        ),
        if (_moved)
          Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.only(top: 48),
              child: FilledButton.tonalIcon(
                onPressed: () => _searchArea(selectCenter: true),
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Tìm vùng này'),
              ),
            ),
          ),
        Positioned(
          right: 12,
          bottom: 100,
          child: Material(
            color: context.colors.surface,
            borderRadius: AppRadii.inputBorder,
            elevation: 2,
            child: Column(
              children: [
                IconButton(
                  tooltip: 'Phóng to bản đồ',
                  icon: const Icon(Icons.add),
                  onPressed: () => _zoom(1),
                ),
                IconButton(
                  tooltip: 'Thu nhỏ bản đồ',
                  icon: const Icon(Icons.remove),
                  onPressed: () => _zoom(-1),
                ),
                IconButton(
                  tooltip: 'Vị trí của tôi',
                  onPressed: state.locating ? null : _locate,
                  icon: state.locating
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.my_location),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _zoom(double delta) {
    if (_ready) {
      _map.move(_map.camera.center, (_map.camera.zoom + delta).clamp(3, 18));
    }
  }

  Widget _bottom(PlaceMapState state, Place? selected) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 680),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_focusError != null) _notice(_focusError!, 'Thử lại', _focus),
            if (state.locationError != null && _ready)
              _notice(state.locationError!, 'Cài đặt', () async {
                final opened = await ref
                    .read(userLocationControllerProvider.notifier)
                    .openSettings();
                if (mounted && !opened) {
                  AppToast.show(
                    context,
                    'Vui lòng mở Cài đặt thiết bị để cấp quyền vị trí.',
                  );
                }
              }),
            if (state.error != null)
              _notice(
                state.error!,
                state.error!.contains('chưa có dữ liệu')
                    ? 'Xem Chợ Phùng Khoang'
                    : 'Thử lại',
                state.error!.contains('chưa có dữ liệu')
                    ? _choosePhungKhoang
                    : _searchArea,
              )
            else if (!state.loading && selected == null && _ready)
              _notice(
                'Không có quán phù hợp trong vùng đã tìm.',
                'Đặt lại lọc',
                () {
                  _text.clear();
                  _focused = null;
                  _selectedId = null;
                  _controller.resetFilters();
                },
              ),
            if (_hint)
              Row(
                children: [
                  Icon(
                    Icons.tips_and_updates_outlined,
                    size: 18,
                    color: context.colors.secondary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Chọn marker để xem quán và mở chỉ đường.',
                      style: context.textStyles.labelSmall,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Đóng gợi ý',
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => setState(() => _hint = false),
                  ),
                ],
              ),
            if (selected != null)
              MapPlacePreview(place: selected, location: state.location),
            if (state.result != null && ref.watch(mapUsesOsmRegionProvider))
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'OSM Hà Nội · dữ liệu ${ref.watch(osmDataDateProvider).value?.toIso8601String().split('T').first ?? 'đang tải'} · bán kính 5 km quanh tâm bản đồ',
                  style: context.textStyles.labelSmall,
                ),
              ),
            if (state.result?.isDemo == true)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Quán, tọa độ, giá và đánh giá minh họa · TP.HCM',
                  style: context.textStyles.labelSmall,
                ),
              ),
          ],
        ),
      ),
    ),
  );

  Widget _notice(String text, String action, VoidCallback callback) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(text, style: context.textStyles.bodySmall),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(onPressed: callback, child: Text(action)),
        ),
      ],
    ),
  );
}
