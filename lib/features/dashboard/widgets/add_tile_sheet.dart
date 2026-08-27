import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_text_form_field.dart';
import '../../devices/device_model.dart';
import '../../devices/devices_provider.dart';
import '../dashboard_provider.dart';
import '../dashboard_tile_config.dart';

class AddTileSheet extends ConsumerStatefulWidget {
  const AddTileSheet({super.key});

  @override
  ConsumerState<AddTileSheet> createState() => _AddTileSheetState();
}

class _AddTileSheetState extends ConsumerState<AddTileSheet> {
  Device? _selectedDevice;
  String? _selectedKey;
  Color _selectedColor = DashboardTileConfig.presetColors.first;
  bool _isRpcControl = false;

  final _labelCtrl = TextEditingController();
  final _unitCtrl = TextEditingController();
  final _yMinCtrl = TextEditingController();
  final _yMaxCtrl = TextEditingController();

  @override
  void dispose() {
    _labelCtrl.dispose();
    _unitCtrl.dispose();
    _yMinCtrl.dispose();
    _yMaxCtrl.dispose();
    super.dispose();
  }

  void _selectTelemetryKey(String key) {
    setState(() {
      _selectedKey = key;
      if (_labelCtrl.text.isEmpty || _labelCtrl.text == _selectedDevice!.name) {
        _labelCtrl.text = key;
      }
    });

    final range = DashboardTileConfig.autoRange(key);
    if (range != null) {
      _yMinCtrl.text = _formatNumber(range.yMin);
      _yMaxCtrl.text = _formatNumber(range.yMax);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Add Tile',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 20),
            const _FieldLabel('Device'),
            const SizedBox(height: 8),
            _DevicePicker(
              selected: _selectedDevice,
              onSelected: (device) {
                setState(() {
                  _selectedDevice = device;
                  _selectedKey = null;
                  _yMinCtrl.clear();
                  _yMaxCtrl.clear();
                  if (_labelCtrl.text.isEmpty) _labelCtrl.text = device.name;
                });
              },
            ),
            const SizedBox(height: 16),
            if (_selectedDevice != null) ...[
              const _FieldLabel('Telemetry Key'),
              const SizedBox(height: 8),
              _TelemetryKeyPicker(
                deviceId: _selectedDevice!.id,
                selected: _selectedKey,
                onSelected: _selectTelemetryKey,
              ),
              const SizedBox(height: 16),
            ],
            const _FieldLabel('Display Name'),
            const SizedBox(height: 8),
            AppTextFormField(
              controller: _labelCtrl,
              hint: 'e.g. Temperature',
              dense: true,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            const _FieldLabel('Unit'),
            const SizedBox(height: 8),
            AppTextFormField(
              controller: _unitCtrl,
              hint: 'e.g. °C or %',
              dense: true,
            ),
            const SizedBox(height: 14),
            const _FieldLabel('Chart range (Y axis)'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: AppTextFormField(
                    controller: _yMinCtrl,
                    hint: 'Min  e.g. 0',
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                      signed: true,
                    ),
                    dense: true,
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    '–',
                    style: TextStyle(
                      color: AppColors.dashboardMuted,
                      fontSize: 16,
                    ),
                  ),
                ),
                Expanded(
                  child: AppTextFormField(
                    controller: _yMaxCtrl,
                    hint: 'Max  e.g. 100',
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                      signed: true,
                    ),
                    dense: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              _rangeHint,
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.dashboardMuted,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 14),
            const _FieldLabel('Colour'),
            const SizedBox(height: 8),
            _ColorPicker(
              selected: _selectedColor,
              onSelected: (color) => setState(() => _selectedColor = color),
            ),
            const SizedBox(height: 24),
            CheckboxListTile(
              title: const Text(
                'Là nút điều khiển Bật/Tắt (Gửi lệnh RPC)',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              value: _isRpcControl,
              activeColor: _selectedColor,
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              onChanged: (value) {
                setState(() => _isRpcControl = value ?? false);
              },
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _canSubmit ? _submit : null,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Add Tile'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool get _canSubmit {
    return _selectedDevice != null &&
        _selectedKey != null &&
        _labelCtrl.text.trim().isNotEmpty;
  }

  String get _rangeHint {
    if (_selectedKey != null &&
        DashboardTileConfig.autoRange(_selectedKey!) != null) {
      return '✦ Tự động nhận diện từ key "$_selectedKey"';
    }
    return 'Để trống → tự scale theo data';
  }

  void _submit() {
    final tile = DashboardTileConfig(
      id:
          '${_selectedDevice!.id}_${_selectedKey}_'
          '${DateTime.now().millisecondsSinceEpoch}',
      label: _labelCtrl.text.trim(),
      deviceId: _selectedDevice!.id,
      deviceName: _selectedDevice!.name,
      telemetryKey: _selectedKey!,
      unit: _unitCtrl.text.trim(),
      sparklineColor: _selectedColor,
      yMin: double.tryParse(_yMinCtrl.text.trim()),
      yMax: double.tryParse(_yMaxCtrl.text.trim()),
      isRpcControl: _isRpcControl,
    );
    ref.read(dashboardTilesProvider.notifier).add(tile);
    Navigator.pop(context);
  }

  String _formatNumber(double value) {
    return value % 1 == 0 ? value.toInt().toString() : value.toString();
  }
}

class _DevicePicker extends ConsumerWidget {
  final Device? selected;
  final ValueChanged<Device> onSelected;

  const _DevicePicker({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref
        .watch(devicesProvider)
        .when(
          loading: () => const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          error: (error, _) => Text(
            'Could not load devices',
            style: TextStyle(
              color: Theme.of(context).colorScheme.error,
              fontSize: 12,
            ),
          ),
          data: (devices) {
            if (devices.isEmpty) {
              return const Text(
                'No devices found',
                style: TextStyle(color: AppColors.dashboardMuted),
              );
            }
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: devices
                  .map(
                    (device) => ChoiceChip(
                      label: Text(device.name),
                      selected: device.id == selected?.id,
                      onSelected: (_) => onSelected(device),
                    ),
                  )
                  .toList(),
            );
          },
        );
  }
}

class _TelemetryKeyPicker extends ConsumerWidget {
  final String deviceId;
  final String? selected;
  final ValueChanged<String> onSelected;

  const _TelemetryKeyPicker({
    required this.deviceId,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref
        .watch(deviceTelemetryKeysProvider(deviceId))
        .when(
          loading: () => const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          error: (_, _) => const Text(
            'Could not load keys',
            style: TextStyle(color: Colors.red, fontSize: 12),
          ),
          data: (keys) {
            if (keys.isEmpty) {
              return const Text(
                'No telemetry data available',
                style: TextStyle(color: AppColors.dashboardMuted),
              );
            }
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: keys
                  .map(
                    (key) => ChoiceChip(
                      label: Text(key),
                      selected: key == selected,
                      onSelected: (_) => onSelected(key),
                    ),
                  )
                  .toList(),
            );
          },
        );
  }
}

class _ColorPicker extends StatelessWidget {
  final Color selected;
  final ValueChanged<Color> onSelected;

  const _ColorPicker({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: DashboardTileConfig.presetColors.map((color) {
        final isSelected = color.toARGB32() == selected.toARGB32();
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: GestureDetector(
            onTap: () => onSelected(color),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: isSelected
                    ? Border.all(color: Colors.white, width: 2.5)
                    : null,
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: color.withValues(alpha: 0.5),
                          blurRadius: 8,
                        ),
                      ]
                    : null,
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.white, size: 14)
                  : null,
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;

  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 11.5,
        fontWeight: FontWeight.w600,
        color: AppColors.dashboardLabel,
        letterSpacing: 0.4,
      ),
    );
  }
}
