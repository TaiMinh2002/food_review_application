import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/formatters/app_formatters.dart';
import '../../../core/router/app_route.dart';
import '../../../shared/design_system/design_system.dart';
import '../../favorites/presentation/favorite_providers.dart';
import '../domain/place.dart';
import '../domain/place_map_repository.dart';
import 'native_map_background.dart';

Future<void> openMapLink(BuildContext context, Uri uri) async {
  try {
    if (await launchUrl(uri, mode: LaunchMode.externalApplication)) return;
  } catch (_) {
    // Keep a safe, actionable message instead of exposing platform errors.
  }
  if (context.mounted) {
    AppToast.show(
      context,
      'Không mở được ứng dụng bản đồ. Vui lòng thử lại.',
      type: AppFeedbackType.error,
    );
  }
}

class PlaceMapCanvas extends StatefulWidget {
  const PlaceMapCanvas({
    super.key,
    required this.controller,
    required this.places,
    required this.selectedId,
    required this.onSelect,
    required this.onReady,
    required this.onMoved,
    required this.tilesEnabled,
    this.location,
    required this.center,
  });
  final MapController controller;
  final List<Place> places;
  final String? selectedId;
  final ValueChanged<Place> onSelect;
  final VoidCallback onReady, onMoved;
  final bool tilesEnabled;
  final GeoPoint? location;
  final LatLng center;

  @override
  State<PlaceMapCanvas> createState() => _PlaceMapCanvasState();
}

class _PlaceMapCanvasState extends State<PlaceMapCanvas> {
  bool _tileError = false;
  int _tileGeneration = 0;

  void _failed() {
    if (_tileError) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_tileError) setState(() => _tileError = true);
    });
  }

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      if (widget.tilesEnabled)
        Positioned.fill(
          child: NativeMapBackground(
            key: ValueKey(_tileGeneration),
            controller: widget.controller,
            center: widget.center,
            onError: _failed,
            onLoaded: () {
              if (mounted && _tileError) setState(() => _tileError = false);
            },
          ),
        ),
      FlutterMap(
        mapController: widget.controller,
        options: MapOptions(
          initialCenter: widget.center,
          initialZoom: 14,
          minZoom: 3,
          maxZoom: 18,
          backgroundColor: context.colors.surface.withValues(alpha: 0),
          interactionOptions: const InteractionOptions(
            flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
          ),
          onMapReady: widget.onReady,
          onPositionChanged: (_, _) => widget.onMoved(),
        ),
        children: [
          MarkerLayer(
            markers: [
              for (final place in widget.places)
                Marker(
                  point: LatLng(place.latitude, place.longitude),
                  width: place.id == widget.selectedId
                      ? 180
                      : 60 + MediaQuery.textScalerOf(context).scale(24),
                  height:
                      (place.id == widget.selectedId ? 90 : 44) +
                      MediaQuery.textScalerOf(context).scale(14),
                  alignment: Alignment.topCenter,
                  child: Semantics(
                    button: true,
                    selected: place.id == widget.selectedId,
                    label: 'Quán ${place.name}',
                    child: Tooltip(
                      message: place.name,
                      child: InkWell(
                        key: ValueKey('marker-${place.id}'),
                        onTap: () => widget.onSelect(place),
                        borderRadius: BorderRadius.circular(24),
                        child: _MapPin(
                          place: place,
                          selected: place.id == widget.selectedId,
                        ),
                      ),
                    ),
                  ),
                ),
              if (widget.location case final location?)
                Marker(
                  point: LatLng(location.latitude, location.longitude),
                  width: 44,
                  height: 44,
                  child: Tooltip(
                    message: 'Vị trí của bạn',
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: context.colors.primary.withValues(alpha: .2),
                      ),
                      child: Icon(
                        Icons.my_location,
                        color: context.colors.primary,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      if (_tileError)
        Positioned(
          left: 8,
          right: 70,
          bottom: 100,
          child: Material(
            color: context.colors.errorContainer,
            borderRadius: AppRadii.inputBorder,
            child: Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Không tải được nền bản đồ.',
                      style: context.textStyles.bodySmall?.copyWith(
                        color: context.colors.onErrorContainer,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => setState(() {
                      _tileError = false;
                      _tileGeneration++;
                    }),
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            ),
          ),
        ),
      Positioned(left: 0, right: 0, bottom: 0, child: const MapAttribution()),
    ],
  );
}

class MapAttribution extends StatelessWidget {
  const MapAttribution({super.key});

  @override
  Widget build(BuildContext context) => Material(
    color: context.colors.surface,
    child: Wrap(
      children: [
        for (final source in const {
          '© OpenStreetMap': 'https://www.openstreetmap.org/copyright',
          '© OpenMapTiles': 'https://openmaptiles.org/',
          'OpenFreeMap': 'https://openfreemap.org/',
        }.entries)
          TextButton(
            style: TextButton.styleFrom(
              minimumSize: const Size(44, 44),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              textStyle: context.textStyles.labelSmall,
            ),
            onPressed: () => openMapLink(context, Uri.parse(source.value)),
            child: Text(source.key),
          ),
      ],
    ),
  );
}

class _MapPin extends StatelessWidget {
  const _MapPin({required this.place, required this.selected});
  final Place place;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final background = selected
        ? context.colors.secondary
        : context.colors.primary;
    final foreground = selected
        ? context.colors.onSecondary
        : context.colors.onPrimary;
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (selected)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: context.colors.surface,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              place.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.textStyles.labelSmall,
            ),
          ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: context.colors.surface, width: 2),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                place.category == 'Cà phê'
                    ? Icons.local_cafe
                    : Icons.restaurant,
                size: selected ? 24 : 16,
                color: foreground,
              ),
              if (!selected && place.minPrice != null) ...[
                const SizedBox(width: 3),
                Text(
                  '${(place.minPrice! / 1000).round()}k',
                  style: context.textStyles.labelSmall?.copyWith(
                    color: foreground,
                  ),
                ),
              ],
            ],
          ),
        ),
        Icon(Icons.arrow_drop_down, color: background, size: 18),
      ],
    );
  }
}

