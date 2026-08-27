import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/dio_client.dart';

// Provider quản lý gọi lệnh RPC lên ThingsBoard
final tbRpcServiceProvider = Provider<TbRpcService>((ref) {
  // Watch dioClientProvider từ hệ thống core của dự án
  final dioClient = ref.watch(dioClientProvider);
  return TbRpcService(dioClient.dio);
});

class TbRpcService {
  final Dio _dio; // Sử dụng Dio Client đã được cấu hình trong core của dự án

  TbRpcService(this._dio);

  /// Gửi lệnh RPC bật/tắt LED tới một thiết bị cụ thể
  /// [deviceId] là ID của thiết bị trên ThingsBoard
  /// [isOn] là trạng thái mong muốn (true = BẬT, false = TẮT)
  Future<bool> sendLedRpcRequest(String deviceId, bool isOn) async {
    try {
      // Endpoint của ThingsBoard dành cho One-way RPC
      final String url = '/api/plugins/rpc/oneway/$deviceId';

      // Payload JSON tương thích hoàn toàn với hàm callback trên mạch ESP32
      final Map<String, dynamic> body = {'method': 'setLED', 'params': isOn};

      final response = await _dio.post(url, data: body);

      // Nếu mã trạng thái trả về là 200, lệnh đã được ThingsBoard tiếp nhận và gửi đi
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('❌ Lỗi gọi RPC từ Flutter: $e');
      return false;
    }
  }

  /// Hàm lấy trạng thái Telemetry (ledState) mới nhất từ ThingsBoard
  Future<bool?> getLatestLedState(String deviceId) async {
    try {
      // Gọi API Rest lấy dữ liệu chuỗi thời gian (timeseries) của thiết bị
      final String url =
          '/api/plugins/telemetry/DEVICE/$deviceId/values/timeseries';
      final response = await _dio.get(
        url,
        queryParameters: {'keys': 'ledState'}, // Chỉ lấy đúng key ledState
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        // ThingsBoard thường trả về dạng: {"ledState": [{"ts": 123456, "value": "ON"}]}
        if (data.containsKey('ledState') && data['ledState'].isNotEmpty) {
          final latestValue = data['ledState'][0]['value'];

          // Trả về true nếu trạng thái là Bật
          return latestValue == 'ON' ||
              latestValue == 'true' ||
              latestValue == true ||
              latestValue == 1;
        }
      }
    } catch (e) {
      debugPrint('❌ Lỗi khi lấy trạng thái ban đầu của LED: $e');
    }
    return null; // Trả về null nếu không có dữ liệu
  }
}
