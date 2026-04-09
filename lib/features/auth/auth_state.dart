sealed class AuthState {
  const AuthState();
}

/// Chưa đăng nhập (initial hoặc sau logout)
class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

/// Đã xác thực thành công
class AuthAuthenticated extends AuthState {
  final String token;
  final String refreshToken;
  final String userId;

  const AuthAuthenticated({
    required this.token,
    required this.refreshToken,
    required this.userId,
  });
}

/// Lỗi xác thực — giữ message để hiện trên UI
class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);
}
