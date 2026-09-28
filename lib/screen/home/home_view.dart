import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../resource/app_colors.dart';
import '../../resource/app_text.dart';
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

  @override
  void dispose() {
    Get.delete<HomeController>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Chat App', style: AppText.bold(size: 18)),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle),
            onPressed: controller.openProfile,
          ),
        ],
      ),
      body: Center(
        child: Obx(
          () => Text(
            'Xin chào, ${controller.user.value?.displayName ?? ''}',
            style: AppText.medium(size: 18),
            textAlign: TextAlign.center,
          ),
        ),
      ),
      // Room list and chat come in the next phases.
    );
  }
}
