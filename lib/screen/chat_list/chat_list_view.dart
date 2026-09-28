import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../common/notification_bell.dart';
import '../../resource/app_colors.dart';
import '../../resource/app_text.dart';
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
      body: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 32.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.forum_outlined,
                size: 64.r,
                color: AppColors.textSecondary,
              ),
              SizedBox(height: 12.h),
              Text(
                'Chưa có cuộc trò chuyện nào',
                style: AppText.bold(size: 17),
              ),
              SizedBox(height: 6.h),
              Text(
                'Các cuộc trò chuyện với bạn bè sẽ hiện ở đây.',
                textAlign: TextAlign.center,
                style: AppText.regular(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
