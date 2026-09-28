import 'dart:async';

import 'package:get/get.dart';

import '../../model/notification_model.dart';
import '../../model/user_model.dart';
import '../../service/api_service.dart';
import '../../service/local_service.dart';
import '../../service/realtime_service.dart';
import '../chat_list/chat_list_controller.dart';
import '../feed/feed_controller.dart';
import '../friends/friends_controller.dart';
import '../user_profile/user_profile_controller.dart';

class HomeController extends GetxController {
  static const meTabTag = 'me-tab';

  final currentTab = 0.obs;
  final user = Rxn<UserModel>(LocalService.user);
  StreamSubscription<NotificationModel>? _live;

  @override
  void onInit() {
    super.onInit();
    refreshMe();
    // Home exists exactly while the user is signed in, so the live connection follows it.
    RealtimeService.instance.start();
    _live = RealtimeService.instance.notifications.listen(_onNotification);
  }

  @override
  void onClose() {
    _live?.cancel();
    RealtimeService.instance.stop();
    super.onClose();
  }

  /// Refresh what the notification changes, so the friends tab badge and lists are current.
  void _onNotification(NotificationModel n) {
    if (Get.isRegistered<FriendsController>()) {
      Get.find<FriendsController>().load();
    }
    if (n.type == NotificationType.friendAccepted &&
        Get.isRegistered<FeedController>()) {
      Get.find<FeedController>().refreshFeed();
    }
  }

  Future<void> refreshMe() async {
    try {
      final me = await ApiService.getMe();
      user.value = me;
      await LocalService.saveUser(me);
    } on ApiException {
      // Keep the cached user; a 401 is already handled by the Dio interceptor.
    }
  }

  /// Each tab reloads when it is opened, so e.g. a post written in the feed shows on "Tôi".
  void selectTab(int index) {
    if (index == currentTab.value) return;
    currentTab.value = index;
    switch (index) {
      case 0:
        Get.find<FeedController>().refreshFeed();
      case 1:
        Get.find<ChatListController>().load();
      case 2:
        Get.find<FriendsController>().load();
      case 3:
        Get.find<UserProfileController>(tag: meTabTag).load();
    }
  }

  void onBack() {
    Get.back();
  }
}
