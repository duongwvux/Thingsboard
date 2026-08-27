import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class DashboardHeader extends StatelessWidget {
  final VoidCallback onAddTile;

  const DashboardHeader({super.key, required this.onAddTile});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 14, 6),
      child: Row(
        children: [
          Text(
            'My Dashboard',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.dashboardPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const Spacer(),
          IconButton.filled(
            onPressed: onAddTile,
            style: IconButton.styleFrom(
              backgroundColor: AppColors.dashboardPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              minimumSize: const Size.square(32),
              maximumSize: const Size.square(32),
              padding: EdgeInsets.zero,
            ),
            icon: const Icon(Icons.add, color: Colors.white, size: 18),
          ),
        ],
      ),
    );
  }
}
