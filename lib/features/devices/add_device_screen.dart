import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/utils/form_validators.dart';
import '../../shared/widgets/app_status_banner.dart';
import '../../shared/widgets/app_text_form_field.dart';
import 'add_device_provider.dart';
import 'devices_provider.dart';
import 'widgets/device_mode_toggle.dart';
import 'widgets/provisioning_stepper.dart';
import 'widgets/token_card.dart';

class AddDeviceScreen extends ConsumerStatefulWidget {
  const AddDeviceScreen({super.key});

  @override
  ConsumerState<AddDeviceScreen> createState() => _AddDeviceScreenState();
}

class _AddDeviceScreenState extends ConsumerState<AddDeviceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _ssidCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _ssidCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final succeeded = await ref
        .read(addDeviceProvider.notifier)
        .addDevice(
          deviceName: _nameCtrl.text.trim(),
          wifiSsid: _ssidCtrl.text.trim(),
          wifiPass: _passCtrl.text,
        );

    if (!succeeded || !mounted) return;
    ref.read(devicesProvider.notifier).refresh();

    final state = ref.read(addDeviceProvider);
    if (state.mode == DeviceMode.real) {
      await Future<void>.delayed(const Duration(seconds: 2));
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(addDeviceProvider);
    final isLoading = {
      AddDeviceStatus.creatingDevice,
      AddDeviceStatus.sendingToRelay,
      AddDeviceStatus.sendingToEsp,
    }.contains(state.status);
    final isWokwi = state.mode == DeviceMode.wokwi;

    return Scaffold(
      appBar: AppBar(title: const Text('Thêm thiết bị')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DeviceModeToggle(
                selected: state.mode,
                onChanged: isLoading
                    ? null
                    : ref.read(addDeviceProvider.notifier).setMode,
              ),
              const SizedBox(height: 20),
              AppStatusBanner(
                icon: isWokwi ? Icons.sync_outlined : Icons.wifi_outlined,
                message: isWokwi
                    ? 'App tạo device → lấy token → POST lên relay server.\n'
                          'ESP32 Wokwi sẽ tự poll và kết nối ThingsBoard.'
                    : 'Vào Cài đặt WiFi → kết nối "ESP32-Setup-XXXX"\n'
                          'rồi quay lại đây điền form.',
              ),
              const SizedBox(height: 20),
              AppTextFormField(
                controller: _nameCtrl,
                enabled: !isLoading,
                label: 'Tên thiết bị',
                hint: 'Phải khớp với DEVICE_ID trong config.h',
                prefixIcon: Icons.device_hub_outlined,
                onChanged: (_) => setState(() {}),
                validator: (value) => FormValidators.requiredText(
                  value,
                  message: 'Nhập tên thiết bị',
                ),
              ),
              if (isWokwi && _nameCtrl.text.trim().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 6, left: 4),
                  child: Text(
                    'device_id relay: ${_relayDeviceId(_nameCtrl.text)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.primary,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              const SizedBox(height: 14),
              if (!isWokwi) ...[
                AppTextFormField(
                  controller: _ssidCtrl,
                  enabled: !isLoading,
                  label: 'WiFi SSID',
                  prefixIcon: Icons.wifi,
                  validator: (value) =>
                      FormValidators.requiredText(value, message: 'Nhập SSID'),
                ),
                const SizedBox(height: 14),
                AppTextFormField(
                  controller: _passCtrl,
                  enabled: !isLoading,
                  label: 'WiFi Password',
                  prefixIcon: Icons.lock_outline,
                  obscureText: _obscure,
                  textInputAction: TextInputAction.done,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscure
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
                const SizedBox(height: 14),
              ],
              FilledButton.icon(
                onPressed: isLoading ? null : _submit,
                icon: isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.add),
                label: Text(
                  isLoading ? _loadingLabel(state.status) : 'Thêm thiết bị',
                ),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
              ),
              if (isWokwi && state.status != AddDeviceStatus.idle) ...[
                const SizedBox(height: 20),
                ProvisioningStepper(status: state.status),
              ],
              if (state.status == AddDeviceStatus.error) ...[
                const SizedBox(height: 16),
                AppStatusBanner(
                  icon: Icons.error_outline,
                  message: state.message,
                  tone: AppStatusTone.error,
                ),
                if (state.token.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'Token vẫn hợp lệ — copy thủ công nếu relay lỗi:',
                    style: TextStyle(fontSize: 12, color: Colors.orange),
                  ),
                  const SizedBox(height: 8),
                  TokenCard(token: state.token, isManual: true),
                ],
              ],
              if (state.status == AddDeviceStatus.success) ...[
                const SizedBox(height: 16),
                AppStatusBanner(
                  icon: Icons.check_circle_outline,
                  message: state.message,
                  tone: AppStatusTone.success,
                ),
                if (isWokwi && state.token.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  TokenCard(token: state.token, isManual: false),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _loadingLabel(AddDeviceStatus status) => switch (status) {
    AddDeviceStatus.creatingDevice => 'Đang tạo thiết bị...',
    AddDeviceStatus.sendingToRelay => 'Đang gửi lên relay...',
    AddDeviceStatus.sendingToEsp => 'Đang gửi cho ESP32...',
    _ => 'Đang xử lý...',
  };

  String _relayDeviceId(String name) {
    return name.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '-');
  }
}
