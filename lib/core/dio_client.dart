// core/dio_client.dart

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'app_constants.dart';

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final dioClientProvider = Provider<DioClient>((ref) {
  return DioClient(baseUrl: AppConstants.tbBaseUrl);
});

// ---------------------------------------------------------------------------
// DioClient
// ---------------------------------------------------------------------------

class DioClient {
  late final Dio dio;

  DioClient({required String baseUrl}) {
    dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      contentType: 'application/json',
    ));

    dio.interceptors.add(_JwtInterceptor(dio));
  }

  /// Gọi sau khi login thành công
  void setToken(String token) {
    dio.options.headers['X-Authorization'] = 'Bearer $token';
  }

  /// Gọi khi logout
  void clearToken() {
    dio.options.headers.remove('X-Authorization');
  }
}

// ---------------------------------------------------------------------------
// JWT Interceptor — tự động attach token và refresh khi 401
// ---------------------------------------------------------------------------

class _JwtInterceptor extends Interceptor {
  final Dio _dio;
  bool _isRefreshing = false;

  _JwtInterceptor(this._dio);

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // Chỉ xử lý 401 và không phải chính endpoint refresh
    final isRefreshEndpoint =
        err.requestOptions.path.contains('/api/auth/token');

    if (err.response?.statusCode != 401 || isRefreshEndpoint) {
      return handler.next(err);
    }

    // Tránh gọi refresh nhiều lần đồng thời
    if (_isRefreshing) return handler.next(err);
    _isRefreshing = true;

    try {
      const storage = FlutterSecureStorage();
      final refreshToken =
          await storage.read(key: AppConstants.keyRefreshToken);

      if (refreshToken == null) {
        // Không có refreshToken → buộc phải đăng nhập lại
        await storage.deleteAll();
        _isRefreshing = false;
        return handler.next(err);
      }

      // Gọi refresh — dùng Dio mới để tránh interceptor đệ quy
      final refreshDio = Dio(BaseOptions(baseUrl: _dio.options.baseUrl));
      final res = await refreshDio.post(
        '/api/auth/token',
        data: {'refreshToken': refreshToken},
      );

      final newToken = res.data['token'] as String;

      // Lưu token mới
      await storage.write(key: AppConstants.keyJwtToken, value: newToken);
      _dio.options.headers['X-Authorization'] = 'Bearer $newToken';

      // Retry request gốc với token mới
      final retryOptions = err.requestOptions;
      retryOptions.headers['X-Authorization'] = 'Bearer $newToken';
      final retryResponse = await _dio.fetch(retryOptions);

      _isRefreshing = false;
      return handler.resolve(retryResponse);
    } catch (_) {
      // Refresh thất bại — xóa hết token, UI sẽ redirect về login
      const storage = FlutterSecureStorage();
      await storage.deleteAll();
      _isRefreshing = false;
      return handler.next(err);
    }
  }
}
