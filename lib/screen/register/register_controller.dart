import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../route.dart';
import '../../service/api_service.dart';
import '../../service/local_service.dart';

class RegisterController extends GetxController {
  final formKey = GlobalKey<FormState>();
  final displayNameController = TextEditingController();
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final isLoading = false.obs;

  @override
  void onClose() {
    displayNameController.dispose();
    usernameController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }

  /// "Confirm password" is only checked here; the backend just needs the password once.
  Future<void> register() async {
    if (isLoading.value || !formKey.currentState!.validate()) return;
    isLoading.value = true;
    try {
      final session = await ApiService.register(
        usernameController.text.trim(),
        passwordController.text,
        displayNameController.text.trim(),
      );
      await LocalService.saveSession(session.accessToken, session.user);
      Get.offAllNamed(AppPage.home.routeName);
    } on ApiException catch (e) {
      Get.snackbar('Đăng ký thất bại', e.message);
    } finally {
      isLoading.value = false;
    }
  }

  void onBack() {
    Get.back();
  }
}
