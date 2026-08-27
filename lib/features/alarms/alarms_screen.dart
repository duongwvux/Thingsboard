// features/alarms/alarms_screen.dart

import 'package:flutter/material.dart';
import '../../shared/widgets/app_empty_state.dart';

class AlarmsScreen extends StatelessWidget {
  const AlarmsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Alarms')),
      body: const AppEmptyState(
        icon: Icons.notifications_none,
        title: 'Chưa có alarm',
        description: 'Tính năng đang phát triển',
      ),
    );
  }
}
