import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../common/app_button.dart';
import '../../common/app_text_field.dart';
import '../../resource/app_colors.dart';
import '../../resource/app_text.dart';
import '../../utils/validators.dart';
import 'profile_controller.dart';

class ProfileView extends StatefulWidget {
  ProfileView({super.key}) {
    if (!Get.isRegistered<ProfileController>()) {
      Get.put(ProfileController());
    }
  }

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  var controller = Get.find<ProfileController>();

  @override
  void dispose() {
    Get.delete<ProfileController>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text('Hồ sơ', style: AppText.bold(size: 18))),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24.w),
          child: Form(
            key: controller.formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Obx(() {
                  final user = controller.user.value;
                  return Column(
                    children: [
                      CircleAvatar(
                        radius: 40.r,
                        backgroundColor: AppColors.primary,
                        child: Text(
                          (user?.displayName.isNotEmpty ?? false)
                              ? user!.displayName[0].toUpperCase()
                              : '?',
                          style: AppText.bold(size: 32, color: AppColors.white),
                        ),
                      ),
                      SizedBox(height: 12.h),
                      Text(
                        '@${user?.username ?? ''}',
                        style: AppText.regular(color: AppColors.textSecondary),
                      ),
                    ],
                  );
                }),
                SizedBox(height: 32.h),
                AppTextField(
                  controller: controller.displayNameController,
                  label: 'Tên hiển thị',
                  validator: Validators.displayName,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => controller.saveDisplayName(),
                ),
                SizedBox(height: 16.h),
                Obx(
                  () => AppButton(
                    text: 'Lưu tên',
                    isLoading: controller.isSaving.value,
                    onPressed: controller.saveDisplayName,
                  ),
                ),
                SizedBox(height: 32.h),
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.lock_outline),
                  title: Text('Đổi mật khẩu', style: AppText.medium(size: 15)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: controller.changePassword,
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: Text(
                    'Đăng xuất',
                    style: AppText.medium(size: 15, color: Colors.red),
                  ),
                  onTap: controller.logout,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
