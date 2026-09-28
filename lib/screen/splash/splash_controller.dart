import 'package:get/get.dart';

import '../../route.dart';
import '../../service/local_service.dart';

class SplashController extends GetxController {
  @override
  void onInit() {
    super.onInit();
  }

  @override
  void onReady() {
    super.onReady();
    Future.delayed(const Duration(seconds: 2), () {
      final nextPage = LocalService.isLoggedIn ? AppPage.home : AppPage.login;
      Get.offAllNamed(nextPage.routeName);
    });
  }

  void onBack() {
    Get.back();
  }
}
