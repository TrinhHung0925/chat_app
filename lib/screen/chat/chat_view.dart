import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../common/user_avatar.dart';
import '../../model/chat_message_model.dart';
import '../../model/user_model.dart';
import '../../resource/app_colors.dart';
import '../../resource/app_text.dart';
import '../../service/chat_realtime_service.dart';
import 'chat_controller.dart';

class ChatView extends StatefulWidget {
  final String tag;

  ChatView({super.key, required UserModel other, required this.tag}) {
    if (!Get.isRegistered<ChatController>(tag: tag)) {
      Get.put(ChatController(other), tag: tag);
    }
  }

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  late var controller = Get.find<ChatController>(tag: widget.tag);

  @override
  void dispose() {
    Get.delete<ChatController>(tag: widget.tag);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final other = controller.other;
    return Scaffold(
      backgroundColor: const Color(0xFFF2F3F5),
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            UserAvatar(userId: other.id, name: other.displayName, size: 36),
            SizedBox(width: 10.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(other.displayName, style: AppText.bold(size: 16)),
                  Obx(() => _buildConnectionText()),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(child: Obx(_buildMessages)),
          _buildInput(),
        ],
      ),
    );
  }

  Widget _buildConnectionText() {
    // Đang kết nối bình thường mà người kia gõ thì ưu tiên hiện "đang nhập...".
    if (controller.otherIsTyping.value &&
        controller.connection.value == ChatConnectionState.connected) {
      return Text(
        'đang nhập...',
        style: AppText.regular(size: 12, color: AppColors.primary),
      );
    }
    final (text, color) = switch (controller.connection.value) {
      ChatConnectionState.connecting => (
          'Đang kết nối...',
          AppColors.textSecondary
        ),
      ChatConnectionState.connected => ('Đã kết nối', Colors.green),
      ChatConnectionState.disconnected => ('Mất kết nối', Colors.red),
    };
    return Text(text, style: AppText.regular(size: 12, color: color));
  }

  Widget _buildMessages() {
    if (controller.connection.value == ChatConnectionState.disconnected &&
        controller.messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Không vào được phòng chat', style: AppText.regular()),
            TextButton(
                onPressed: controller.connect, child: const Text('Thử lại')),
          ],
        ),
      );
    }
    if (controller.messages.isEmpty) {
      return Center(
        child: Text(
          'Hãy gửi lời chào tới ${controller.other.displayName} 👋',
          style: AppText.regular(color: AppColors.textSecondary),
        ),
      );
    }
    // reverse: true để tin mới nhất nằm dưới cùng và danh sách tự "dính" đáy.
    final items = controller.messages.reversed.toList();
    // Đọc 2 mốc ngay tại đây để Obx theo dõi chúng: itemBuilder bên dưới chạy muộn hơn,
    // đọc trong đó thì Obx không biết, "Đã xem" sẽ không tự hiện.
    controller.otherDeliveredAt.value;
    controller.otherReadAt.value;
    return ListView.builder(
      reverse: true,
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      // Khi người kia đang gõ, thêm một ô "..." ở dưới cùng (vị trí 0 vì danh sách bị đảo).
      itemCount: items.length + (controller.otherIsTyping.value ? 1 : 0),
      itemBuilder: (context, index) {
        if (controller.otherIsTyping.value) {
          if (index == 0) return _buildTypingBubble();
          index--;
        }
        final m = items[index];
        // Chỉ tin cuối cùng mình gửi mới có dòng trạng thái bên dưới, giống Messenger.
        if (m.id == controller.lastMine?.id) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [_buildBubble(m), _buildStatus(m)],
          );
        }
        return _buildBubble(m);
      },
    );
  }

  Widget _buildStatus(ChatMessageModel m) {
    final (text, icon, color) = switch (controller.statusOf(m)) {
      MessageStatus.sent => ('Đã gửi', Icons.check, AppColors.textSecondary),
      MessageStatus.delivered => (
          'Đã nhận',
          Icons.done_all,
          AppColors.textSecondary
        ),
      MessageStatus.seen => ('Đã xem', Icons.done_all, AppColors.primary),
    };
    return Padding(
      padding: EdgeInsets.only(right: 4.w, bottom: 2.h),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14.r, color: color),
          SizedBox(width: 3.w),
          Text(text, style: AppText.regular(size: 11, color: color)),
        ],
      ),
    );
  }

  Widget _buildTypingBubble() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 3.h),
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Text(
          '${controller.other.displayName} đang nhập...',
          style: AppText.regular(size: 13, color: AppColors.textSecondary),
        ),
      ),
    );
  }

  Widget _buildBubble(ChatMessageModel m) {
    final isMine = m.senderId == controller.meId;
    final time = DateTime.fromMillisecondsSinceEpoch(m.createdAt);
    final hhmm =
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: 0.75.sw),
        margin: EdgeInsets.symmetric(vertical: 3.h),
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isMine ? AppColors.primary : AppColors.white,
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              m.text,
              style: AppText.regular(
                size: 15,
                color: isMine ? AppColors.white : AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              hhmm,
              style: AppText.regular(
                size: 10,
                color: isMine ? Colors.white70 : AppColors.textSecondary,
              ),
            ),
          ],
        ),
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
                controller: controller.textController,
                minLines: 1,
                maxLines: 4,
                maxLength: 2000,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => controller.send(),
                style: AppText.regular(size: 15),
                decoration: InputDecoration(
                  hintText: 'Nhập tin nhắn...',
                  counterText: '',
                  isDense: true,
                  filled: true,
                  fillColor: const Color(0xFFF2F3F5),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20.r),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            Obx(
              () => IconButton(
                tooltip: 'Gửi',
                onPressed: controller.canSend.value &&
                        controller.connection.value ==
                            ChatConnectionState.connected
                    ? controller.send
                    : null,
                icon: Icon(Icons.send, size: 24.r),
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
