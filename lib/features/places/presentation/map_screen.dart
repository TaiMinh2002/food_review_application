import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/errors/app_error_message.dart';
import '../../../shared/design_system/design_system.dart';
import '../domain/place.dart';
import '../domain/place_map_repository.dart';
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
  bool _ready = false, _moved = false;
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

  Future<void> _locate() async {
    final point = await _controller.locate();
    if (!mounted || point == null || !_ready) return;
    ref.read(discoveryCenterProvider.notifier).useDeviceLocation();
    _map.move(LatLng(point.latitude, point.longitude), 15);
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
        items.where((place) => place.id == _selectedId).firstOrNull ?? _focused;
    final markers = [
      ...items,
      if (_focused != null && !items.any((place) => place.id == _focused!.id))
        _focused!,
    ];
    return Scaffold(body: _buildBody(state, markers, selected));
  }

  Widget _buildBody(PlaceMapState state, List<Place> markers, Place? selected) {
    final camera = _ready ? _map.camera.center : null;
    final point = _focused == null
        ? ref.watch(discoveryCenterProvider) ??
              state.location ??
              (camera == null
                  ? null
                  : GeoPoint(camera.latitude, camera.longitude))
        : GeoPoint(_focused!.latitude, _focused!.longitude);
    if (point == null) {
      return _noLocationFallback();
    }
    return Stack(
      children: [
        // Full-screen map
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
                offset: const Offset(0, 100),
              );
            },
          ),
        ),
        // Search bar stacked on top
        _searchOverlay(state),
        // "Tìm vùng này" button when map moved
        if (_moved)
          Positioned(
            top: MediaQuery.paddingOf(context).top + 72,
            left: 0,
            right: 0,
            child: Center(
              child: FilledButton.tonalIcon(
                onPressed: () => _searchArea(selectCenter: true),
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Tìm vùng này'),
              ),
            ),
          ),
        // Map controls (zoom + locate) on right side
        Positioned(
          right: 12,
          bottom:
              (selected != null ? 220 : 24) +
              MediaQuery.paddingOf(context).bottom,
          child: _mapControls(state),
        ),
        // Error notices overlay
        if (_focusError != null || state.error != null)
          Positioned(
            left: 16,
            right: 16,
            bottom:
                (selected != null ? 220 : 24) +
                MediaQuery.paddingOf(context).bottom,
            child: _errorOverlay(state),
          ),
        // Place preview card stacked at bottom
        if (selected != null)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _placeBottomCard(selected, state.location),
          ),
      ],
    );
  }

  Widget _noLocationFallback() => SafeArea(
    child: Center(
      child: SingleChildScrollView(
        padding: AppSpacing.page,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.map_outlined, size: 64, color: context.colors.primary),
            const SizedBox(height: AppSpacing.md),
            Text('Bản đồ quanh bạn', style: context.textStyles.titleLarge),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Cho phép truy cập vị trí hoặc chọn khu vực để bắt đầu.',
              style: context.textStyles.bodyMedium?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              onPressed: _locate,
              icon: const Icon(Icons.my_location),
              label: const Text('Dùng vị trí của tôi'),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextButton(
              onPressed: _choosePhungKhoang,
              child: const Text('Xem quán quanh Chợ Phùng Khoang'),
            ),
            const SizedBox(height: AppSpacing.md),
            const UserLocationStatus(),
          ],
        ),
      ),
    ),
  );

  Widget _searchOverlay(PlaceMapState state) {
    final topPadding = MediaQuery.paddingOf(context).top;
    final canPop = ModalRoute.of(context)?.canPop ?? false;
    return Positioned(
      top: topPadding + 8,
      left: 12,
      right: 12,
      child: Column(
        children: [
          Row(
            children: [
              if (canPop) ...[
                Material(
                  elevation: 4,
                  shape: const CircleBorder(),
                  color: context.colors.surface,
                  surfaceTintColor: context.colors.surfaceTint,
                  child: const BackButton(),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Material(
                  elevation: 4,
                  borderRadius: BorderRadius.circular(28),
                  color: context.colors.surface,
                  surfaceTintColor: context.colors.surfaceTint,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: AppSearchField(
                      controller: _text,
                      hintText: 'Tìm quán ăn, món ngon...',
                      onChanged: (query) {
                        _focused = null;
                        _selectedId = null;
                        _controller.query(query);
                      },
                      onSubmitted: (_) {
                        FocusScope.of(context).unfocus();
                        _searchArea();
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Result count chip
          if (state.loading || state.result != null)
            Align(
              alignment: Alignment.centerLeft,
              child: Material(
                color: context.colors.surface.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(16),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  child: Text(
                    state.loading
                        ? 'Đang tìm quán…'
                        : '${state.result?.places.length ?? 0}${state.result?.hasMore == true ? "+" : ""} quán',
                    style: context.textStyles.labelSmall,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _mapControls(PlaceMapState state) => Material(
    color: context.colors.surface,
    borderRadius: AppRadii.inputBorder,
    elevation: 4,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Phóng to bản đồ',
          icon: const Icon(Icons.add),
          onPressed: () => _zoom(1),
        ),
        const Divider(height: 1, indent: 8, endIndent: 8),
        IconButton(
          tooltip: 'Thu nhỏ bản đồ',
          icon: const Icon(Icons.remove),
          onPressed: () => _zoom(-1),
        ),
        const Divider(height: 1, indent: 8, endIndent: 8),
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
  );

  void _zoom(double delta) {
    if (_ready) {
      _map.move(_map.camera.center, (_map.camera.zoom + delta).clamp(3, 18));
    }
  }

  Widget _errorOverlay(PlaceMapState state) {
    final errors = <Widget>[];
    if (_focusError != null) {
      errors.add(_errorChip(_focusError!, 'Thử lại', _focus));
    }
    if (state.error != null) {
      errors.add(
        _errorChip(
          state.error!,
          state.error!.contains('chưa có dữ liệu')
              ? 'Xem Chợ Phùng Khoang'
              : 'Thử lại',
          state.error!.contains('chưa có dữ liệu')
              ? _choosePhungKhoang
              : _searchArea,
        ),
      );
    }
    return Column(mainAxisSize: MainAxisSize.min, children: errors);
  }

  Widget _errorChip(String text, String action, VoidCallback callback) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Material(
          color: context.colors.errorContainer,
          borderRadius: BorderRadius.circular(12),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.only(left: 12, right: 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    text,
                    style: context.textStyles.bodySmall?.copyWith(
                      color: context.colors.onErrorContainer,
                    ),
                  ),
                ),
                TextButton(onPressed: callback, child: Text(action)),
              ],
            ),
          ),
        ),
      );

  Widget _placeBottomCard(Place place, GeoPoint? location) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;
    return Container(
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: context.colors.shadow.withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, 12, 16, bottomPadding > 0 ? 4 : 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle and close button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 28),
                  Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: context.colors.onSurfaceVariant.withValues(
                        alpha: 0.3,
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    tooltip: 'Đóng',
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 28,
                      minHeight: 28,
                    ),
                    onPressed: () => setState(() {
                      _selectedId = null;
                      _focused = null;
                    }),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              MapPlacePreview(place: place, location: location),
            ],
          ),
        ),
      ),
    );
  }
}
