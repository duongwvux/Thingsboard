import 'package:flutter/material.dart';

import '../add_device_provider.dart';

class ProvisioningStepper extends StatelessWidget {
  final AddDeviceStatus status;

  const ProvisioningStepper({super.key, required this.status});

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
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: steps.asMap().entries.map((entry) {
          final index = entry.key;
          final step = entry.value;
          return Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: step.done
                      ? Colors.green
                      : step.active
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(
                          context,
                        ).colorScheme.outline.withValues(alpha: 0.2),
                ),
                child: step.active
                    ? const Padding(
                        padding: EdgeInsets.all(8),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
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
              if (index < steps.length - 1)
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Icon(
                      Icons.arrow_downward,
                      size: 14,
                      color: Theme.of(
                        context,
                      ).colorScheme.outline.withValues(alpha: 0.4),
                    ),
                  ),
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  bool _isDone(AddDeviceStatus step) {
    const order = [
      AddDeviceStatus.creatingDevice,
      AddDeviceStatus.sendingToRelay,
      AddDeviceStatus.success,
    ];
    final stepIndex = order.indexOf(step);
    final statusIndex = order.indexOf(status);
    return statusIndex > stepIndex || status == AddDeviceStatus.success;
  }
}
