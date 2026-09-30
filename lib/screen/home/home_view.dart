import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../service/local_service.dart';
import '../friends/friends_controller.dart';
import '../chat_list/chat_list_controller.dart';
import '../chat_list/chat_list_view.dart';
import '../feed/feed_view.dart';
import '../friends/friends_view.dart';
import '../user_profile/user_profile_view.dart';
import 'home_controller.dart';

class HomeView extends StatefulWidget {
  HomeView({super.key}) {
    if (!Get.isRegistered<HomeController>()) {
      Get.put(HomeController());
    }
  }

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  var controller = Get.find<HomeController>();

  // Built once and kept alive by the IndexedStack, so switching tabs keeps scroll positions.
  late final List<Widget> _tabs = [
    FeedView(),
    ChatListView(),
    FriendsView(),
    UserProfileView(
      userId: LocalService.user!.id,
      tag: HomeController.meTabTag,
    ),
  ];

  @override
  void dispose() {
    Get.delete<HomeController>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Scaffold(
        body: IndexedStack(index: controller.currentTab.value, children: _tabs),
        bottomNavigationBar: NavigationBar(
          selectedIndex: controller.currentTab.value,
          onDestinationSelected: controller.selectTab,
          destinations: [
            const NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Bảng tin',
            ),
            NavigationDestination(
              icon: _chatIcon(Icons.chat_bubble_outline),
              selectedIcon: _chatIcon(Icons.chat_bubble),
              label: 'Chat',
            ),
            NavigationDestination(
              icon: _friendsIcon(Icons.people_outline),
              selectedIcon: _friendsIcon(Icons.people),
              label: 'Bạn bè',
            ),
            const NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Tôi',
            ),
          ],
        ),
      ),
    );
  }

  /// The friends tab shows how many requests are waiting.
  // Tab Chat hiện tổng số tin chưa đọc.
  Widget _chatIcon(IconData icon) {
    final count = Get.isRegistered<ChatListController>()
        ? Get.find<ChatListController>().totalUnread
        : 0;
    return Badge(
      isLabelVisible: count > 0,
      label: Text('$count'),
      child: Icon(icon),
    );
  }

  Widget _friendsIcon(IconData icon) {
    final count = Get.isRegistered<FriendsController>()
        ? Get.find<FriendsController>().incoming.length
        : 0;
    return Badge(
      isLabelVisible: count > 0,
      label: Text('$count'),
      child: Icon(icon),
    );
  }
}
