import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../dialog/change_password_dialog.dart';
import '../../model/user_model.dart';
import '../../route.dart';
import '../../service/api_service.dart';
import '../../service/local_service.dart';

class ProfileController extends GetxController {
  final formKey = GlobalKey<FormState>();
  final user = Rxn<UserModel>(LocalService.user);
  late final displayNameController = TextEditingController(
    text: user.value?.displayName,
  );
  final isSaving = false.obs;

  @override
  void onClose() {
    displayNameController.dispose();
    super.onClose();
  }

  Future<void> saveDisplayName() async {
    if (isSaving.value || !formKey.currentState!.validate()) return;
    isSaving.value = true;
    try {
      final updated = await ApiService.updateDisplayName(
        displayNameController.text.trim(),
      );
      user.value = updated;
      await LocalService.saveUser(updated);
      Get.snackbar('Thành công', 'Đã đổi tên hiển thị');
    } on ApiException catch (e) {
      Get.snackbar('Lỗi', e.message);
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> changePassword() async {
    final changed = await Get.dialog<bool>(const ChangePasswordDialog());
    if (changed == true) Get.snackbar('Thành công', 'Đã đổi mật khẩu');
  }

  Future<void> logout() async {
    await LocalService.logout();
    Get.offAllNamed(AppPage.login.routeName);
  }

  void onBack() {
    Get.back();
  }
}
