import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../common/notification_bell.dart';
import '../../common/user_avatar.dart';
import '../../model/conversation_model.dart';
import '../../resource/app_colors.dart';
import '../../resource/app_text.dart';
import '../../utils/time_ago.dart';
import 'chat_list_controller.dart';

class ChatListView extends StatefulWidget {
  ChatListView({super.key}) {
    if (!Get.isRegistered<ChatListController>()) {
      Get.put(ChatListController());
    }
  }

  @override
  State<ChatListView> createState() => _ChatListViewState();
}

class _ChatListViewState extends State<ChatListView> {
  var controller = Get.find<ChatListController>();

  @override
  void dispose() {
    Get.delete<ChatListController>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tin nhắn', style: AppText.bold(size: 20)),
        actions: const [NotificationBell()],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        return RefreshIndicator(
          onRefresh: controller.load,
          child: controller.conversations.isEmpty
              ? _buildEmpty()
              : ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: controller.conversations.length,
                  itemBuilder: (context, i) =>
                      _buildTile(controller.conversations[i]),
                ),
        );
      }),
    );
  }

  Widget _buildTile(ConversationModel c) {
    final unread = c.unreadCount > 0;
    final prefix = c.lastSenderId == controller.meId ? 'Bạn: ' : '';
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
      leading: _buildAvatar(c),
      title: Text(
        c.other.displayName,
        style: unread ? AppText.bold(size: 16) : AppText.medium(size: 16),
      ),
      subtitle: Text(
        '$prefix${c.lastMessageText ?? ''}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        // Chưa đọc thì chữ đậm và đen, giống Messenger.
        style: unread
            ? AppText.bold(size: 14)
            : AppText.regular(size: 14, color: AppColors.textSecondary),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (c.lastMessageAt != null)
            Text(
              timeAgo(c.lastMessageAt!),
              style: AppText.regular(size: 12, color: AppColors.textSecondary),
            ),
          if (unread) ...[
            SizedBox(height: 4.h),
            Badge(label: Text('${c.unreadCount}')),
          ],
        ],
      ),
      onTap: () => controller.open(c),
    );
  }

  // Avatar kèm chấm xanh ở góc dưới bên phải khi người kia đang hoạt động.
  Widget _buildAvatar(ConversationModel c) {
    final avatar =
        UserAvatar(userId: c.other.id, name: c.other.displayName, size: 50);
    if (!c.presence.online) return avatar;
    return Stack(
      children: [
        avatar,
        Positioned(
          right: 0,
          bottom: 0,
          child: Container(
            width: 14.r,
            height: 14.r,
            decoration: BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
              // Viền trắng để chấm tách khỏi màu avatar.
              border: Border.all(color: AppColors.white, width: 2.r),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmpty() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: 120.h),
        Icon(Icons.forum_outlined, size: 64.r, color: AppColors.textSecondary),
        SizedBox(height: 12.h),
        Text(
          'Chưa có cuộc trò chuyện nào',
          textAlign: TextAlign.center,
          style: AppText.bold(size: 17),
        ),
        SizedBox(height: 6.h),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 32.w),
          child: Text(
            'Vào trang cá nhân của một người bạn và bấm "Nhắn tin" để bắt đầu.',
            textAlign: TextAlign.center,
            style: AppText.regular(color: AppColors.textSecondary),
          ),
        ),
      ],
    );
  }
}
