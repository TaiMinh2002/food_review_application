import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:maplibre_gl/maplibre_gl.dart' as native;

import '../../../core/config/app_config.dart';
import '../../../shared/design_system/design_system.dart';

/// Native vector basemap. FlutterMap remains the single camera/gesture and
/// marker layer, so filters, viewport queries and selection share one camera.
class NativeMapBackground extends StatefulWidget {
  const NativeMapBackground({
    super.key,
    required this.controller,
    required this.center,
    required this.onError,
    required this.onLoaded,
  });

  final MapController controller;
  final LatLng center;
  final VoidCallback onError, onLoaded;

  @override
  State<NativeMapBackground> createState() => _NativeMapBackgroundState();
}

class _NativeMapBackgroundState extends State<NativeMapBackground> {
  native.MapLibreMapController? _native;
  StreamSubscription<MapEvent>? _subscription;
  Timer? _timeout;
  MapCamera? _camera;
  bool _moving = false, _loading = true;
  String? _style;

  @override
  void initState() {
    super.initState();
    try {
      // Retry can recreate only the basemap while the gesture camera survives.
      _camera = widget.controller.camera;
    } catch (_) {
      // The first build precedes FlutterMap attaching its camera.
    }
    _subscription = widget.controller.mapEventStream.listen((event) {
      _camera = event.camera;
      _syncCamera();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final style = Theme.of(context).brightness == Brightness.dark
        ? AppConfig.mapDarkStyleUrl
        : AppConfig.mapStyleUrl;
    if (_style == style) return;
    _style = style;
    _loading = true;
    _timeout?.cancel();
    _timeout = Timer(const Duration(seconds: 25), () {
      if (mounted && _loading) _failed();
    });
  }

  Future<void> _syncCamera() async {
    if (_moving || _native == null || _camera == null) return;
    _moving = true;
    try {
      // Coalesce gesture events while a native camera update is in flight.
      MapCamera? applied;
      while (mounted && _native != null && !identical(applied, _camera)) {
        applied = _camera;
        if (applied == null) break;
        await _native!.moveCamera(
          native.CameraUpdate.newCameraPosition(
            native.CameraPosition(
              target: native.LatLng(
                applied.center.latitude,
                applied.center.longitude,
              ),
              // FlutterMap uses a 256px world; MapLibre uses a 512px world.
              zoom: applied.zoom - 1,
            ),
          ),
        );
      }
    } catch (_) {
      if (mounted) _failed();
    } finally {
      _moving = false;
    }
  }

  void _loaded() {
    if (!mounted) return;
    _timeout?.cancel();
    if (_loading) setState(() => _loading = false);
    widget.onLoaded();
  }

  void _failed() {
    _timeout?.cancel();
    if (_loading) setState(() => _loading = false);
    widget.onError();
  }

  @override
  void dispose() {
    _timeout?.cancel();
    _subscription?.cancel();
    // MapLibreMap owns and disposes its platform controller.
    _native = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: Stack(
      fit: StackFit.expand,
      children: [
        native.MapLibreMap(
          styleString: _style!,
          initialCameraPosition: native.CameraPosition(
            target: native.LatLng(
              _camera?.center.latitude ?? widget.center.latitude,
              _camera?.center.longitude ?? widget.center.longitude,
            ),
            zoom: (_camera?.zoom ?? 14) - 1,
          ),
          minMaxZoomPreference: const native.MinMaxZoomPreference(2, 17),
          rotateGesturesEnabled: false,
          tiltGesturesEnabled: false,
          scrollGesturesEnabled: false,
          zoomGesturesEnabled: false,
          compassEnabled: false,
          attributionButtonPosition: null,
          // Location is supplied by the shared GPS controller, not another SDK.
          myLocationEnabled: false,
          onMapCreated: (controller) {
            _native = controller;
            _syncCamera();
          },
          onStyleLoadedCallback: _syncCamera,
          onMapIdle: _loaded,
        ),
        if (_loading)
          Center(
            child: Material(
              color: context.colors.surface,
              borderRadius: AppRadii.inputBorder,
              child: const Padding(
                padding: EdgeInsets.all(12),
                child: Text('Đang tải bản đồ…'),
              ),
            ),
          ),
      ],
    ),
  );
}
