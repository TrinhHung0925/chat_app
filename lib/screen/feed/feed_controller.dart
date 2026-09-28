import 'package:get/get.dart';

import '../../model/post_model.dart';
import '../../route.dart';
import '../../service/api_service.dart';
import '../../utils/post_list_mixin.dart';

class FeedController extends GetxController with PostListMixin {
  final isLoading = true.obs;
  final isLoadingMore = false.obs;
  int? _nextBefore;

  bool get hasMore => _nextBefore != null;

  @override
  void onInit() {
    super.onInit();
    refreshFeed();
  }

  Future<void> refreshFeed() async {
    try {
      final page = await ApiService.getFeed();
      posts.assignAll(page.items);
      _nextBefore = page.nextBefore;
    } on ApiException catch (e) {
      Get.snackbar('Lỗi', e.message);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadMore() async {
    if (isLoadingMore.value || !hasMore) return;
    isLoadingMore.value = true;
    try {
      final page = await ApiService.getFeed(before: _nextBefore);
      posts.addAll(page.items);
      _nextBefore = page.nextBefore;
    } on ApiException catch (e) {
      Get.snackbar('Lỗi', e.message);
    } finally {
      isLoadingMore.value = false;
    }
  }

  Future<void> createPost() async {
    final created = await Get.toNamed(AppPage.postEditor.routeName);
    if (created is PostModel) posts.insert(0, created);
  }

  void onBack() {
    Get.back();
  }
}
