import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../service/local_service.dart';
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
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Bảng tin',
            ),
            NavigationDestination(
              icon: Icon(Icons.people_outline),
              selectedIcon: Icon(Icons.people),
              label: 'Bạn bè',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Tôi',
            ),
          ],
        ),
      ),
    );
  }
}
