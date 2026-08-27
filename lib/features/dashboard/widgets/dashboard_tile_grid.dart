import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../devices/tb_rpc_service.dart';
import '../dashboard_provider.dart';
import '../dashboard_tile_config.dart';
import '../telemetry_model.dart';
import 'telemetry_chart.dart';

class DashboardTileGrid extends ConsumerWidget {
  final List<DashboardTileConfig> tiles;

  const DashboardTileGrid({super.key, required this.tiles});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1.45,
      ),
      itemCount: tiles.length,
      itemBuilder: (context, index) {
        final tile = tiles[index];
        final dataAsync = ref.watch(tileDataProvider(tile.id));

        return dataAsync.when(
          loading: () => _LoadingCard(config: tile),
          error: (_, _) => _OfflineCard(config: tile),
          data: (data) => _SensorCard(
            data: data,
            onLongPress: () => _confirmRemove(context, ref, tile),
          ),
        );
      },
    );
  }

  Future<void> _confirmRemove(
    BuildContext context,
    WidgetRef ref,
    DashboardTileConfig tile,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove tile'),
        content: Text('Remove "${tile.label}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed ?? false) {
      ref.read(dashboardTilesProvider.notifier).remove(tile.id);
    }
  }
}

class _SensorCard extends ConsumerWidget {
  final TileData data;
  final VoidCallback? onLongPress;

  const _SensorCard({required this.data, this.onLongPress});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnline = data.isOnline && data.latestValue != null;
    final color = data.config.sparklineColor;

    return GestureDetector(
      onLongPress: onLongPress,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.09),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 8, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      data.config.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.dashboardMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isOnline
                          ? const Color(0xFF4CAF50)
                          : AppColors.dashboardDisabled,
                    ),
                  ),
                ],
              ),
            ),
            if (data.config.isRpcControl)
              Expanded(
                child: Center(
                  child: Switch(
                    value: data.latestValue == 1,
                    activeThumbColor: color,
                    onChanged: (newValue) => _sendRpc(context, ref, newValue),
                  ),
                ),
              )
            else ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 2, 10, 0),
                child: isOnline
                    ? _ValueRow(
                        value: data.formattedValue,
                        unit: data.config.unit,
                        color: color,
                      )
                    : const _OfflineIndicator(),
              ),
              const SizedBox(height: 3),
              if (isOnline && data.sparklineValues.length >= 2)
                Expanded(
                  child: TelemetryChart(
                    values: data.sparklineValues,
                    color: color,
                    yMin: data.config.yMin,
                    yMax: data.config.yMax,
                  ),
                )
              else
                const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _sendRpc(
    BuildContext context,
    WidgetRef ref,
    bool newValue,
  ) async {
    final rpcService = ref.read(tbRpcServiceProvider);
    final succeeded = await rpcService.sendLedRpcRequest(
      data.config.deviceId,
      newValue,
    );
    if (!context.mounted) return;

    if (succeeded) {
      ref.invalidate(tileDataProvider(data.config.id));
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Lỗi gửi lệnh điều khiển!')));
    }
  }
}

class _ValueRow extends StatelessWidget {
  final String value;
  final String unit;
  final Color color;

  const _ValueRow({
    required this.value,
    required this.unit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w300,
            color: AppColors.dashboardPrimary,
            height: 1,
          ),
        ),
        if (unit.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 3, left: 2),
            child: Text(
              unit,
              style: TextStyle(
                fontSize: 10,
                color: color.withValues(alpha: 0.85),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }
}

class _OfflineIndicator extends StatelessWidget {
  const _OfflineIndicator();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Text(
          '– –',
          style: TextStyle(
            fontSize: 16,
            color: AppColors.dashboardDisabled,
            fontWeight: FontWeight.w300,
            letterSpacing: 4,
          ),
        ),
        SizedBox(width: 6),
        Icon(
          Icons.wifi_off_rounded,
          size: 11,
          color: AppColors.dashboardDisabled,
        ),
      ],
    );
  }
}

class _LoadingCard extends StatelessWidget {
  final DashboardTileConfig config;

  const _LoadingCard({required this.config});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            config.label,
            style: const TextStyle(
              fontSize: 11.5,
              color: AppColors.dashboardMuted,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 1.5,
              color: config.sparklineColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _OfflineCard extends StatelessWidget {
  final DashboardTileConfig config;

  const _OfflineCard({required this.config});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  config.label,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: AppColors.dashboardMuted,
                  ),
                ),
              ),
              Container(
                width: 5,
                height: 5,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.dashboardDisabled,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const _OfflineIndicator(),
        ],
      ),
    );
  }
}
