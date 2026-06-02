import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'devices_provider.dart';
import 'tb_device_service.dart';

// ─── Chế độ thiết bị ─────────────────────────
enum DeviceMode { real, wokwi }

enum AddDeviceStatus { idle, creatingDevice, sendingToEsp, success, error }

class AddDeviceState {
  final AddDeviceStatus status;
  final String message;
  final String token;         // Wokwi: hiện ra để copy
  final DeviceMode mode;      // chế độ đang chọn

  const AddDeviceState({
    this.status = AddDeviceStatus.idle,
    this.message = '',
    this.token = '',
    this.mode = DeviceMode.wokwi,
  });

  AddDeviceState copyWith({
    AddDeviceStatus? status,
    String? message,
    String? token,
    DeviceMode? mode,
  }) => AddDeviceState(
    status:  status  ?? this.status,
    message: message ?? this.message,
    token:   token   ?? this.token,
    mode:    mode    ?? this.mode,
  );
}

// ─── Notifier ────────────────────────────────
class AddDeviceNotifier extends Notifier<AddDeviceState> {
  @override
  AddDeviceState build() => const AddDeviceState();

  void setMode(DeviceMode mode) {
    state = state.copyWith(mode: mode);
  }

  // Thử tối đa 3 lần, mỗi lần cách nhau 500ms
  Future<String?> _getTokenWithRetry(
    TbDeviceService service,
    String deviceId,
  ) async {
    for (int i = 0; i < 3; i++) {
      await Future.delayed(const Duration(milliseconds: 500));
      final token = await service.getDeviceToken(deviceId);
      if (token != null) return token;
      debugPrint('getDeviceToken attempt ${i + 1} failed, retrying...');
    }
    return null;
  }

  Future<bool> addDevice({
    required String deviceName,
    required String wifiSsid,
    required String wifiPass,
  }) async {
    final service = ref.read(tbDeviceServiceProvider);

    // Bước 1 + 2: tạo device và lấy token (dùng chung cả 2 chế độ)
    state = state.copyWith(
      status: AddDeviceStatus.creatingDevice,
      message: 'Đang tạo thiết bị trên ThingsBoard...',
    );
    final deviceId = await service.createDevice(deviceName);
    if (deviceId == null) {
      state = state.copyWith(
        status: AddDeviceStatus.error,
        message: 'Không tạo được thiết bị. Kiểm tra quyền tài khoản.',
      );
      return false;
    }

    await Future.delayed(const Duration(milliseconds: 500));

    final token = await _getTokenWithRetry(service, deviceId);
    if (token == null) {
      state = state.copyWith(
        status: AddDeviceStatus.error,
        message: 'Không lấy được token thiết bị.',
      );
      return false;
    }

    // Bước 3: phân nhánh theo chế độ
    if (state.mode == DeviceMode.wokwi) {
      return _handleWokwi(token);
    } else {
      return _handleRealEsp32(token, wifiSsid, wifiPass);
    }
  }

  // ─── Wokwi: chỉ hiện token để user copy ──────
  bool _handleWokwi(String token) {
    state = state.copyWith(
      status: AddDeviceStatus.success,
      message: 'Thiết bị đã tạo! Copy token dán vào Wokwi.',
      token: token,
    );
    return true;
  }

  // ─── ESP32 thật: gửi config qua WiFi AP ──────
  Future<bool> _handleRealEsp32(
    String token,
    String wifiSsid,
    String wifiPass,
  ) async {
    state = state.copyWith(
      status: AddDeviceStatus.sendingToEsp,
      message: 'Đang gửi config cho ESP32...',
    );
    try {
      final res = await http.post(
        Uri.parse('http://192.168.4.1/config'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'ssid':  wifiSsid,
          'pass':  wifiPass,
          'token': token,
        }),
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        state = state.copyWith(
          status: AddDeviceStatus.success,
          message: 'Thành công! ESP32 đang kết nối...',
          token: '',
        );
        return true;
      }
      state = state.copyWith(
        status: AddDeviceStatus.error,
        message: 'ESP32 phản hồi lỗi. Thử lại.',
      );
      return false;
    } catch (_) {
      state = state.copyWith(
        status: AddDeviceStatus.error,
        message: 'Không kết nối được ESP32.\n'
            'Hãy kết nối WiFi "ESP32-Setup-XXXX" trước.',
      );
      return false;
    }
  }
}

final addDeviceProvider =
    NotifierProvider.autoDispose<AddDeviceNotifier, AddDeviceState>(
  AddDeviceNotifier.new,
);