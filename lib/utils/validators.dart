/// Mirrors the rules in backend/src/lib/validation.ts so most mistakes are caught before a request.
abstract class Validators {
  static final RegExp _username = RegExp(r'^[a-zA-Z0-9_.]{3,30}$');

  static String? username(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Vui lòng nhập tên đăng nhập';
    if (!_username.hasMatch(text)) return '3-30 ký tự: chữ, số, dấu _ hoặc .';
    return null;
  }

  static String? password(String? value) {
    final text = value ?? '';
    if (text.isEmpty) return 'Vui lòng nhập mật khẩu';
    if (text.length < 6) return 'Mật khẩu tối thiểu 6 ký tự';
    return null;
  }

  static String? Function(String?) confirmPassword(String Function() password) {
    return (value) =>
        value == password() ? null : 'Mật khẩu xác nhận không khớp';
  }

  static String? displayName(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Vui lòng nhập tên hiển thị';
    if (text.length > 50) return 'Tối đa 50 ký tự';
    return null;
  }
}
