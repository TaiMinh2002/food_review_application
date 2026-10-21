import 'dart:async';

import 'package:geolocator/geolocator.dart';

import '../../../core/errors/app_exception.dart';
import '../domain/place_map_repository.dart';

class DeviceLocationRepository implements UserLocationRepository {
  @override
  Future<GeoPoint> locate() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw const AppException(
          'Dịch vụ vị trí đang tắt. Vui lòng bật vị trí trong Cài đặt thiết bị.',
        );
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        throw const AppException(
          'Quyền vị trí đã bị chặn. Bạn có thể mở Cài đặt để cấp lại quyền.',
        );
      }
      if (permission != LocationPermission.always &&
          permission != LocationPermission.whileInUse) {
        throw const AppException(
          'Chưa có quyền vị trí. Bạn vẫn có thể xem và tìm kiếm quán.',
        );
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      final point = GeoPoint(position.latitude, position.longitude);
      if (!point.isValid) {
        throw const AppException('Vị trí nhận được không hợp lệ.');
      }
      return point;
    } on AppException {
      rethrow;
    } on TimeoutException {
      throw const AppException(
        'Chưa lấy được vị trí. Vui lòng thử lại ở nơi có tín hiệu tốt hơn.',
      );
    } catch (_) {
      throw const AppException(
        'Không thể lấy vị trí. Bạn vẫn có thể xem và tìm kiếm quán.',
      );
    }
  }

  @override
  Future<bool> openSettings() async {
    try {
      return await Geolocator.isLocationServiceEnabled()
          ? await Geolocator.openAppSettings()
          : await Geolocator.openLocationSettings();
    } catch (_) {
      return false;
    }
  }
}
