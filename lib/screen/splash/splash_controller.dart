import 'package:get/get.dart';

import '../../route.dart';

class SplashController extends GetxController {
  @override
  void onInit() {
    super.onInit();
  }

  @override
  void onReady() {
    super.onReady();
    Future.delayed(const Duration(seconds: 2), () {
      Get.offAllNamed(AppPage.home.routeName);
    });
  }

  void onBack() {
    Get.back();
  }
}
