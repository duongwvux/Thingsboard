import 'package:dio/dio.dart';
import 'device_model.dart';

class TbDeviceService {
  final Dio _dio;
  TbDeviceService(this._dio);

  /// GET /api/tenant/devices?pageSize=100&page=0
  /// Trả về tất cả thiết bị thuộc tenant đang đăng nhập
  Future<List<Device>> getDevices({int pageSize = 100}) async {
    try {
      final res = await _dio.get(
        '/api/tenant/devices',
        queryParameters: {'pageSize': pageSize, 'page': 0},
      );

      final data = res.data as Map<String, dynamic>;
      final items = data['data'] as List<dynamic>? ?? [];

      return items
          .map((e) => Device.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status == 401) throw Exception('Phiên đăng nhập hết hạn');
      if (status == 403) throw Exception('Không có quyền xem thiết bị');
      throw Exception('Không tải được danh sách thiết bị');
    }
  }
}