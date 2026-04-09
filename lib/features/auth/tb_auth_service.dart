import 'package:dio/dio.dart';
import 'auth_response.dart';

/// Chịu trách nhiệm duy nhất: giao tiếp với ThingsBoard auth endpoints.
/// Không chứa logic lưu token hay state — việc đó thuộc về authProvider.
class TbAuthService {
  final Dio _dio;

  TbAuthService(this._dio);

  /// POST /api/auth/login
  /// ThingsBoard dùng field 'username', không phải 'email'
  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    try {
      final res = await _dio.post(
        '/api/auth/login',
        data: {'username': email, 'password': password},
      );
      return AuthResponse.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  /// POST /api/auth/token — dùng refreshToken để lấy access token mới
  Future<AuthResponse> refreshToken(String refreshToken) async {
    try {
      final res = await _dio.post(
        '/api/auth/token',
        data: {'refreshToken': refreshToken},
      );
      return AuthResponse.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  /// Chuyển DioException thành message tiếng Việt thân thiện
  Exception _mapDioError(DioException e) {
    final status = e.response?.statusCode;
    if (status == 401) {
      return Exception('Sai email hoặc mật khẩu');
    } else if (status == 429) {
      return Exception('Quá nhiều lần thử. Vui lòng đợi một lúc');
    } else if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return Exception('Không kết nối được server. Kiểm tra lại URL và mạng');
    } else if (e.type == DioExceptionType.unknown) {
      return Exception('Lỗi mạng. Kiểm tra kết nối internet');
    }
    return Exception('Lỗi không xác định (${status ?? 'unknown'})');
  }
}
