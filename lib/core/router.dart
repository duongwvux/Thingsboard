// core/router.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/auth_provider.dart';
import '../features/auth/auth_state.dart';
import '../features/auth/login_screen.dart';
// import '../features/devices/device_list_screen.dart'; // thêm sau

final routerProvider = Provider<GoRouter>((ref) {
  // routerProvider lắng nghe authProvider để tự redirect
  final authNotifier = ref.watch(authProvider.notifier);

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: _AuthStateListenable(ref),

    redirect: (context, state) {
      final authAsync = ref.read(authProvider);

      // Đang load session ban đầu → chưa redirect
      if (authAsync.isLoading) return null;

      AuthState? authValue;
      authAsync.whenData((value) => authValue = value);
      final isAuthenticated = authValue is AuthAuthenticated;
      final isOnLogin = state.matchedLocation == '/login';

      if (!isAuthenticated && !isOnLogin) return '/login';
      if (isAuthenticated && isOnLogin)   return '/devices';
      return null;
    },

    routes: [
      GoRoute(
        path: '/login',
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: '/devices',
        // builder: (_, __) => const DeviceListScreen(),
        builder: (_, __) => const _PlaceholderScreen(title: 'Danh sách thiết bị'),
      ),
    ],
  );
});

// Placeholder — xóa sau khi có DeviceListScreen thật
class _PlaceholderScreen extends StatelessWidget {
  final String title;
  const _PlaceholderScreen({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: Text(title)));
  }
}

// Cho GoRouter biết khi nào cần chạy lại redirect
class _AuthStateListenable extends ChangeNotifier {
  _AuthStateListenable(Ref ref) {
    ref.listen(authProvider, (_, __) => notifyListeners());
  }
}
