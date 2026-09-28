import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../dialog/confirm_dialog.dart';
import '../../model/comment_model.dart';
import '../../model/post_model.dart';
import '../../route.dart';
import '../../service/api_service.dart';
import '../../service/local_service.dart';

/// Returns the latest post through Get.back, or false when the post was deleted here.
class PostDetailController extends GetxController {
  final post = Rxn<PostModel>();
  final comments = <CommentModel>[].obs;
  final isLoading = true.obs;
  final isSending = false.obs;
  final commentController = TextEditingController();

  PostDetailController(PostModel initial) {
    post.value = initial;
  }

  String get _postId => post.value!.id;
  String? get _meId => LocalService.user?.id;

  bool get isMyPost => post.value?.author.id == _meId;

  bool canDeleteComment(CommentModel c) => c.author.id == _meId || isMyPost;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  @override
  void onClose() {
    commentController.dispose();
    super.onClose();
  }

  Future<void> load() async {
    try {
      final results = await Future.wait([
        ApiService.getPost(_postId),
        ApiService.getComments(_postId),
      ]);
      post.value = results[0] as PostModel;
      comments.assignAll(results[1] as List<CommentModel>);
    } on ApiException catch (e) {
      Get.snackbar('Lỗi', e.message);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> toggleLike() async {
    final current = post.value!;
    final liked = !current.likedByMe;
    post.value = current.copyWith(
      likedByMe: liked,
      likeCount: current.likeCount + (liked ? 1 : -1),
    );
    try {
      post.value = liked
          ? await ApiService.likePost(_postId)
          : await ApiService.unlikePost(_postId);
    } on ApiException catch (e) {
      post.value = current;
      Get.snackbar('Lỗi', e.message);
    }
  }

  Future<void> sendComment() async {
    final content = commentController.text.trim();
    if (content.isEmpty || isSending.value) return;
    isSending.value = true;
    try {
      final comment = await ApiService.createComment(_postId, content);
      comments.add(comment);
      post.value = post.value!.copyWith(
        commentCount: post.value!.commentCount + 1,
      );
      commentController.clear();
    } on ApiException catch (e) {
      Get.snackbar('Lỗi', e.message);
    } finally {
      isSending.value = false;
    }
  }

  Future<void> deleteComment(CommentModel comment) async {
    final ok = await showConfirmDialog(
      title: 'Xóa bình luận?',
      message: comment.content,
      confirmText: 'Xóa',
      isDestructive: true,
    );
    if (!ok) return;
    try {
      await ApiService.deleteComment(_postId, comment.id);
      comments.removeWhere((c) => c.id == comment.id);
      post.value = post.value!.copyWith(
        commentCount: post.value!.commentCount - 1,
      );
    } on ApiException catch (e) {
      Get.snackbar('Lỗi', e.message);
    }
  }

  Future<void> editPost() async {
    final updated = await Get.toNamed(
      AppPage.postEditor.routeName,
      arguments: post.value,
    );
    if (updated is PostModel) post.value = updated;
  }

  Future<void> deletePost() async {
    final ok = await showConfirmDialog(
      title: 'Xóa bài viết?',
      message: 'Bài viết cùng lượt thích và bình luận sẽ bị xóa vĩnh viễn.',
      confirmText: 'Xóa',
      isDestructive: true,
    );
    if (!ok) return;
    try {
      await ApiService.deletePost(_postId);
      Get.back(result: false);
    } on ApiException catch (e) {
      Get.snackbar('Lỗi', e.message);
    }
  }

  void openUser(String userId) {
    Get.toNamed(AppPage.userProfile.routeName, arguments: userId);
  }

  void onBack() {
    Get.back(result: post.value);
  }
}
