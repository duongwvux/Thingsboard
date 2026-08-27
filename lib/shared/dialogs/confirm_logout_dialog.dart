import 'package:flutter/material.dart';

Future<bool> showLogoutConfirmation(BuildContext context) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Đăng xuất'),
      content: const Text('Bạn có chắc muốn đăng xuất không?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Huỷ'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text('Đăng xuất'),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}
