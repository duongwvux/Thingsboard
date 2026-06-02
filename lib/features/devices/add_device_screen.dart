import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'add_device_provider.dart';
import 'devices_provider.dart';

class AddDeviceScreen extends ConsumerStatefulWidget {
  const AddDeviceScreen({super.key});
  @override
  ConsumerState<AddDeviceScreen> createState() => _AddDeviceScreenState();
}

class _AddDeviceScreenState extends ConsumerState<AddDeviceScreen> {
  final _formKey  = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _ssidCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure   = true;

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

    final ok = await ref.read(addDeviceProvider.notifier).addDevice(
      deviceName: _nameCtrl.text.trim(),
      wifiSsid:   _ssidCtrl.text.trim(),
      wifiPass:   _passCtrl.text,
    );

    if (ok && mounted) {
      ref.read(devicesProvider.notifier).refresh();
      // Wokwi: ở lại màn hình để user copy token
      // ESP32 thật: đóng màn hình sau 2 giây
      final state = ref.read(addDeviceProvider);
      if (state.mode == DeviceMode.real) {
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state     = ref.watch(addDeviceProvider);
    final isLoading = state.status == AddDeviceStatus.creatingDevice ||
                      state.status == AddDeviceStatus.sendingToEsp;
    final isWokwi   = state.mode == DeviceMode.wokwi;

    return Scaffold(
      appBar: AppBar(title: const Text('Thêm thiết bị')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [

              // ── Toggle chế độ ───────────────────────────
              _ModeToggle(
                selected: state.mode,
                onChanged: isLoading
                    ? null
                    : (m) => ref.read(addDeviceProvider.notifier).setMode(m),
              ),
              const SizedBox(height: 20),

              // ── Hướng dẫn tuỳ theo chế độ ───────────────
              _InfoBanner(isWokwi: isWokwi),
              const SizedBox(height: 20),

              // ── Tên thiết bị ─────────────────────────────
              TextFormField(
                controller: _nameCtrl,
                enabled: !isLoading,
                decoration: const InputDecoration(
                  labelText: 'Tên thiết bị',
                  prefixIcon: Icon(Icons.device_hub_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    v!.trim().isEmpty ? 'Nhập tên thiết bị' : null,
              ),
              const SizedBox(height: 14),

              // ── WiFi fields: chỉ hiện khi ESP32 thật ─────
              if (!isWokwi) ...[
                TextFormField(
                  controller: _ssidCtrl,
                  enabled: !isLoading,
                  decoration: const InputDecoration(
                    labelText: 'WiFi SSID',
                    hintText: 'Tên mạng WiFi nhà bạn',
                    prefixIcon: Icon(Icons.wifi),
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      v!.trim().isEmpty ? 'Nhập SSID' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _passCtrl,
                  enabled: !isLoading,
                  obscureText: _obscure,
                  decoration: InputDecoration(
                    labelText: 'WiFi Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(_obscure
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined),
                      onPressed: () =>
                          setState(() => _obscure = !_obscure),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // ── Nút thêm ─────────────────────────────────
              FilledButton.icon(
                onPressed: isLoading ? null : _submit,
                icon: isLoading
                    ? const SizedBox(
                        width: 16, height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.add),
                label: Text(isLoading ? state.message : 'Thêm thiết bị'),
                style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48)),
              ),

              // ── Kết quả ──────────────────────────────────
              if (state.status == AddDeviceStatus.error) ...[
                const SizedBox(height: 16),
                _StatusCard(
                  icon: Icons.error_outline,
                  message: state.message,
                  isSuccess: false,
                ),
              ],

              // ── Wokwi: hiện token để copy ─────────────────
              if (state.status == AddDeviceStatus.success &&
                  state.token.isNotEmpty) ...[
                const SizedBox(height: 16),
                _TokenCard(token: state.token),
              ],

              // ── ESP32 thật: thông báo thành công ──────────
              if (state.status == AddDeviceStatus.success &&
                  state.token.isEmpty) ...[
                const SizedBox(height: 16),
                _StatusCard(
                  icon: Icons.check_circle_outline,
                  message: state.message,
                  isSuccess: true,
                ),
              ],

            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Widget: Toggle chế độ
// ─────────────────────────────────────────────
class _ModeToggle extends StatelessWidget {
  final DeviceMode selected;
  final ValueChanged<DeviceMode>? onChanged;

  const _ModeToggle({required this.selected, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<DeviceMode>(
      segments: const [
        ButtonSegment(
          value: DeviceMode.wokwi,
          icon: Icon(Icons.computer_outlined),
          label: Text('Wokwi (ảo)'),
        ),
        ButtonSegment(
          value: DeviceMode.real,
          icon: Icon(Icons.memory_outlined),
          label: Text('ESP32 thật'),
        ),
      ],
      selected: {selected},
      onSelectionChanged: onChanged == null
          ? null
          : (s) => onChanged!(s.first),
    );
  }
}

// ─────────────────────────────────────────────
// Widget: Banner hướng dẫn
// ─────────────────────────────────────────────
class _InfoBanner extends StatelessWidget {
  final bool isWokwi;
  const _InfoBanner({required this.isWokwi});

  @override
  Widget build(BuildContext context) {
    final text = isWokwi
        ? 'App sẽ tạo thiết bị và hiện token.\nCopy token dán vào code Wokwi là xong.'
        : 'Vào Cài đặt WiFi → kết nối vào mạng "ESP32-Setup-XXXX"\nrồi quay lại đây điền form.';

    final icon = isWokwi ? Icons.laptop_outlined : Icons.wifi_outlined;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon,
              size: 18,
              color: Theme.of(context).colorScheme.onSecondaryContainer),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSecondaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Widget: Hiện token để copy (Wokwi)
// ─────────────────────────────────────────────
class _TokenCard extends StatelessWidget {
  final String token;
  const _TokenCard({required this.token});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.key_outlined,
                size: 16,
                color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 6),
            Text('Token — dán vào Wokwi',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                )),
          ]),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              token,
              style: const TextStyle(
                  fontFamily: 'monospace', fontSize: 13),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.copy, size: 16),
              label: const Text('Copy token'),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: token));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Đã copy! Dán vào WOKWI_TOKEN trong code.'),
                    duration: Duration(seconds: 3),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Widget: Status thành công / lỗi
// ─────────────────────────────────────────────
class _StatusCard extends StatelessWidget {
  final IconData icon;
  final String message;
  final bool isSuccess;
  const _StatusCard({
    required this.icon,
    required this.message,
    required this.isSuccess,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isSuccess
        ? Theme.of(context).colorScheme.primaryContainer
        : Theme.of(context).colorScheme.errorContainer;
    final fg = isSuccess
        ? Theme.of(context).colorScheme.onPrimaryContainer
        : Theme.of(context).colorScheme.onErrorContainer;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(8)),
      child: Row(children: [
        Icon(icon, size: 16, color: fg),
        const SizedBox(width: 8),
        Expanded(
            child: Text(message,
                style: TextStyle(fontSize: 13, color: fg))),
      ]),
    );
  }
}