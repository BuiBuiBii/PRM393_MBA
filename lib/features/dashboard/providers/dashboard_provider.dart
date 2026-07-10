import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/demo/demo_service.dart';
import '../../../core/network/api_utils.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/app_api.dart';
import '../../../core/network/app_api_provider.dart';
class DashboardState {
  const DashboardState({this.payload, this.isLoading = false, this.error});
  final Map<String, dynamic>? payload;
  final bool isLoading;
  final String? error;
}

class DashboardNotifier extends Notifier<DashboardState> {
  late AppApi _api;

  @override
  DashboardState build() {
    _api = ref.read(appApiProvider);
    return const DashboardState();
  }

  Future<void> load() async {
    state = const DashboardState(isLoading: true);
    try {
      final payload = AppConfig.demoMode
          ? await DemoService.instance.dashboardMe()
          : await safeRequest(_api.dashboardMe);
      state = DashboardState(payload: payload);
    } catch (e) {
      state = DashboardState(error: getApiErrorMessage(e));
    }
  }
}

final dashboardProvider = NotifierProvider<DashboardNotifier, DashboardState>(DashboardNotifier.new);
