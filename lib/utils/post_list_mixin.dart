import 'package:get/get.dart';

import '../dialog/confirm_dialog.dart';
import '../model/post_model.dart';
import '../route.dart';
import '../service/api_service.dart';
import '../service/local_service.dart';

/// Like / edit / delete / open for any controller that shows a list of posts
/// (the feed and profile pages), so each screen does not repeat them.
mixin PostListMixin on GetxController {
  final posts = <PostModel>[].obs;

  bool isMine(PostModel post) => post.author.id == LocalService.user?.id;

  void _replace(PostModel post) {
    final index = posts.indexWhere((p) => p.id == post.id);
    if (index != -1) posts[index] = post;
  }

  /// Updates the heart at once, then corrects it with what the server says.
  Future<void> toggleLike(PostModel post) async {
    final liked = !post.likedByMe;
    _replace(
      post.copyWith(
        likedByMe: liked,
        likeCount: post.likeCount + (liked ? 1 : -1),
      ),
    );
    try {
      _replace(
        liked
            ? await ApiService.likePost(post.id)
            : await ApiService.unlikePost(post.id),
      );
    } catch (e) {
      _replace(post);
      Get.snackbar('Lỗi', e.toString());
    }
  }

  Future<void> editPost(PostModel post) async {
    final updated = await Get.toNamed(
      AppPage.postEditor.routeName,
      arguments: post,
    );
    if (updated is PostModel) _replace(updated);
  }

  Future<void> deletePost(PostModel post) async {
    final ok = await showConfirmDialog(
      title: 'Xóa bài viết?',
      message: 'Bài viết cùng lượt thích và bình luận sẽ bị xóa vĩnh viễn.',
      confirmText: 'Xóa',
      isDestructive: true,
    );
    if (!ok) return;
    try {
      await ApiService.deletePost(post.id);
      posts.removeWhere((p) => p.id == post.id);
    } catch (e) {
      Get.snackbar('Lỗi', e.toString());
    }
  }

  /// The detail screen returns the latest version of the post, or null if it was deleted there.
  Future<void> openPost(PostModel post) async {
    final result = await Get.toNamed(
      AppPage.postDetail.routeName,
      arguments: post,
    );
    if (result is PostModel) {
      _replace(result);
    } else if (result == false) {
      posts.removeWhere((p) => p.id == post.id);
    }
  }

  void openAuthor(PostModel post) {
    Get.toNamed(AppPage.userProfile.routeName, arguments: post.author.id);
  }
}
