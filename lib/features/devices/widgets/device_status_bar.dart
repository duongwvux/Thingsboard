import 'package:flutter/material.dart';

import '../device_model.dart';

class DeviceStatusBar extends StatelessWidget {
  final List<Device> devices;

  const DeviceStatusBar({super.key, required this.devices});

  @override
  Widget build(BuildContext context) {
    final onlineCount = devices.where((device) => device.active).length;
    final theme = Theme.of(context);

    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: theme.colorScheme.outlineVariant, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.circle, size: 8, color: Colors.green),
          const SizedBox(width: 6),
          Text('$onlineCount online', style: theme.textTheme.bodySmall),
          const SizedBox(width: 16),
          Icon(
            Icons.circle,
            size: 8,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 6),
          Text(
            '${devices.length - onlineCount} offline',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const Spacer(),
          Text(
            '${devices.length} thiết bị',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
