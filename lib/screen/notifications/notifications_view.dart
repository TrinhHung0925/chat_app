import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../common/user_avatar.dart';
import '../../model/notification_model.dart';
import '../../resource/app_colors.dart';
import '../../resource/app_text.dart';
import '../../utils/time_ago.dart';
import 'notifications_controller.dart';

class NotificationsView extends StatefulWidget {
  NotificationsView({super.key}) {
    if (!Get.isRegistered<NotificationsController>()) {
      Get.put(NotificationsController());
    }
  }

  @override
  State<NotificationsView> createState() => _NotificationsViewState();
}

class _NotificationsViewState extends State<NotificationsView> {
  var controller = Get.find<NotificationsController>();

  @override
  void dispose() {
    Get.delete<NotificationsController>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Thông báo', style: AppText.bold(size: 18))),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        return RefreshIndicator(
          onRefresh: controller.load,
          child: controller.items.isEmpty
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 80.h),
                      child: Text(
                        'Chưa có thông báo nào.',
                        textAlign: TextAlign.center,
                        style: AppText.regular(color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                )
              : ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: controller.items.length,
                  itemBuilder: (context, index) =>
                      _buildItem(controller.items[index]),
                ),
        );
      }),
    );
  }

  Widget _buildItem(NotificationModel n) {
    final icon = switch (n.type) {
      NotificationType.friendRequest => Icons.person_add_alt_1,
      NotificationType.friendAccepted => Icons.how_to_reg,
      NotificationType.unknown => Icons.notifications,
    };
    return Material(
      color:
          n.read ? AppColors.white : AppColors.primary.withValues(alpha: 0.08),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
        leading: Stack(
          clipBehavior: Clip.none,
          children: [
            UserAvatar(userId: n.actor.id, name: n.actor.displayName, size: 48),
            Positioned(
              right: -4,
              bottom: -4,
              child: CircleAvatar(
                radius: 11.r,
                backgroundColor: AppColors.primary,
                child: Icon(icon, size: 13.r, color: AppColors.white),
              ),
            ),
          ],
        ),
        title: Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: n.actor.displayName,
                style: AppText.bold(size: 15),
              ),
              TextSpan(text: ' ${n.action}', style: AppText.regular(size: 15)),
            ],
          ),
        ),
        subtitle: Text(
          timeAgo(n.createdAt),
          style: AppText.regular(
            size: 12,
            color: n.read ? AppColors.textSecondary : AppColors.primary,
          ),
        ),
        onTap: () => controller.open(n),
      ),
    );
  }
}
