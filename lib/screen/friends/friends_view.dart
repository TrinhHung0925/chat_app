import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../common/notification_bell.dart';
import '../../common/user_avatar.dart';
import '../../model/friend_request_model.dart';
import '../../model/user_model.dart';
import '../../resource/app_colors.dart';
import '../../resource/app_text.dart';
import '../../utils/time_ago.dart';
import 'friends_controller.dart';

class FriendsView extends StatefulWidget {
  FriendsView({super.key}) {
    if (!Get.isRegistered<FriendsController>()) {
      Get.put(FriendsController());
    }
  }

  @override
  State<FriendsView> createState() => _FriendsViewState();
}

class _FriendsViewState extends State<FriendsView> {
  var controller = Get.find<FriendsController>();

  @override
  void dispose() {
    Get.delete<FriendsController>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Bạn bè', style: AppText.bold(size: 20)),
          actions: [
            IconButton(
              icon: const Icon(Icons.person_search),
              tooltip: 'Tìm bạn',
              onPressed: controller.openSearch,
            ),
            const NotificationBell(),
          ],
          bottom: TabBar(
            tabs: [
              Obx(() => Tab(text: 'Bạn bè (${controller.friends.length})')),
              Obx(() => Tab(text: 'Lời mời (${controller.incoming.length})')),
            ],
          ),
        ),
        body: Obx(() {
          if (controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }
          return TabBarView(children: [_buildFriends(), _buildRequests()]);
        }),
      ),
    );
  }

  Widget _buildFriends() {
    return RefreshIndicator(
      onRefresh: controller.load,
      child: controller.friends.isEmpty
          ? _buildEmpty(
              'Chưa có bạn bè nào.\nBấm biểu tượng tìm kiếm để tìm bạn theo mã.',
            )
          : ListView(
              children: controller.friends.map(_buildFriendTile).toList(),
            ),
    );
  }

  Widget _buildFriendTile(UserModel user) {
    return ListTile(
      leading: UserAvatar(userId: user.id, name: user.displayName),
      title: Text(user.displayName, style: AppText.medium(size: 15)),
      subtitle: Text(
        '@${user.handle}',
        style: AppText.regular(size: 13, color: AppColors.textSecondary),
      ),
      onTap: () => controller.openUser(user),
      trailing: PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert),
        onSelected: (_) => controller.unfriend(user),
        itemBuilder: (_) => const [
          PopupMenuItem(value: 'unfriend', child: Text('Hủy kết bạn')),
        ],
      ),
    );
  }

  Widget _buildRequests() {
    return RefreshIndicator(
      onRefresh: controller.load,
      child: controller.incoming.isEmpty && controller.outgoing.isEmpty
          ? _buildEmpty('Không có lời mời nào.')
          : ListView(
              children: [
                if (controller.incoming.isNotEmpty)
                  _buildSection('Lời mời kết bạn'),
                ...controller.incoming.map(
                  (r) => _buildRequestTile(r, incoming: true),
                ),
                if (controller.outgoing.isNotEmpty) _buildSection('Đã gửi'),
                ...controller.outgoing.map(
                  (r) => _buildRequestTile(r, incoming: false),
                ),
              ],
            ),
    );
  }

  Widget _buildSection(String title) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 4.h),
      child: Text(
        title,
        style: AppText.bold(size: 14, color: AppColors.textSecondary),
      ),
    );
  }

  Widget _buildRequestTile(
    FriendRequestModel request, {
    required bool incoming,
  }) {
    final busy = controller.busyIds.contains(request.id);
    return ListTile(
      leading: UserAvatar(
        userId: request.user.id,
        name: request.user.displayName,
      ),
      title: Text(request.user.displayName, style: AppText.medium(size: 15)),
      subtitle: Text(
        '@${request.user.handle} · ${timeAgo(request.createdAt)}',
        style: AppText.regular(size: 13, color: AppColors.textSecondary),
      ),
      onTap: () => controller.openUser(request.user),
      trailing: busy
          ? SizedBox(
              width: 24.r,
              height: 24.r,
              child: const CircularProgressIndicator(strokeWidth: 2),
            )
          : incoming
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton.filled(
                      icon: const Icon(Icons.check),
                      tooltip: 'Chấp nhận',
                      onPressed: () => controller.accept(request),
                    ),
                    IconButton.outlined(
                      icon: const Icon(Icons.close),
                      tooltip: 'Từ chối',
                      onPressed: () => controller.decline(request),
                    ),
                  ],
                )
              : TextButton(
                  onPressed: () => controller.cancel(request),
                  child: const Text('Hủy'),
                ),
    );
  }

  Widget _buildEmpty(String message) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 80.h),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: AppText.regular(color: AppColors.textSecondary),
          ),
        ),
      ],
    );
  }
}
