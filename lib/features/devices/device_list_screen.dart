import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../shared/dialogs/confirm_logout_dialog.dart';
import '../../shared/widgets/app_async_view.dart';
import '../../shared/widgets/app_empty_state.dart';
import '../auth/auth_provider.dart';
import 'add_device_screen.dart';
import 'device_model.dart';
import 'devices_provider.dart';
import 'led_control_card.dart';
import 'tb_rpc_service.dart';
import 'widgets/device_card.dart';
import 'widgets/device_status_bar.dart';

class DeviceListScreen extends ConsumerWidget {
  const DeviceListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devicesAsync = ref.watch(devicesProvider);
    final rpcService = ref.watch(tbRpcServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thiết bị'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Đăng xuất',
            onPressed: () => _logout(context, ref),
          ),
        ],
      ),
      body: AppAsyncView<List<Device>>(
        value: devicesAsync,
        onRetry: () => ref.read(devicesProvider.notifier).refresh(),
        dataBuilder: (devices) {
          if (devices.isEmpty) {
            return const AppEmptyState(
              icon: Icons.device_hub,
              title: 'Chưa có thiết bị nào',
              description: 'Thêm thiết bị trong ThingsBoard dashboard',
            );
          }

          return RefreshIndicator(
            onRefresh: () => ref.read(devicesProvider.notifier).refresh(),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: devices.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final device = devices[index];
                if (device.type.toLowerCase() == 'led') {
                  return LedControlCard(
                    deviceId: device.id,
                    rpcService: rpcService,
                  );
                }
                return DeviceCard(
                  device: device,
                  onTap: () => context.push('/devices/${device.id}'),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute<void>(builder: (_) => const AddDeviceScreen()),
        ),
        tooltip: 'Thêm thiết bị',
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: devicesAsync.maybeWhen(
        data: (devices) => DeviceStatusBar(devices: devices),
        orElse: () => null,
      ),
    );
  }

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    if (await showLogoutConfirmation(context)) {
      await ref.read(authProvider.notifier).logout();
    }
  }
}
