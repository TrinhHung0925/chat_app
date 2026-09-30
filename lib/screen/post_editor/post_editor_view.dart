import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../common/user_avatar.dart';
import '../../model/post_model.dart';
import '../../resource/app_text.dart';
import '../../service/local_service.dart';
import 'post_editor_controller.dart';

class PostEditorView extends StatefulWidget {
  PostEditorView({super.key, PostModel? post}) {
    if (!Get.isRegistered<PostEditorController>()) {
      Get.put(PostEditorController(post));
    }
  }

  @override
  State<PostEditorView> createState() => _PostEditorViewState();
}

class _PostEditorViewState extends State<PostEditorView> {
  var controller = Get.find<PostEditorController>();

  @override
  void dispose() {
    Get.delete<PostEditorController>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final me = LocalService.user;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          controller.isEditing ? 'Sửa bài viết' : 'Tạo bài viết',
          style: AppText.bold(size: 18),
        ),
        actions: [
          Obx(
            () => Padding(
              padding: EdgeInsets.only(right: 8.w),
              child: controller.isSaving.value
                  ? Padding(
                      padding: EdgeInsets.all(14.r),
                      child: SizedBox(
                        width: 20.r,
                        height: 20.r,
                        child: const CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : FilledButton(
                      onPressed:
                          controller.canSave.value ? controller.save : null,
                      child: Text(controller.isEditing ? 'Lưu' : 'Đăng'),
                    ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                UserAvatar(userId: me?.id ?? '', name: me?.displayName ?? ''),
                SizedBox(width: 10.w),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(me?.displayName ?? '', style: AppText.bold(size: 15)),
                    Text('Bạn bè', style: AppText.regular(size: 12)),
                  ],
                ),
              ],
            ),
            SizedBox(height: 12.h),
            Expanded(
              child: TextField(
                controller: controller.textController,
                autofocus: true,
                maxLines: null,
                expands: true,
                maxLength: PostEditorController.maxLength,
                textAlignVertical: TextAlignVertical.top,
                style: AppText.regular(size: 17),
                decoration: const InputDecoration(
                  hintText: 'Bạn đang nghĩ gì?',
                  border: InputBorder.none,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
