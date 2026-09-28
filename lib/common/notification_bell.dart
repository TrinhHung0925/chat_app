import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../route.dart';
import '../service/realtime_service.dart';

/// App bar bell with the unread count; updates live from RealtimeService.
class NotificationBell extends StatelessWidget {
  const NotificationBell({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final count = RealtimeService.instance.unreadCount.value;
      return IconButton(
        tooltip: 'Thông báo',
        onPressed: () => Get.toNamed(AppPage.notifications.routeName),
        icon: Badge(
          isLabelVisible: count > 0,
          label: Text(count > 99 ? '99+' : '$count'),
          child: Icon(
            count > 0 ? Icons.notifications : Icons.notifications_outlined,
          ),
        ),
      );
    });
  }
}
