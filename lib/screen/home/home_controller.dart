import 'package:get/get.dart';

import '../../model/user_model.dart';
import '../../service/api_service.dart';
import '../../service/local_service.dart';
import '../feed/feed_controller.dart';
import '../friends/friends_controller.dart';
import '../user_profile/user_profile_controller.dart';

class HomeController extends GetxController {
  static const meTabTag = 'me-tab';

  final currentTab = 0.obs;
  final user = Rxn<UserModel>(LocalService.user);

  @override
  void onInit() {
    super.onInit();
    refreshMe();
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
        Get.find<FriendsController>().load();
      case 2:
        Get.find<UserProfileController>(tag: meTabTag).load();
    }
  }

  void onBack() {
    Get.back();
  }
}
