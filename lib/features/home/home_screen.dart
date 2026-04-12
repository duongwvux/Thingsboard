// features/home/home_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../devices/devices_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devicesAsync = ref.watch(devicesProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        centerTitle: false,
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(devicesProvider.notifier).refresh(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Summary cards ─────────────────────────────────────────────
            devicesAsync.when(
              loading: () => const _SummaryCardsSkeleton(),
              error: (_, __) => const SizedBox.shrink(),
              data: (devices) {
                final onlineCount  = devices.where((d) => d.active).length;
                final offlineCount = devices.length - onlineCount;
                return _SummaryCards(
                  total:   devices.length,
                  online:  onlineCount,
                  offline: offlineCount,
                );
              },
            ),

            const SizedBox(height: 20),

            // ── Recent devices ────────────────────────────────────────────
            Text('Thiết bị gần đây',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                )),
            const SizedBox(height: 10),

            devicesAsync.when(
              loading: () => const _DeviceRowSkeleton(),
              error: (e, _) => _InlineError(
                message: e.toString().replaceFirst('Exception: ', ''),
                onRetry: () => ref.read(devicesProvider.notifier).refresh(),
              ),
              data: (devices) {
                final recent = devices.take(5).toList();
                if (recent.isEmpty) {
                  return const _EmptyDevices();
                }
                return Column(
                  children: recent
                      .map((d) => _DeviceRow(device: d))
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Summary cards — 3 ô tổng quan
// ---------------------------------------------------------------------------

class _SummaryCards extends StatelessWidget {
  final int total;
  final int online;
  final int offline;
  const _SummaryCards(
      {required this.total, required this.online, required this.offline});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
            child: _SummaryCard(
          label: 'Tổng',
          value: '$total',
          icon: Icons.device_hub,
          color: Theme.of(context).colorScheme.primary,
        )),
        const SizedBox(width: 10),
        Expanded(
            child: _SummaryCard(
          label: 'Online',
          value: '$online',
          icon: Icons.wifi,
          color: Colors.green,
        )),
        const SizedBox(width: 10),
        Expanded(
            child: _SummaryCard(
          label: 'Offline',
          value: '$offline',
          icon: Icons.wifi_off,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        )),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _SummaryCard(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outlineVariant,
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 8),
          Text(value,
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w600, color: color)),
          Text(label,
              style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Device row — hiển thị gọn trong home
// ---------------------------------------------------------------------------

class _DeviceRow extends StatelessWidget {
  final device;
  const _DeviceRow({required this.device});

  @override
  Widget build(BuildContext context) {
    final theme    = Theme.of(context);
    final isOnline = device.active as bool;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        border: Border.all(
            color: theme.colorScheme.outlineVariant, width: 0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(
            Icons.circle,
            size: 8,
            color: isOnline ? Colors.green : theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(device.name as String,
                style: theme.textTheme.bodyMedium,
                overflow: TextOverflow.ellipsis),
          ),
          Text(
            isOnline ? 'Online' : 'Offline',
            style: theme.textTheme.bodySmall?.copyWith(
              color: isOnline
                  ? Colors.green
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Skeleton / placeholder widgets
// ---------------------------------------------------------------------------

class _SummaryCardsSkeleton extends StatelessWidget {
  const _SummaryCardsSkeleton();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(
        3,
        (_) => Expanded(
          child: Container(
            margin: const EdgeInsets.only(right: 10),
            height: 88,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }
}

class _DeviceRowSkeleton extends StatelessWidget {
  const _DeviceRowSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        3,
        (_) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          height: 44,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceVariant,
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }
}

class _EmptyDevices extends StatelessWidget {
  const _EmptyDevices();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Text(
          'Chưa có thiết bị nào',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _InlineError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(Icons.error_outline,
              size: 16, color: Theme.of(context).colorScheme.error),
          const SizedBox(width: 8),
          Expanded(
              child: Text(message,
                  style: Theme.of(context).textTheme.bodySmall)),
          TextButton(onPressed: onRetry, child: const Text('Thử lại')),
        ],
      ),
    );
  }
}