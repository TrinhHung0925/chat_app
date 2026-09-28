import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../common/post_card.dart';
import '../../common/relationship_button.dart';
import '../../common/user_avatar.dart';
import '../../resource/app_colors.dart';
import '../../resource/app_text.dart';
import 'user_profile_controller.dart';

class UserProfileView extends StatefulWidget {
  final String tag;

  /// [tag] must be unique per open screen: the same person's profile can be in the
  /// navigation stack twice (A → B → A), and each needs its own controller.
  UserProfileView({super.key, required String userId, required this.tag}) {
    if (!Get.isRegistered<UserProfileController>(tag: tag)) {
      Get.put(UserProfileController(userId), tag: tag);
    }
  }

  @override
  State<UserProfileView> createState() => _UserProfileViewState();
}

class _UserProfileViewState extends State<UserProfileView> {
  late var controller = Get.find<UserProfileController>(tag: widget.tag);

  @override
  void dispose() {
    Get.delete<UserProfileController>(tag: widget.tag);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F3F5),
      appBar: AppBar(
        title: Obx(
          () => Text(
            controller.isSelf
                ? 'Trang cá nhân'
                : controller.profile.value?.user.displayName ?? '',
            style: AppText.bold(size: 18),
          ),
        ),
        actions: [
          Obx(
            () => controller.isSelf
                ? IconButton(
                    icon: const Icon(Icons.settings_outlined),
                    tooltip: 'Chỉnh sửa hồ sơ',
                    onPressed: controller.editProfile,
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.error.value != null) {
          return Center(
            child: Text(controller.error.value!, style: AppText.regular()),
          );
        }
        return RefreshIndicator(
          onRefresh: controller.load,
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
                if (index == 0) return _buildHeader();
                if (index == controller.posts.length + 1) return _buildFooter();
                final post = controller.posts[index - 1];
                return PostCard(
                  post: post,
                  isMine: controller.isMine(post),
                  onLike: () => controller.toggleLike(post),
                  onOpen: () => controller.openPost(post),
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

  Widget _buildHeader() {
    final info = controller.profile.value!;
    final user = info.user;
    return Container(
      color: AppColors.white,
      margin: EdgeInsets.only(bottom: 6.h),
      padding: EdgeInsets.symmetric(vertical: 24.h, horizontal: 16.w),
      child: Column(
        children: [
          UserAvatar(userId: user.id, name: user.displayName, size: 88),
          SizedBox(height: 12.h),
          Text(
            user.displayName,
            style: AppText.bold(size: 22),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 4.h),
          Text(
            '@${user.handle}',
            style: AppText.regular(color: AppColors.textSecondary),
          ),
          SizedBox(height: 16.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildCount(info.postCount, 'Bài viết'),
              SizedBox(width: 40.w),
              _buildCount(info.friendCount, 'Bạn bè'),
            ],
          ),
          SizedBox(height: 16.h),
          if (controller.isSelf)
            OutlinedButton.icon(
              onPressed: controller.editProfile,
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Chỉnh sửa hồ sơ'),
            )
          else
            RelationshipButton(
              relationship: info.relationship,
              isBusy: controller.isBusy.value,
              onAdd: controller.addFriend,
              onCancel: controller.cancelRequest,
              onAccept: controller.acceptRequest,
              onDecline: controller.declineRequest,
              onUnfriend: controller.unfriend,
            ),
        ],
      ),
    );
  }

  Widget _buildCount(int value, String label) {
    return Column(
      children: [
        Text('$value', style: AppText.bold(size: 18)),
        Text(
          label,
          style: AppText.regular(size: 13, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    final info = controller.profile.value!;
    String? message;
    if (!info.canSeePosts) {
      message = 'Kết bạn với ${info.user.displayName} để xem bài viết.';
    } else if (controller.posts.isEmpty) {
      message = controller.isSelf
          ? 'Bạn chưa có bài viết nào.'
          : 'Chưa có bài viết nào.';
    }
    if (controller.isLoadingMore.value) {
      return Padding(
        padding: EdgeInsets.all(16.r),
        child: const Center(child: CircularProgressIndicator()),
      );
    }
    if (message == null) return const SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 40.h),
      child: Column(
        children: [
          Icon(
            info.canSeePosts ? Icons.article_outlined : Icons.lock_outline,
            size: 40.r,
            color: AppColors.textSecondary,
          ),
          SizedBox(height: 8.h),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppText.regular(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
