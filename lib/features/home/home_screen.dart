import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../core/app_constants.dart';
import '../auth/auth_provider.dart';
import '../auth/auth_state.dart';
import 'dashboard_model.dart';
import 'dashboards_provider.dart';
 
// ---------------------------------------------------------------------------
// HomeScreen — danh sách dashboard, tap để xem từng dashboard
// ---------------------------------------------------------------------------
 
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});
 
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardsAsync = ref.watch(dashboardsProvider);
 
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        centerTitle: false,
      ),
      body: dashboardsAsync.when(
        loading: () => const _DashboardListSkeleton(),
 
        error: (e, _) => _ErrorView(
          message: e.toString().replaceFirst('Exception: ', ''),
          onRetry: () => ref.read(dashboardsProvider.notifier).refresh(),
        ),
 
        data: (dashboards) {
          if (dashboards.isEmpty) return const _EmptyView();
 
          return RefreshIndicator(
            onRefresh: () => ref.read(dashboardsProvider.notifier).refresh(),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: dashboards.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) => _DashboardCard(
                dashboard: dashboards[i],
                onTap: () => _openDashboard(context, ref, dashboards[i]),
              ),
            ),
          );
        },
      ),
    );
  }
 
  void _openDashboard(BuildContext context, WidgetRef ref, Dashboard dashboard) {
  // 1. Chỉ đọc provider một lần duy nhất
  final authState = ref.read(authProvider);

  final String? token = authState.mapOrNull(
      data: (asyncData) {
      final state = asyncData.value;
      if (state is AuthAuthenticated) return state.token;
      return null;
    },
  ); 
  

  // 3. Điều hướng
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => DashboardDetailScreen(
        dashboard: dashboard,
        token: token,
      ),
    ),
  );
}
}
 
// ---------------------------------------------------------------------------
// DashboardDetailScreen — hiển thị dashboard ThingsBoard qua WebView
// ---------------------------------------------------------------------------
 
class DashboardDetailScreen extends StatefulWidget {
  final Dashboard dashboard;
  final String? token;
 
  const DashboardDetailScreen({
    super.key,
    required this.dashboard,
    this.token,
  });
 
  @override
  State<DashboardDetailScreen> createState() => _DashboardDetailScreenState();
}
 
class _DashboardDetailScreenState extends State<DashboardDetailScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _hasError   = false;
 
  @override
  void initState() {
    super.initState();
    _initWebView();
  }
 
  void _initWebView() {
    // URL ThingsBoard embed dashboard — truyền accessToken để tự đăng nhập
    // Nếu không có token thì TB sẽ hiện trang login của TB
    final token    = widget.token ?? '';
    final dashId   = widget.dashboard.id;
    final baseUrl  = AppConstants.tbBaseUrl;
 
    // ThingsBoard hỗ trợ embed dashboard qua URL:
    // /dashboard/<id>?accessToken=<jwt>
    final embedUrl = '$baseUrl/dashboard/$dashId?accessToken=$token'
        '&hideToolbar=true';
 
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() {
            _isLoading = true;
            _hasError  = false;
          }),
          onPageFinished: (_) => setState(() => _isLoading = false),
          onWebResourceError: (_) => setState(() {
            _isLoading = false;
            _hasError  = true;
          }),
        ),
      )
      ..loadRequest(Uri.parse(embedUrl));
  }
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.dashboard.title,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          // Nút reload
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _isLoading = true;
                _hasError  = false;
              });
              _controller.reload();
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // WebView — luôn render để không mất state
          if (!_hasError) WebViewWidget(controller: _controller),
 
          // Loading overlay
          if (_isLoading && !_hasError)
            const Center(child: CircularProgressIndicator()),
 
          // Error view
          if (_hasError)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.cloud_off,
                        size: 56,
                        color: Theme.of(context).colorScheme.error),
                    const SizedBox(height: 16),
                    const Text('Không tải được dashboard'),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: () {
                        setState(() {
                          _isLoading = true;
                          _hasError  = false;
                        });
                        _controller.reload();
                      },
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text('Thử lại'),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
 
// ---------------------------------------------------------------------------
// _DashboardCard
// ---------------------------------------------------------------------------
 
class _DashboardCard extends StatelessWidget {
  final Dashboard dashboard;
  final VoidCallback onTap;
 
  const _DashboardCard({required this.dashboard, required this.onTap});
 
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
 
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant, width: 0.5),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              // Icon
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.dashboard_outlined,
                  size: 22,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 14),
 
              // Title + ngày tạo
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dashboard.title,
                      style: theme.textTheme.bodyLarge
                          ?.copyWith(fontWeight: FontWeight.w500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (dashboard.createdTime != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        _formatDate(dashboard.createdTime!),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
 
              Icon(Icons.chevron_right,
                  size: 20, color: theme.colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
 
  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
 
// ---------------------------------------------------------------------------
// Skeleton loading
// ---------------------------------------------------------------------------
 
class _DashboardListSkeleton extends StatelessWidget {
  const _DashboardListSkeleton();
 
  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, _) => Container(
        height: 72,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
 
// ---------------------------------------------------------------------------
// Empty / Error views
// ---------------------------------------------------------------------------
 
class _EmptyView extends StatelessWidget {
  const _EmptyView();
 
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.dashboard_outlined,
              size: 56,
              color: Theme.of(context).colorScheme.outlineVariant),
          const SizedBox(height: 16),
          Text('Chưa có dashboard nào',
              style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 6),
          Text(
            'Tạo dashboard trong ThingsBoard rồi quay lại',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}
 
class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});
 
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off,
                size: 56, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 16),
            Text(message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }
}