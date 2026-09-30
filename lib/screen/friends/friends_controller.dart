import 'package:get/get.dart';

import '../../dialog/confirm_dialog.dart';
import '../../model/friend_request_model.dart';
import '../../model/user_model.dart';
import '../../route.dart';
import '../../service/api_service.dart';

class FriendsController extends GetxController {
  final friends = <UserModel>[].obs;
  final incoming = <FriendRequestModel>[].obs;
  final outgoing = <FriendRequestModel>[].obs;
  final isLoading = true.obs;

  /// Ids of requests or friends with an action in flight, to disable their buttons.
  final busyIds = <String>{}.obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    try {
      final results = await Future.wait([
        ApiService.getFriends(),
        ApiService.getFriendRequests(),
      ]);
      friends.assignAll(results[0] as List<UserModel>);
      final requests =
          results[1]
              as ({
                List<FriendRequestModel> incoming,
                List<FriendRequestModel> outgoing,
              });
      incoming.assignAll(requests.incoming);
      outgoing.assignAll(requests.outgoing);
    } catch (e) {
      Get.snackbar('Lỗi', e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _busy(String id, Future<void> Function() action) async {
    if (busyIds.contains(id)) return;
    busyIds.add(id);
    try {
      await action();
      await load();
    } catch (e) {
      Get.snackbar('Lỗi', e.toString());
    } finally {
      busyIds.remove(id);
    }
  }

  void accept(FriendRequestModel r) =>
      _busy(r.id, () => ApiService.acceptFriendRequest(r.id));
  void decline(FriendRequestModel r) =>
      _busy(r.id, () => ApiService.deleteFriendRequest(r.id));
  void cancel(FriendRequestModel r) =>
      _busy(r.id, () => ApiService.deleteFriendRequest(r.id));

  Future<void> unfriend(UserModel user) async {
    final ok = await showConfirmDialog(
      title: 'Hủy kết bạn?',
      message:
          'Bạn và ${user.displayName} sẽ không còn thấy bài viết của nhau.',
      confirmText: 'Hủy kết bạn',
      isDestructive: true,
    );
    if (ok) await _busy(user.id, () => ApiService.unfriend(user.id));
  }

  Future<void> openUser(UserModel user) async {
    await Get.toNamed(AppPage.userProfile.routeName, arguments: user.id);
    await load();
  }

  Future<void> openSearch() async {
    await Get.toNamed(AppPage.searchUser.routeName);
    await load();
  }

  void onBack() {
    Get.back();
  }
}
