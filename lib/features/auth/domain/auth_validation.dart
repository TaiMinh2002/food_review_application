abstract final class AuthValidation {
  static String? email(String? value) =>
      RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value?.trim() ?? '')
      ? null
      : 'Vui lòng nhập địa chỉ email hợp lệ.';
  // Login accepts existing passwords; creation rules belong to registration.
  static String? password(String? value) =>
      value == null || value.isEmpty ? 'Vui lòng nhập mật khẩu.' : null;
}
