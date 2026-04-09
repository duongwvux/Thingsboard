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
// devicesProvider — tải và cache danh sách thiết bị
// ---------------------------------------------------------------------------

final devicesProvider =
    AsyncNotifierProvider<DevicesNotifier, List<Device>>(DevicesNotifier.new);

class DevicesNotifier extends AsyncNotifier<List<Device>> {
  @override
  Future<List<Device>> build() async {
    return _fetchDevices();
  }

  Future<List<Device>> _fetchDevices() {
    return ref.read(tbDeviceServiceProvider).getDevices();
  }

  /// Gọi khi user kéo refresh — cập nhật lại danh sách
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetchDevices);
  }
}