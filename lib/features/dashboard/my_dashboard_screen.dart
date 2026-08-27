import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../shared/widgets/app_empty_state.dart';
import 'dashboard_provider.dart';
import 'widgets/add_tile_sheet.dart';
import 'widgets/dashboard_header.dart';
import 'widgets/dashboard_tile_grid.dart';

class MyDashboardScreen extends ConsumerWidget {
  const MyDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tiles = ref.watch(dashboardTilesProvider);

    return Scaffold(
      backgroundColor: AppColors.dashboardBackground,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DashboardHeader(onAddTile: () => _showAddTileSheet(context)),
            const SizedBox(height: 6),
            Expanded(
              child: tiles.isEmpty
                  ? AppEmptyState(
                      icon: Icons.dashboard_customize_outlined,
                      title: 'No tiles yet',
                      description: 'Tap + to add a sensor tile',
                      action: FilledButton.icon(
                        onPressed: () => _showAddTileSheet(context),
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Add tile'),
                      ),
                    )
                  : DashboardTileGrid(tiles: tiles),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddTileSheet(BuildContext context) async {
    final container = ProviderScope.containerOf(context);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => UncontrolledProviderScope(
        container: container,
        child: const AddTileSheet(),
      ),
    );
  }
}
