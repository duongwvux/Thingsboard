import 'package:dio/dio.dart';
import '../../core/dio_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TbRpcService {
  final Dio _dio;
  TbRpcService(this._dio);

  /// Gửi lệnh bật/tắt LED
  Future<bool> setLed({
    required String deviceId,
    required bool enabled,
  }) async {
    try {
      await _dio.post(
        '/api/plugins/rpc/oneway/$deviceId',
        data: {
          'method': 'setValue',
          'params': {'enabled': enabled},
        },
      );
      return true;
    } on DioException catch (e) {
      return false;
    }
  }
}

final tbRpcServiceProvider = Provider<TbRpcService>((ref) {
  return TbRpcService(ref.read(dioClientProvider).dio);
});