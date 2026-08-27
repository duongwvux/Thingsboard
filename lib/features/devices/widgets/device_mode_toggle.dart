import 'package:flutter/material.dart';

import '../add_device_provider.dart';

class DeviceModeToggle extends StatelessWidget {
  final DeviceMode selected;
  final ValueChanged<DeviceMode>? onChanged;

  const DeviceModeToggle({super.key, required this.selected, this.onChanged});

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
          : (selection) => onChanged!(selection.first),
    );
  }
}
