import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../model/post_model.dart';
import '../../service/api_service.dart';

/// Creates a post, or edits the one passed in. Returns the saved post through Get.back.
class PostEditorController extends GetxController {
  final PostModel? editing;
  late final textController = TextEditingController(text: editing?.content);
  final isSaving = false.obs;
  final canSave = false.obs;

  static const maxLength = 2000;

  PostEditorController(this.editing);

  bool get isEditing => editing != null;

  @override
  void onInit() {
    super.onInit();
    textController.addListener(_updateCanSave);
  }

  @override
  void onClose() {
    textController.dispose();
    super.onClose();
  }

  void _updateCanSave() {
    final text = textController.text.trim();
    canSave.value = text.isNotEmpty && text != editing?.content;
  }

  Future<void> save() async {
    if (isSaving.value || !canSave.value) return;
    isSaving.value = true;
    try {
      final content = textController.text.trim();
      final post = isEditing
          ? await ApiService.updatePost(editing!.id, content)
          : await ApiService.createPost(content);
      Get.back(result: post);
    } catch (e) {
      Get.snackbar('Lỗi', e.toString());
    } finally {
      isSaving.value = false;
    }
  }

  void onBack() {
    Get.back();
  }
}
