import 'dart:async';

import 'package:get/get.dart';

import '../../model/notification_model.dart';
import '../../route.dart';
import '../../service/api_service.dart';
import '../../service/realtime_service.dart';

class NotificationsController extends GetxController {
  final items = <NotificationModel>[].obs;
  final isLoading = true.obs;
  StreamSubscription<NotificationModel>? _live;

  @override
  void onInit() {
    super.onInit();
    load();
    // A new one arriving while this screen is open is added on top.
    _live = RealtimeService.instance.notifications.listen((_) => load());
  }

  @override
  void onClose() {
    _live?.cancel();
    super.onClose();
  }

  /// Opening the list counts as reading everything in it. The items keep their unread look
  /// for this visit, so the user can still tell which ones are new.
  Future<void> load() async {
    try {
      final result = await ApiService.getNotifications();
      items.assignAll(result.items);
      if (result.unreadCount > 0) {
        await ApiService.markAllNotificationsRead();
      }
      RealtimeService.instance.unreadCount.value = 0;
    } on ApiException catch (e) {
      Get.snackbar('Lỗi', e.message);
    } finally {
      isLoading.value = false;
    }
  }

  void open(NotificationModel n) {
    Get.toNamed(AppPage.userProfile.routeName, arguments: n.actor.id);
  }

  void onBack() {
    Get.back();
  }
}
