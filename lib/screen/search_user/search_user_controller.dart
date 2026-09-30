import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../model/relationship_model.dart';
import '../../model/user_profile_model.dart';
import '../../route.dart';
import '../../service/api_service.dart';
import '../../utils/relationship_actions.dart';

class SearchUserController extends GetxController {
  final textController = TextEditingController();
  final query = ''.obs;
  final results = <UserProfileModel>[].obs;
  final isSearching = false.obs;
  final busyIds = <String>{}.obs;

  @override
  void onInit() {
    super.onInit();
    textController.addListener(() => query.value = textController.text.trim());
    // Wait until typing pauses, so one request goes out instead of one per keystroke.
    debounce(query, (_) => search(), time: const Duration(milliseconds: 350));
  }

  @override
  void onClose() {
    textController.dispose();
    super.onClose();
  }

  Future<void> search() async {
    final q = query.value;
    if (q.isEmpty) {
      results.clear();
      return;
    }
    isSearching.value = true;
    try {
      final found = await ApiService.searchUsers(q);
      // Ignore a late answer for an older query.
      if (q == query.value) results.assignAll(found);
    } catch (e) {
      Get.snackbar('Lỗi', e.toString());
    } finally {
      isSearching.value = false;
    }
  }

  Future<void> _apply(
    UserProfileModel item,
    Future<RelationshipModel?> Function() action,
  ) async {
    if (busyIds.contains(item.user.id)) return;
    busyIds.add(item.user.id);
    try {
      final relationship = await action();
      if (relationship == null) return;
      final index = results.indexWhere((r) => r.user.id == item.user.id);
      if (index != -1) {
        results[index] = item.copyWith(relationship: relationship);
      }
    } finally {
      busyIds.remove(item.user.id);
    }
  }

  void add(UserProfileModel i) =>
      _apply(i, () => RelationshipActions.add(i.user));
  void cancel(UserProfileModel i) =>
      _apply(i, () => RelationshipActions.cancel(i.relationship));
  void accept(UserProfileModel i) =>
      _apply(i, () => RelationshipActions.accept(i.relationship));
  void decline(UserProfileModel i) =>
      _apply(i, () => RelationshipActions.decline(i.relationship));
  void unfriend(UserProfileModel i) =>
      _apply(i, () => RelationshipActions.unfriend(i.user));

  Future<void> openUser(UserProfileModel item) async {
    await Get.toNamed(AppPage.userProfile.routeName, arguments: item.user.id);
    await search();
  }

  void onBack() {
    Get.back();
  }
}
