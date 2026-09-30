import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../dialog/change_password_dialog.dart';
import '../../model/user_model.dart';
import '../../route.dart';
import '../../service/api_service.dart';
import '../../service/local_service.dart';
import '../../service/push_service.dart';
import '../../utils/validators.dart';

class ProfileController extends GetxController {
  final formKey = GlobalKey<FormState>();
  final user = Rxn<UserModel>(LocalService.user);
  late final displayNameController = TextEditingController(
    text: user.value?.displayName,
  );
  late final handleController = TextEditingController(text: user.value?.handle);
  final isSaving = false.obs;

  @override
  void onClose() {
    displayNameController.dispose();
    handleController.dispose();
    super.onClose();
  }

  /// Sends only the fields that changed, so an unchanged handle is not re-checked for uniqueness.
  Future<void> saveProfile() async {
    if (isSaving.value || !formKey.currentState!.validate()) return;
    final current = user.value;
    final displayName = displayNameController.text.trim();
    final handle = Validators.normalizeHandle(handleController.text);
    final nameChanged = displayName != current?.displayName;
    final handleChanged = handle != current?.handle;
    if (!nameChanged && !handleChanged) return;

    isSaving.value = true;
    try {
      final updated = await ApiService.updateProfile(
        displayName: nameChanged ? displayName : null,
        handle: handleChanged ? handle : null,
      );
      user.value = updated;
      handleController.text = updated.handle;
      await LocalService.saveUser(updated);
      Get.snackbar('Thành công', 'Đã lưu hồ sơ');
    } catch (e) {
      Get.snackbar('Lỗi', e.toString());
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> changePassword() async {
    final changed = await Get.dialog<bool>(const ChangePasswordDialog());
    if (changed == true) Get.snackbar('Thành công', 'Đã đổi mật khẩu');
  }

  Future<void> logout() async {
    // Xóa token push TRƯỚC khi xóa phiên đăng nhập, vì gọi server cần token đăng nhập.
    await PushService.instance.stop();
    await LocalService.logout();
    Get.offAllNamed(AppPage.login.routeName);
  }

  void onBack() {
    Get.back();
  }
}
