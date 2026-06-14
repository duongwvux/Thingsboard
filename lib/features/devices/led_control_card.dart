import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'device_model.dart';
import 'tb_rpc_service.dart';

class LedControlCard extends ConsumerStatefulWidget {
  final Device device;
  const LedControlCard({super.key, required this.device});

  @override
  ConsumerState<LedControlCard> createState() => _LedControlCardState();
}

class _LedControlCardState extends ConsumerState<LedControlCard> {
  bool _isOn      = false;
  bool _loading   = false;

  Future<void> _toggle() async {
    setState(() => _loading = true);
    final newState = !_isOn;

    final ok = await ref.read(tbRpcServiceProvider).setLed(
      deviceId: widget.device.id,
      enabled:  newState,
    );

    if (ok) setState(() => _isOn = newState);
    setState(() => _loading = false);

    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gửi lệnh thất bại')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme    = Theme.of(context);
    final isOnline = widget.device.active;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant,
          width: 0.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Icon đèn
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: _isOn
                    ? Colors.amber.shade100
                    : theme.colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _isOn ? Icons.lightbulb : Icons.lightbulb_outline,
                color: _isOn ? Colors.amber.shade700 : theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 16),

            // Tên + trạng thái
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.device.name,
                      style: theme.textTheme.bodyLarge
                          ?.copyWith(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 2),
                  Row(children: [
                    Icon(Icons.circle,
                        size: 8,
                        color: isOnline ? Colors.green : theme.colorScheme.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text(
                      isOnline
                          ? (_isOn ? 'Đang bật' : 'Đang tắt')
                          : 'Offline',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isOnline
                            ? (_isOn ? Colors.amber.shade700 : theme.colorScheme.onSurfaceVariant)
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ]),
                ],
              ),
            ),

            // Toggle
            _loading
                ? const SizedBox(
                    width: 24, height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : Switch(
                    value: _isOn,
                    onChanged: isOnline ? (_) => _toggle() : null,
                  ),
          ],
        ),
      ),
    );
  }
}