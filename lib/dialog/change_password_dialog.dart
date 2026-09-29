import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../common/app_text_field.dart';
import '../resource/app_text.dart';
import '../service/api_service.dart';
import '../utils/validators.dart';

/// Returns true through Get.back when the password was changed.
class ChangePasswordDialog extends StatefulWidget {
  const ChangePasswordDialog({super.key});

  @override
  State<ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<ChangePasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isLoading || !_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      await ApiService.changePassword(
        _currentController.text,
        _newController.text,
      );
      Get.back(result: true);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Đổi mật khẩu', style: AppText.bold(size: 18)),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppTextField(
                controller: _currentController,
                label: 'Mật khẩu hiện tại',
                isPassword: true,
                validator: Validators.password,
              ),
              SizedBox(height: 12.h),
              AppTextField(
                controller: _newController,
                label: 'Mật khẩu mới',
                isPassword: true,
                validator: Validators.password,
              ),
              SizedBox(height: 12.h),
              AppTextField(
                controller: _confirmController,
                label: 'Xác nhận mật khẩu mới',
                isPassword: true,
                validator: Validators.confirmPassword(
                  () => _newController.text,
                ),
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
              ),
              if (_error != null) ...[
                SizedBox(height: 12.h),
                Text(_error!, style: AppText.regular(color: Colors.red)),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Get.back(result: false),
          child: const Text('Hủy'),
        ),
        FilledButton(
          onPressed: _isLoading ? null : _submit,
          child: _isLoading
              ? SizedBox(
                  width: 18.r,
                  height: 18.r,
                  child: const CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Đổi'),
        ),
      ],
    );
  }
}
