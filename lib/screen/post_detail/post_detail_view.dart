import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../common/post_card.dart';
import '../../common/user_avatar.dart';
import '../../model/comment_model.dart';
import '../../model/post_model.dart';
import '../../resource/app_colors.dart';
import '../../resource/app_text.dart';
import '../../utils/time_ago.dart';
import 'post_detail_controller.dart';

class PostDetailView extends StatefulWidget {
  /// Unique per opened screen, so a post opened twice in the stack gets two controllers.
  final String tag;

  PostDetailView({super.key, required PostModel post, required this.tag}) {
    if (!Get.isRegistered<PostDetailController>(tag: tag)) {
      Get.put(PostDetailController(post), tag: tag);
    }
  }

  @override
  State<PostDetailView> createState() => _PostDetailViewState();
}

class _PostDetailViewState extends State<PostDetailView> {
  late var controller = Get.find<PostDetailController>(tag: widget.tag);

  @override
  void dispose() {
    Get.delete<PostDetailController>(tag: widget.tag);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) controller.onBack();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF2F3F5),
        appBar: AppBar(title: Text('Bài viết', style: AppText.bold(size: 18))),
        body: Column(
          children: [
            Expanded(
              child: Obx(() {
                final post = controller.post.value!;
                return ListView(
                  padding: EdgeInsets.only(bottom: 12.h),
                  children: [
                    PostCard(
                      post: post,
                      isMine: controller.isMyPost,
                      onLike: controller.toggleLike,
                      onOpenAuthor: () => controller.openUser(post.author.id),
                      onEdit: controller.editPost,
                      onDelete: controller.deletePost,
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 4.h),
                      child: Text('Bình luận', style: AppText.bold(size: 15)),
                    ),
                    if (controller.isLoading.value)
                      Padding(
                        padding: EdgeInsets.all(16.r),
                        child: const Center(child: CircularProgressIndicator()),
                      )
                    else if (controller.comments.isEmpty)
                      Padding(
                        padding: EdgeInsets.all(16.r),
                        child: Text(
                          'Chưa có bình luận nào. Hãy là người đầu tiên!',
                          style: AppText.regular(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      )
                    else
                      ...controller.comments.map(_buildComment),
                  ],
                );
              }),
            ),
            _buildInput(),
          ],
        ),
      ),
    );
  }

  Widget _buildComment(CommentModel comment) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => controller.openUser(comment.author.id),
            child: UserAvatar(
              userId: comment.author.id,
              name: comment.author.displayName,
              size: 34,
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: GestureDetector(
              onLongPress: controller.canDeleteComment(comment)
                  ? () => controller.deleteComment(comment)
                  : null,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 8.h,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          comment.author.displayName,
                          style: AppText.bold(size: 13),
                        ),
                        SizedBox(height: 2.h),
                        Text(comment.content, style: AppText.regular(size: 14)),
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(left: 12.w, top: 2.h),
                    child: Text(
                      controller.canDeleteComment(comment)
                          ? '${timeAgo(comment.createdAt)} · giữ để xóa'
                          : timeAgo(comment.createdAt),
                      style: AppText.regular(
                        size: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInput() {
    return SafeArea(
      top: false,
      child: Container(
        color: AppColors.white,
        padding: EdgeInsets.fromLTRB(12.w, 8.h, 4.w, 8.h),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller.commentController,
                minLines: 1,
                maxLines: 4,
                maxLength: 1000,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => controller.sendComment(),
                style: AppText.regular(size: 15),
                decoration: InputDecoration(
                  hintText: 'Viết bình luận...',
                  counterText: '',
                  isDense: true,
                  filled: true,
                  fillColor: const Color(0xFFF2F3F5),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 14.w,
                    vertical: 10.h,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20.r),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            Obx(
              () => IconButton(
                onPressed: controller.isSending.value
                    ? null
                    : controller.sendComment,
                icon: Icon(Icons.send, color: AppColors.primary, size: 24.r),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
