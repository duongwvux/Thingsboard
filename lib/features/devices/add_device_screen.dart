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

      // ESP32 thật: đóng màn hình sau 2 giây
      // Wokwi: ở lại để user thấy kết quả (token + trạng thái relay)
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
                      state.status == AddDeviceStatus.sendingToRelay ||
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

              // ── Toggle chế độ ────────────────────────────────────────────
              _ModeToggle(
                selected: state.mode,
                onChanged: isLoading
                    ? null
                    : (m) => ref.read(addDeviceProvider.notifier).setMode(m),
              ),
              const SizedBox(height: 20),

              // ── Banner hướng dẫn ──────────────────────────────────────────
              _InfoBanner(isWokwi: isWokwi),
              const SizedBox(height: 20),

              // ── Tên thiết bị ──────────────────────────────────────────────
              TextFormField(
                controller: _nameCtrl,
                enabled: !isLoading,
                decoration: const InputDecoration(
                  labelText: 'Tên thiết bị',
                  hintText: 'Phải khớp với DEVICE_ID trong config.h',
                  prefixIcon: Icon(Icons.device_hub_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    v!.trim().isEmpty ? 'Nhập tên thiết bị' : null,
              ),

              // ── Hint device_id sẽ được tạo ra ────────────────────────────
              if (isWokwi && _nameCtrl.text.trim().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 6, left: 4),
                  child: Text(
                    'device_id relay: '
                    '${_nameCtrl.text.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '-')}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.primary,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              const SizedBox(height: 14),

              // ── WiFi fields: chỉ hiện khi ESP32 thật ─────────────────────
              if (!isWokwi) ...[
                TextFormField(
                  controller: _ssidCtrl,
                  enabled: !isLoading,
                  decoration: const InputDecoration(
                    labelText: 'WiFi SSID',
                    prefixIcon: Icon(Icons.wifi),
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => v!.trim().isEmpty ? 'Nhập SSID' : null,
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

              // ── Nút thêm ──────────────────────────────────────────────────
              FilledButton.icon(
                onPressed: isLoading ? null : _submit,
                icon: isLoading
                    ? const SizedBox(
                        width: 16, height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.add),
                label: Text(isLoading ? _loadingLabel(state.status) : 'Thêm thiết bị'),
                style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48)),
              ),

              // ── Stepper tiến trình (Wokwi) ────────────────────────────────
              if (isWokwi && state.status != AddDeviceStatus.idle) ...[
                const SizedBox(height: 20),
                _ProgressStepper(status: state.status),
              ],

              // ── Kết quả lỗi ───────────────────────────────────────────────
              if (state.status == AddDeviceStatus.error) ...[
                const SizedBox(height: 16),
                _StatusCard(
                  icon: Icons.error_outline,
                  message: state.message,
                  isSuccess: false,
                ),
                // Nếu đã có token dù lỗi relay → vẫn hiện để copy thủ công
                if (state.token.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'Token vẫn hợp lệ — copy thủ công nếu relay lỗi:',
                    style: TextStyle(fontSize: 12, color: Colors.orange),
                  ),
                  const SizedBox(height: 8),
                  _TokenCard(token: state.token, isManual: true),
                ],
              ],

              // ── Thành công Wokwi ──────────────────────────────────────────
              if (state.status == AddDeviceStatus.success &&
                  state.token.isNotEmpty &&
                  isWokwi) ...[
                const SizedBox(height: 16),
                _StatusCard(
                  icon: Icons.check_circle_outline,
                  message: state.message,
                  isSuccess: true,
                ),
                const SizedBox(height: 12),
                _TokenCard(token: state.token, isManual: false),
              ],

              // ── Thành công ESP32 thật ──────────────────────────────────────
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

  String _loadingLabel(AddDeviceStatus s) => switch (s) {
    AddDeviceStatus.creatingDevice => 'Đang tạo thiết bị...',
    AddDeviceStatus.sendingToRelay => 'Đang gửi lên relay...',
    AddDeviceStatus.sendingToEsp   => 'Đang gửi cho ESP32...',
    _                              => 'Đang xử lý...',
  };
}

// ─────────────────────────────────────────────────────────────────────────────
// _ProgressStepper — hiện 3 bước cho Wokwi flow
// ─────────────────────────────────────────────────────────────────────────────

class _ProgressStepper extends StatelessWidget {
  final AddDeviceStatus status;
  const _ProgressStepper({required this.status});

  @override
  Widget build(BuildContext context) {
    final steps = [
      (
        label: 'Tạo thiết bị',
        icon: Icons.cloud_upload_outlined,
        done: _isDone(AddDeviceStatus.creatingDevice),
        active: status == AddDeviceStatus.creatingDevice,
      ),
      (
        label: 'Gửi token lên relay',
        icon: Icons.send_outlined,
        done: _isDone(AddDeviceStatus.sendingToRelay),
        active: status == AddDeviceStatus.sendingToRelay,
      ),
      (
        label: 'ESP32 kết nối',
        icon: Icons.sensors_outlined,
        done: status == AddDeviceStatus.success,
        active: false,
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: steps.asMap().entries.map((e) {
          final i    = e.key;
          final step = e.value;
          return Row(
            children: [
              // ── Icon bước ─────────────────────────────────────────
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: step.done
                      ? Colors.green
                      : step.active
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.outline
                              .withOpacity(0.2),
                ),
                child: step.active
                    ? const Padding(
                        padding: EdgeInsets.all(8),
                        child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                      )
                    : Icon(
                        step.done ? Icons.check : step.icon,
                        size: 16,
                        color: step.done || step.active
                            ? Colors.white
                            : Theme.of(context).colorScheme.outline,
                      ),
              ),
              const SizedBox(width: 12),

              // ── Label ──────────────────────────────────────────────
              Text(
                step.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: step.active || step.done
                      ? FontWeight.w500
                      : FontWeight.normal,
                  color: step.done
                      ? Colors.green
                      : step.active
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),

              // ── Gạch nối xuống bước tiếp theo ─────────────────────
              if (i < steps.length - 1)
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Icon(
                      Icons.arrow_downward,
                      size: 14,
                      color: Theme.of(context).colorScheme.outline
                          .withOpacity(0.4),
                    ),
                  ),
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  // Một bước được coi là "done" khi status đã vượt qua nó
  bool _isDone(AddDeviceStatus step) {
    const order = [
      AddDeviceStatus.creatingDevice,
      AddDeviceStatus.sendingToRelay,
      AddDeviceStatus.success,
    ];
    final stepIdx   = order.indexOf(step);
    final statusIdx = order.indexOf(status);
    return statusIdx > stepIdx ||
        status == AddDeviceStatus.success ||
        (status == AddDeviceStatus.error && statusIdx > stepIdx);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Các widget con (giữ nguyên + bổ sung isManual cho _TokenCard)
// ─────────────────────────────────────────────────────────────────────────────

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
      onSelectionChanged:
          onChanged == null ? null : (s) => onChanged!(s.first),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  final bool isWokwi;
  const _InfoBanner({required this.isWokwi});

  @override
  Widget build(BuildContext context) {
    final text = isWokwi
        ? 'App tạo device → lấy token → POST lên relay server.\n'
          'ESP32 Wokwi sẽ tự poll và kết nối ThingsBoard.'
        : 'Vào Cài đặt WiFi → kết nối "ESP32-Setup-XXXX"\n'
          'rồi quay lại đây điền form.';
    final icon = isWokwi ? Icons.sync_outlined : Icons.wifi_outlined;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18,
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

class _TokenCard extends StatelessWidget {
  final String token;
  final bool isManual; // true = relay lỗi, cần copy thủ công
  const _TokenCard({required this.token, required this.isManual});

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
            Icon(Icons.key_outlined, size: 16,
                color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 6),
            Text(
              isManual ? 'Token — dán thủ công vào config.h' : 'Token (tham khảo)',
              style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ]),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(6),
            ),
            child: SelectableText(
              token,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
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
                    content: Text('Đã copy! Dán vào TB_TOKEN trong config.h'),
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
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: fg),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message,
                style: TextStyle(fontSize: 13, color: fg)),
          ),
        ],
      ),
    );
  }
}