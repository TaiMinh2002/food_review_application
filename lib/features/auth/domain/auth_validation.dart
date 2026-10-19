abstract final class AuthValidation {
  static String? displayName(String? value) =>
      value?.trim().isNotEmpty == true ? null : 'Vui lòng nhập tên hiển thị.';

  static String? email(String? value) =>
      RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value?.trim() ?? '')
      ? null
      : 'Vui lòng nhập địa chỉ email hợp lệ.';
  // Login accepts existing passwords; creation rules belong to registration.
  static String? password(String? value) =>
      value == null || value.isEmpty ? 'Vui lòng nhập mật khẩu.' : null;

  static String? registrationPassword(String? value) {
    if (value == null || value.isEmpty) return 'Vui lòng nhập mật khẩu.';
    if (value.length < 8) return 'Mật khẩu cần ít nhất 8 ký tự.';
    return null;
  }

  static String? passwordConfirmation(String? value, String password) {
    if (value == null || value.isEmpty) return 'Vui lòng xác nhận mật khẩu.';
    if (value != password) return 'Mật khẩu xác nhận chưa khớp.';
    return null;
  }

  static String? terms(bool accepted) =>
      accepted ? null : 'Vui lòng đồng ý với điều khoản để tiếp tục.';
}
