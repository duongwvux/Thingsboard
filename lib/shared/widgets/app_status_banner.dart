import 'package:flutter/material.dart';

enum AppStatusTone { info, success, warning, error }

class AppStatusBanner extends StatelessWidget {
  final String message;
  final IconData icon;
  final AppStatusTone tone;

  const AppStatusBanner({
    super.key,
    required this.message,
    required this.icon,
    this.tone = AppStatusTone.info,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (background, foreground) = switch (tone) {
      AppStatusTone.success => (
        theme.colorScheme.primaryContainer,
        theme.colorScheme.onPrimaryContainer,
      ),
      AppStatusTone.warning => (
        theme.colorScheme.tertiaryContainer,
        theme.colorScheme.onTertiaryContainer,
      ),
      AppStatusTone.error => (
        theme.colorScheme.errorContainer,
        theme.colorScheme.onErrorContainer,
      ),
      AppStatusTone.info => (
        theme.colorScheme.secondaryContainer,
        theme.colorScheme.onSecondaryContainer,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: foreground),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(fontSize: 13, color: foreground),
            ),
          ),
        ],
      ),
    );
  }
}
