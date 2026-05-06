import 'package:dio/dio.dart';
import 'dashboard_model.dart';
 
class TbDashboardService {
  final Dio _dio;
  TbDashboardService(this._dio);
 
  /// GET /api/tenant/dashboards?pageSize=50&page=0
  /// Lấy toàn bộ dashboard thuộc tenant đang đăng nhập
  Future<List<Dashboard>> getDashboards({int pageSize = 50}) async {
    try {
      final res = await _dio.get(
        '/api/tenant/dashboards',
        queryParameters: {'pageSize': pageSize, 'page': 0},
      );
      final data  = res.data as Map<String, dynamic>;
      final items = data['data'] as List<dynamic>? ?? [];
      return items
          .map((e) => Dashboard.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status == 401) throw Exception('Phiên đăng nhập hết hạn');
      if (status == 403) throw Exception('Không có quyền xem dashboard');
      throw Exception('Không tải được danh sách dashboard');
    }
  }
}