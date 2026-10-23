import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/place_map_repository.dart';
import 'user_location_controller.dart';

/// Explicit map or Home selection shared by the discovery surfaces.
/// A GPS fix is used only when the user has not selected another center.
final discoveryCenterProvider = NotifierProvider<DiscoveryCenter, GeoPoint?>(
  DiscoveryCenter.new,
);

final activeDiscoveryCenterProvider = Provider<GeoPoint?>((ref) {
  return ref.watch(discoveryCenterProvider) ??
      ref.watch(userLocationControllerProvider).point;
});

class DiscoveryCenter extends Notifier<GeoPoint?> {
  @override
  GeoPoint? build() => null;

  void choose(GeoPoint point) {
    if (!point.isValid) throw ArgumentError.value(point, 'point');
    if (state?.latitude == point.latitude &&
        state?.longitude == point.longitude) {
      return;
    }
    state = point;
  }

  void useDeviceLocation() => state = null;
}

const phungKhoangCenter = GeoPoint(20.9859, 105.7938);
