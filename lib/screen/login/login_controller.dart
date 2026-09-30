import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../route.dart';
import '../../service/api_service.dart';
import '../../service/local_service.dart';

class LoginController extends GetxController {
  final formKey = GlobalKey<FormState>();
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  final isLoading = false.obs;

  @override
  void onClose() {
    usernameController.dispose();
    passwordController.dispose();
    super.onClose();
  }

  Future<void> login() async {
    if (isLoading.value || !formKey.currentState!.validate()) return;
    isLoading.value = true;
    try {
      final session = await ApiService.login(
        usernameController.text.trim(),
        passwordController.text,
      );
      await LocalService.saveSession(session.accessToken, session.user);
      Get.offAllNamed(AppPage.home.routeName);
    } catch (e) {
      Get.snackbar('Đăng nhập thất bại', e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  void goToRegister() {
    Get.toNamed(AppPage.register.routeName);
  }

  void onBack() {
    Get.back();
  }
}
