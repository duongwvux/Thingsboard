import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/dio_client.dart';
import 'device_model.dart';
import 'tb_device_service.dart';

// ---------------------------------------------------------------------------
// Service provider
// ---------------------------------------------------------------------------

final tbDeviceServiceProvider = Provider<TbDeviceService>((ref) {
  return TbDeviceService(ref.read(dioClientProvider).dio);
});

// ---------------------------------------------------------------------------
// devicesProvider — poll mỗi 20s để phát hiện thiết bị mới/xoá
// Trạng thái active của mỗi device được ThingsBoard cập nhật trong payload
// Kết hợp với WS nếu cần cập nhật active realtime trên DeviceListScreen
// ---------------------------------------------------------------------------

class DevicesNotifier extends AsyncNotifier<List<Device>> {
  Timer? _timer;

  @override
  Future<List<Device>> build() async {
    ref.onDispose(() => _timer?.cancel());

    _timer = Timer.periodic(const Duration(seconds: 20), (_) {
      ref.invalidateSelf();
    });

    return _fetch();
  }

  Future<List<Device>> _fetch() =>
      ref.read(tbDeviceServiceProvider).getDevices();

  Future<void> refresh() async {
    _timer?.cancel();
    ref.invalidateSelf();
  }
}

final devicesProvider =
    AsyncNotifierProvider<DevicesNotifier, List<Device>>(DevicesNotifier.new);