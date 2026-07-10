import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/demo/demo_service.dart';
import '../../../core/network/api_utils.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/app_api.dart';
import '../../../core/network/app_api_provider.dart';
import '../../../shared/models/app_models.dart';
class NotificationState {
  const NotificationState({this.items = const [], this.isLoading = false, this.error});
  final List<NotificationModel> items;
  final bool isLoading;
  final String? error;
}

class NotificationNotifier extends Notifier<NotificationState> {
  late AppApi _api;

  @override
  NotificationState build() {
    _api = ref.read(appApiProvider);
    return const NotificationState();
  }

  Future<void> load({bool unreadOnly = false, String? type}) async {
    state = const NotificationState(isLoading: true);
    try {
      final items = AppConfig.demoMode
          ? await DemoService.instance.getNotifications(unreadOnly: unreadOnly, type: type)
          : await safeRequest(() => _api.getNotifications(unreadOnly: unreadOnly, type: type));
      state = NotificationState(items: items);
    } catch (e) {
      state = NotificationState(error: getApiErrorMessage(e));
    }
  }

  Future<void> create(String title, String message, String type) async {
    if (AppConfig.demoMode) {
      await DemoService.instance.createNotification(title: title, message: message, type: type);
    } else {
      await safeRequest(() => _api.createNotification(title: title, message: message, type: type));
    }
    await load();
  }

  Future<void> markRead(String id) async {
    if (AppConfig.demoMode) {
      await DemoService.instance.markNotificationRead(id);
    } else {
      await safeRequest(() => _api.markNotificationRead(id));
    }
    await load();
  }

  Future<void> remove(String id) async {
    if (AppConfig.demoMode) {
      await DemoService.instance.deleteNotification(id);
    } else {
      await safeRequest(() => _api.deleteNotification(id));
    }
    await load();
  }
}

final notificationProvider = NotifierProvider<NotificationNotifier, NotificationState>(NotificationNotifier.new);
