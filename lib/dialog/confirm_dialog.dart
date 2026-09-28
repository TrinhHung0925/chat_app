import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../resource/app_text.dart';

/// Resolves to true when the user confirms.
Future<bool> showConfirmDialog({
  required String title,
  required String message,
  String confirmText = 'Đồng ý',
  bool isDestructive = false,
}) async {
  final result = await Get.dialog<bool>(
    AlertDialog(
      title: Text(title, style: AppText.bold(size: 18)),
      content: Text(message, style: AppText.regular(size: 15)),
      actions: [
        TextButton(
          onPressed: () => Get.back(result: false),
          child: const Text('Hủy'),
        ),
        FilledButton(
          style: isDestructive
              ? FilledButton.styleFrom(backgroundColor: Colors.red)
              : null,
          onPressed: () => Get.back(result: true),
          child: Text(confirmText),
        ),
      ],
    ),
  );
  return result ?? false;
}
