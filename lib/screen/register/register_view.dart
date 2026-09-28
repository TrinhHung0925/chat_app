import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../common/app_button.dart';
import '../../common/app_text_field.dart';
import '../../resource/app_colors.dart';
import '../../resource/app_text.dart';
import '../../utils/validators.dart';
import 'register_controller.dart';

class RegisterView extends StatefulWidget {
  RegisterView({super.key}) {
    if (!Get.isRegistered<RegisterController>()) {
      Get.put(RegisterController());
    }
  }

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  var controller = Get.find<RegisterController>();

  @override
  void dispose() {
    Get.delete<RegisterController>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text('Đăng ký', style: AppText.bold(size: 18))),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Form(
            key: controller.formKey,
            child: Column(
              children: [
                SizedBox(height: 24.h),
                AppTextField(
                  controller: controller.usernameController,
                  label: 'Tên đăng nhập',
                  validator: Validators.username,
                ),
                SizedBox(height: 16.h),
                AppTextField(
                  controller: controller.passwordController,
                  label: 'Mật khẩu',
                  isPassword: true,
                  validator: Validators.password,
                ),
                SizedBox(height: 16.h),
                AppTextField(
                  controller: controller.confirmPasswordController,
                  label: 'Xác nhận mật khẩu',
                  isPassword: true,
                  validator: Validators.confirmPassword(
                    () => controller.passwordController.text,
                  ),
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => controller.register(),
                ),
                SizedBox(height: 24.h),
                Obx(
                  () => AppButton(
                    text: 'Đăng ký',
                    isLoading: controller.isLoading.value,
                    onPressed: controller.register,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
