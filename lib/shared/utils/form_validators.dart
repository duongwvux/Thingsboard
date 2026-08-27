abstract final class FormValidators {
  static String? requiredText(String? value, {String message = 'Bắt buộc'}) {
    if (value == null || value.trim().isEmpty) return message;
    return null;
  }

  static String? serverUrl(String? value) {
    if (value == null || value.trim().isEmpty) return 'Nhập URL server';
    final uri = Uri.tryParse(value.trim());
    if (uri == null || !uri.hasScheme) {
      return 'URL không hợp lệ (cần https://)';
    }
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return 'Nhập email';
    final emailRegex = RegExp(r'^[\w.-]+@[\w.-]+\.\w+$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Email không đúng định dạng';
    }
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Nhập mật khẩu';
    if (value.length < 6) return 'Mật khẩu ít nhất 6 ký tự';
    return null;
  }
}
