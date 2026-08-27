import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../utils/error_message.dart';
import 'app_error_view.dart';

class AppAsyncView<T> extends StatelessWidget {
  final AsyncValue<T> value;
  final Widget Function(T data) dataBuilder;
  final VoidCallback? onRetry;
  final Widget? loading;

  const AppAsyncView({
    super.key,
    required this.value,
    required this.dataBuilder,
    this.onRetry,
    this.loading,
  });

  @override
  Widget build(BuildContext context) {
    return value.when(
      loading: () =>
          loading ?? const Center(child: CircularProgressIndicator()),
      error: (error, _) =>
          AppErrorView(message: readableError(error), onRetry: onRetry),
      data: dataBuilder,
    );
  }
}
