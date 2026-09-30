import 'package:get/get.dart';

import '../../model/relationship_model.dart';
import '../../model/user_profile_model.dart';
import '../../route.dart';
import '../../service/api_service.dart';
import '../../utils/post_list_mixin.dart';
import '../../utils/relationship_actions.dart';

/// Anyone's profile page, including your own (the "Tôi" tab).
class UserProfileController extends GetxController with PostListMixin {
  final String userId;
  final profile = Rxn<UserProfileModel>();
  final isLoading = true.obs;
  final isBusy = false.obs;
  final isLoadingMore = false.obs;
  final error = RxnString();
  int? _nextBefore;

  UserProfileController(this.userId);

  bool get hasMore => _nextBefore != null;
  bool get isSelf =>
      profile.value?.relationship.status == RelationshipStatus.self;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    try {
      final info = await ApiService.getUserProfile(userId);
      profile.value = info;
      error.value = null;
      if (info.canSeePosts) {
        final page = await ApiService.getUserPosts(userId);
        posts.assignAll(page.items);
        _nextBefore = page.nextBefore;
      } else {
        posts.clear();
        _nextBefore = null;
      }
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadMore() async {
    if (isLoadingMore.value || !hasMore) return;
    isLoadingMore.value = true;
    try {
      final page = await ApiService.getUserPosts(userId, before: _nextBefore);
      posts.addAll(page.items);
      _nextBefore = page.nextBefore;
    } catch (e) {
      Get.snackbar('Lỗi', e.toString());
    } finally {
      isLoadingMore.value = false;
    }
  }

  Future<void> _apply(Future<RelationshipModel?> Function() action) async {
    if (isBusy.value) return;
    isBusy.value = true;
    try {
      final result = await action();
      // Becoming (or no longer being) friends changes which posts are visible, so reload.
      if (result != null) await load();
    } finally {
      isBusy.value = false;
    }
  }

  RelationshipModel get _relationship => profile.value!.relationship;

  void addFriend() =>
      _apply(() => RelationshipActions.add(profile.value!.user));
  void cancelRequest() =>
      _apply(() => RelationshipActions.cancel(_relationship));
  void acceptRequest() =>
      _apply(() => RelationshipActions.accept(_relationship));
  void declineRequest() =>
      _apply(() => RelationshipActions.decline(_relationship));
  void unfriend() =>
      _apply(() => RelationshipActions.unfriend(profile.value!.user));

  // Chỉ bạn bè mới chat được (backend cũng kiểm tra lại điều này).
  void openChat() {
    Get.toNamed(AppPage.chat.routeName, arguments: profile.value!.user);
  }

  Future<void> editProfile() async {
    await Get.toNamed(AppPage.profile.routeName);
    await load();
  }

  void onBack() {
    Get.back();
  }
}
