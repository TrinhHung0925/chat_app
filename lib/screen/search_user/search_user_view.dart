import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../common/relationship_button.dart';
import '../../common/user_avatar.dart';
import '../../resource/app_colors.dart';
import '../../resource/app_text.dart';
import 'search_user_controller.dart';

class SearchUserView extends StatefulWidget {
  SearchUserView({super.key}) {
    if (!Get.isRegistered<SearchUserController>()) {
      Get.put(SearchUserController());
    }
  }

  @override
  State<SearchUserView> createState() => _SearchUserViewState();
}

class _SearchUserViewState extends State<SearchUserView> {
  var controller = Get.find<SearchUserController>();

  @override
  void dispose() {
    Get.delete<SearchUserController>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: TextField(
          controller: controller.textController,
          autofocus: true,
          autocorrect: false,
          textInputAction: TextInputAction.search,
          style: AppText.regular(size: 16),
          decoration: InputDecoration(
            hintText: 'Tìm theo mã (@...) hoặc tên',
            border: InputBorder.none,
            hintStyle: AppText.regular(color: AppColors.textSecondary),
          ),
        ),
      ),
      body: Obx(() {
        if (controller.isSearching.value && controller.results.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.query.value.isEmpty) {
          return _buildHint('Nhập mã của bạn bè, ví dụ @binh.tran');
        }
        if (controller.results.isEmpty) {
          return _buildHint('Không tìm thấy ai.');
        }
        return ListView.separated(
          itemCount: controller.results.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final item = controller.results[index];
            return ListTile(
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16.w,
                vertical: 4.h,
              ),
              leading: UserAvatar(
                userId: item.user.id,
                name: item.user.displayName,
              ),
              title: Text(
                item.user.displayName,
                style: AppText.medium(size: 15),
              ),
              subtitle: Text(
                '@${item.user.handle}',
                style: AppText.regular(
                  size: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              onTap: () => controller.openUser(item),
              trailing: RelationshipButton(
                compact: true,
                relationship: item.relationship,
                isBusy: controller.busyIds.contains(item.user.id),
                onAdd: () => controller.add(item),
                onCancel: () => controller.cancel(item),
                onAccept: () => controller.accept(item),
                onDecline: () => controller.decline(item),
                onUnfriend: () => controller.unfriend(item),
              ),
            );
          },
        );
      }),
    );
  }

  Widget _buildHint(String text) {
    return Padding(
      padding: EdgeInsets.all(32.r),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: AppText.regular(color: AppColors.textSecondary),
      ),
    );
  }
}
