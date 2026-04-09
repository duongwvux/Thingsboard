import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/app_constants.dart';
import '../../core/dio_client.dart';
import 'auth_state.dart';
import 'tb_auth_service.dart';

// ---------------------------------------------------------------------------
// Providers phụ trợ
// ---------------------------------------------------------------------------

final secureStorageProvider = Provider<FlutterSecureStorage>(
  (_) => const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  ),
);

final tbAuthServiceProvider = Provider<TbAuthService>((ref) {
  return TbAuthService(ref.read(dioClientProvider).dio);
});

// ---------------------------------------------------------------------------
// authProvider — điểm duy nhất quản lý trạng thái đăng nhập
// ---------------------------------------------------------------------------
//
// Dùng AsyncNotifier để:
//   - build() tự chạy khi app khởi động → thử restore session
//   - state tự xử lý loading/error/data mà không cần set thủ công
//   - UI dùng .when(loading, error, data) mà không cần if-else

final authProvider =
    AsyncNotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);

class AuthNotifier extends AsyncNotifier<AuthState> {
  // ---------------------------------------------------------------------------
  // build — chạy 1 lần khi app start, thử đọc token đã lưu
  // ---------------------------------------------------------------------------
  @override
  Future<AuthState> build() async {
    return _tryRestoreSession();
  }

  // ---------------------------------------------------------------------------
  // login
  // ---------------------------------------------------------------------------
  Future<void> login({
    required String email,
    required String password,
  }) async {
    // Bật loading — LoginScreen tự hiện CircularProgressIndicator
    state = const AsyncLoading();

    // AsyncValue.guard bắt exception và chuyển thành AsyncError tự động
    state = await AsyncValue.guard(() async {
      final authService = ref.read(tbAuthServiceProvider);
      final storage     = ref.read(secureStorageProvider);
      final dioClient   = ref.read(dioClientProvider);

      // 1. Gọi ThingsBoard
      final response = await authService.login(
        email: email,
        password: password,
      );

      // 2. Lưu token an toàn
      await Future.wait([
        storage.write(key: AppConstants.keyJwtToken,     value: response.token),
        storage.write(key: AppConstants.keyRefreshToken, value: response.refreshToken),
        storage.write(key: AppConstants.keyUserId,       value: response.userId),
      ]);

      // 3. Gắn token vào Dio cho mọi request tiếp theo
      dioClient.setToken(response.token);

      return AuthAuthenticated(
        token:        response.token,
        refreshToken: response.refreshToken,
        userId:       response.userId,
      );
    });
  }

  // ---------------------------------------------------------------------------
  // logout
  // ---------------------------------------------------------------------------
  Future<void> logout() async {
    final storage   = ref.read(secureStorageProvider);
    final dioClient = ref.read(dioClientProvider);

    await storage.deleteAll();
    dioClient.clearToken();

    state = const AsyncData(AuthUnauthenticated());
  }

  // ---------------------------------------------------------------------------
  // _tryRestoreSession — đọc token đã lưu khi mở lại app
  // ---------------------------------------------------------------------------
  Future<AuthState> _tryRestoreSession() async {
    final storage = ref.read(secureStorageProvider);

    final token        = await storage.read(key: AppConstants.keyJwtToken);
    final refreshToken = await storage.read(key: AppConstants.keyRefreshToken);
    final userId       = await storage.read(key: AppConstants.keyUserId);

    // Chưa từng đăng nhập
    if (token == null || refreshToken == null) {
      return const AuthUnauthenticated();
    }

    // Có token → thử refresh để kiểm tra còn hợp lệ không
    try {
      final authService = ref.read(tbAuthServiceProvider);
      final dioClient   = ref.read(dioClientProvider);

      final newAuth = await authService.refreshToken(refreshToken);

      // Cập nhật token mới vào storage và Dio
      await storage.write(key: AppConstants.keyJwtToken, value: newAuth.token);
      dioClient.setToken(newAuth.token);

      return AuthAuthenticated(
        token:        newAuth.token,
        refreshToken: refreshToken,
        userId:       userId ?? newAuth.userId,
      );
    } catch (_) {
      // Token hết hạn hoặc không hợp lệ → xóa và yêu cầu đăng nhập lại
      await storage.deleteAll();
      return const AuthUnauthenticated();
    }
  }

  // ---------------------------------------------------------------------------
  // Getter tiện lợi cho các widget khác
  // ---------------------------------------------------------------------------

  AuthState? get _currentValue {
    AuthState? result;
    state.whenData((value) => result = value);
    return result;
  }

  /// Token hiện tại (null nếu chưa đăng nhập)
  String? get currentToken {
    final s = _currentValue;
    return s is AuthAuthenticated ? s.token : null;
  }

  bool get isAuthenticated => _currentValue is AuthAuthenticated;
}

