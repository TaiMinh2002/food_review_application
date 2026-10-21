import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_error_message.dart';
import '../../../core/errors/app_exception.dart';
import '../data/device_location_repository.dart';
import '../domain/place_map_repository.dart';

final userLocationRepositoryProvider = Provider<UserLocationRepository>(
  (ref) => DeviceLocationRepository(),
);

class UserLocationState {
  const UserLocationState({this.point, this.locating = false, this.error});

  final GeoPoint? point;
  final bool locating;
  final String? error;
}

final userLocationControllerProvider =
    NotifierProvider<UserLocationController, UserLocationState>(
      UserLocationController.new,
    );

/// One shared foreground fix for startup, Home and Map; no default coordinate.
class UserLocationController extends Notifier<UserLocationState> {
  bool _started = false;
  bool _returningFromSettings = false;

  @override
  UserLocationState build() => const UserLocationState();

  Future<void> initialize() async {
    if (_started) return;
    _started = true;
    await locate();
  }

  Future<GeoPoint?> locate() async {
    if (state.locating) return null;
    state = UserLocationState(point: state.point, locating: true);
    try {
      final point = await ref.read(userLocationRepositoryProvider).locate();
      if (!ref.mounted) return null;
      if (!point.isValid) {
        throw const AppException('Vị trí nhận được không hợp lệ.');
      }
      state = UserLocationState(point: point);
      return point;
    } catch (error) {
      if (ref.mounted) {
        state = UserLocationState(
          error: AppErrorMessage.from(
            error,
            fallback: 'Không thể lấy vị trí hiện tại. Vui lòng thử lại.',
          ),
        );
      }
      return null;
    }
  }

  Future<bool> openSettings() async {
    _returningFromSettings = true;
    final opened = await ref
        .read(userLocationRepositoryProvider)
        .openSettings();
    if (!opened) _returningFromSettings = false;
    return opened;
  }

  Future<void> resumeFromSettings() async {
    if (!_returningFromSettings) return;
    _returningFromSettings = false;
    await locate();
  }
}
