import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../common/post_card.dart';
import '../../common/user_avatar.dart';
import '../../resource/app_colors.dart';
import '../../resource/app_text.dart';
import '../../service/local_service.dart';
import 'feed_controller.dart';

class FeedView extends StatefulWidget {
  FeedView({super.key}) {
    if (!Get.isRegistered<FeedController>()) {
      Get.put(FeedController());
    }
  }

  @override
  State<FeedView> createState() => _FeedViewState();
}

class _FeedViewState extends State<FeedView> {
  var controller = Get.find<FeedController>();

  @override
  void dispose() {
    Get.delete<FeedController>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F3F5),
      appBar: AppBar(title: Text('Bảng tin', style: AppText.bold(size: 20))),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        return RefreshIndicator(
          onRefresh: controller.refreshFeed,
          child: NotificationListener<ScrollNotification>(
            onNotification: (n) {
              if (n.metrics.extentAfter < 300) controller.loadMore();
              return false;
            },
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.only(bottom: 16.h),
              itemCount: controller.posts.length + 2,
              itemBuilder: (context, index) {
                if (index == 0) return _buildComposer();
                if (index == controller.posts.length + 1) return _buildFooter();
                final post = controller.posts[index - 1];
                return PostCard(
                  post: post,
                  isMine: controller.isMine(post),
                  onLike: () => controller.toggleLike(post),
                  onOpen: () => controller.openPost(post),
                  onOpenAuthor: () => controller.openAuthor(post),
                  onEdit: () => controller.editPost(post),
                  onDelete: () => controller.deletePost(post),
                );
              },
            ),
          ),
        );
      }),
    );
  }

  Widget _buildComposer() {
    final me = LocalService.user;
    return Card(
      margin: EdgeInsets.fromLTRB(12.w, 12.h, 12.w, 6.h),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12.r),
        onTap: controller.createPost,
        child: Padding(
          padding: EdgeInsets.all(12.r),
          child: Row(
            children: [
              UserAvatar(userId: me?.id ?? '', name: me?.displayName ?? ''),
              SizedBox(width: 12.w),
              Expanded(
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 10.h,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2F3F5),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Text(
                    'Bạn đang nghĩ gì?',
                    style: AppText.regular(color: AppColors.textSecondary),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    if (controller.isLoadingMore.value) {
      return Padding(
        padding: EdgeInsets.all(16.r),
        child: const Center(child: CircularProgressIndicator()),
      );
    }
    if (controller.posts.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 48.h),
        child: Text(
          'Chưa có bài viết nào.\nHãy viết bài đầu tiên hoặc kết bạn để xem bài của bạn bè.',
          textAlign: TextAlign.center,
          style: AppText.regular(color: AppColors.textSecondary),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}
