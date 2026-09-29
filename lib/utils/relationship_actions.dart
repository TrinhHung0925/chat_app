import 'package:get/get.dart';

import '../dialog/confirm_dialog.dart';
import '../model/relationship_model.dart';
import '../model/user_model.dart';
import '../service/api_service.dart';

/// Runs one friend action and returns the new relationship, or null if nothing changed.
abstract class RelationshipActions {
  static Future<RelationshipModel?> add(UserModel user) =>
      _run(() => ApiService.sendFriendRequest(user.id));

  static Future<RelationshipModel?> cancel(RelationshipModel r) async {
    final ok = await showConfirmDialog(
      title: 'Hủy lời mời?',
      message: 'Lời mời kết bạn sẽ bị thu hồi.',
      confirmText: 'Hủy lời mời',
    );
    if (!ok) return null;
    return _run(() async {
      await ApiService.deleteFriendRequest(r.requestId!);
      return RelationshipModel.none;
    });
  }

  static Future<RelationshipModel?> accept(RelationshipModel r) =>
      _run(() async {
        await ApiService.acceptFriendRequest(r.requestId!);
        return RelationshipModel(RelationshipStatus.friends, r.requestId);
      });

  static Future<RelationshipModel?> decline(RelationshipModel r) =>
      _run(() async {
        await ApiService.deleteFriendRequest(r.requestId!);
        return RelationshipModel.none;
      });

  static Future<RelationshipModel?> unfriend(UserModel user) async {
    final ok = await showConfirmDialog(
      title: 'Hủy kết bạn?',
      message:
          'Bạn và ${user.displayName} sẽ không còn thấy bài viết của nhau.',
      confirmText: 'Hủy kết bạn',
      isDestructive: true,
    );
    if (!ok) return null;
    return _run(() async {
      await ApiService.unfriend(user.id);
      return RelationshipModel.none;
    });
  }

  static Future<RelationshipModel?> _run(
    Future<RelationshipModel> Function() action,
  ) async {
    try {
      return await action();
    } catch (e) {
      Get.snackbar('Lỗi', e.toString());
      return null;
    }
  }
}