class MapPlacePreview extends ConsumerWidget {
  const MapPlacePreview({super.key, required this.place, this.location});
  final Place place;
  final GeoPoint? location;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final osmOnly = place.id.startsWith('osm_') && !place.isDemo;
    final favorite =
        !osmOnly && ref.watch(favoriteIdsProvider).contains(place.id);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: AppRadii.inputBorder,
                  child: SizedBox(
                    width: 88,
                    height: 96,
                    child: AppImage(url: place.imageUrls.firstOrNull),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              place.category,
                              style: context.textStyles.labelSmall,
                            ),
                          ),
                          if (!osmOnly)
                            IconButton(
                              tooltip: favorite ? 'Bỏ lưu quán' : 'Lưu quán',
                              visualDensity: VisualDensity.compact,
                              onPressed: () => ref
                                  .read(favoriteIdsProvider.notifier)
                                  .toggle(place.id),
                              icon: Icon(
                                favorite
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color: context.colors.secondary,
                              ),
                            ),
                        ],
                      ),
                      Text(place.name, style: context.textStyles.titleMedium),
                      if (place.reviewCount > 0)
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            AppRating(value: place.averageRating),
                            Text(
                              '(${place.reviewCount})',
                              style: context.textStyles.labelSmall,
                            ),
                          ],
                        )
                      else
                        Text(
                          'Chưa có đánh giá trong ứng dụng',
                          style: context.textStyles.labelSmall,
                        ),
                      if (place.address.isNotEmpty)
                        Text(
                          place.address,
                          style: context.textStyles.labelSmall,
                        ),
                      if (place.minPrice != null && place.maxPrice != null)
                        Text(
                          AppFormatters.priceRange(
                            place.minPrice!,
                            place.maxPrice!,
                          ),
                          style: context.textStyles.labelSmall,
                        ),
                      if (location case final point?)
                        Text(
                          'Cách khoảng ${AppFormatters.distance(point.distanceTo(GeoPoint(place.latitude, place.longitude)))} · đường chim bay',
                          style: context.textStyles.labelSmall,
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final buttons = [
                  AppButton(
                    label: 'Chỉ đường',
                    icon: Icons.turn_right,
                    variant: AppButtonVariant.secondary,
                    onPressed: () =>
                        openMapLink(context, walkingDirections(place)),
                  ),
                  if (!osmOnly)
                    AppButton(
                      label: 'Xem chi tiết',
                      icon: Icons.arrow_forward,
                      onPressed: () => context.push(
                        AppRoute.restaurant.location(
                          parameters: {'restaurantId': place.id},
                        ),
                      ),
                    ),
                ];
                if (buttons.length == 1) return buttons.single;
                return constraints.maxWidth < 300 ||
                        MediaQuery.textScalerOf(context).scale(14) > 19
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          buttons[0],
                          const SizedBox(height: 8),
                          buttons[1],
                        ],
                      )
                    : Row(
                        children: [
                          Expanded(child: buttons[0]),
                          const SizedBox(width: 8),
                          Expanded(child: buttons[1]),
                        ],
                      );
              },
            ),
          ],
        ),
      ),
    );
  }
}
