import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/dio_client.dart';
import 'dashboard_model.dart';
import 'tb_dashboard_service.dart';

final tbDashboardServiceProvider = Provider<TbDashboardService>((ref) {
  return TbDashboardService(ref.read(dioClientProvider).dio);
});
 
final dashboardsProvider =
    AsyncNotifierProvider<DashboardsNotifier, List<Dashboard>>(
        DashboardsNotifier.new);
 
class DashboardsNotifier extends AsyncNotifier<List<Dashboard>> {
  @override
  Future<List<Dashboard>> build() => _fetch();
 
  Future<List<Dashboard>> _fetch() =>
      ref.read(tbDashboardServiceProvider).getDashboards();
 
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }
}