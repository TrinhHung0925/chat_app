import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../common/app_button.dart';
import '../../common/app_text_field.dart';
import '../../resource/app_colors.dart';
import '../../resource/app_text.dart';
import '../../utils/validators.dart';
import 'login_controller.dart';

class LoginView extends StatefulWidget {
  LoginView({super.key}) {
    if (!Get.isRegistered<LoginController>()) {
      Get.put(LoginController());
    }
  }

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  var controller = Get.find<LoginController>();

  @override
  void dispose() {
    Get.delete<LoginController>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Form(
            key: controller.formKey,
            child: Column(
              children: [
                SizedBox(height: 80.h),
                Icon(
                  Icons.chat_bubble_rounded,
                  size: 72.r,
                  color: AppColors.primary,
                ),
                SizedBox(height: 16.h),
                Text('Chat App', style: AppText.bold(size: 28)),
                SizedBox(height: 8.h),
                Text(
                  'Đăng nhập để bắt đầu trò chuyện',
                  style: AppText.regular(color: AppColors.textSecondary),
                ),
                SizedBox(height: 40.h),
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
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => controller.login(),
                ),
                SizedBox(height: 24.h),
                Obx(
                  () => AppButton(
                    text: 'Đăng nhập',
                    isLoading: controller.isLoading.value,
                    onPressed: controller.login,
                  ),
                ),
                SizedBox(height: 16.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Chưa có tài khoản?',
                      style: AppText.regular(color: AppColors.textSecondary),
                    ),
                    TextButton(
                      onPressed: controller.goToRegister,
                      child: Text(
                        'Đăng ký',
                        style: AppText.bold(color: AppColors.primary),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
