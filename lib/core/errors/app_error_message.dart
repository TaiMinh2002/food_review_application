import 'app_exception.dart';

/// Only expose deliberately user-facing failures; never SDK diagnostics.
abstract final class AppErrorMessage {
  static String from(
    Object error, {
    String fallback = 'Đã xảy ra lỗi. Vui lòng thử lại.',
  }) {
    if (error is AppException) {
      return switch (error.code) {
        'network' ||
        'network-request-failed' ||
        'unavailable' => 'Không có kết nối mạng. Vui lòng thử lại.',
        'unauthenticated' ||
        'requires-recent-login' => 'Vui lòng đăng nhập để tiếp tục.',
        'permission-denied' => 'Bạn không có quyền thực hiện thao tác này.',
        'not-found' => 'Không tìm thấy nội dung này.',
        _ => error.message,
      };
    }
    return fallback;
  }
}
