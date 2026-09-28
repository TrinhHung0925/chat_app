import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../resource/app_colors.dart';
import '../../resource/app_text.dart';
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
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            children: [
              const Spacer(),
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
              const Spacer(),
              _buildGoogleButton(),
              SizedBox(height: 32.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGoogleButton() {
    return Obx(
      () => SizedBox(
        width: double.infinity,
        height: 52.h,
        child: OutlinedButton(
          onPressed: controller.isLoading.value
              ? null
              : controller.loginWithGoogle,
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: AppColors.textSecondary),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
          ),
          child: controller.isLoading.value
              ? SizedBox(
                  width: 22.r,
                  height: 22.r,
                  child: const CircularProgressIndicator(strokeWidth: 2),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'G',
                      style: AppText.bold(size: 20, color: AppColors.primary),
                    ),
                    SizedBox(width: 12.w),
                    Text(
                      'Đăng nhập bằng Google',
                      style: AppText.medium(size: 16),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
