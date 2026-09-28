import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../model/post_model.dart';
import '../resource/app_colors.dart';
import '../resource/app_text.dart';
import '../utils/time_ago.dart';
import 'user_avatar.dart';

class PostCard extends StatelessWidget {
  final PostModel post;
  final bool isMine;
  final VoidCallback onLike;
  final VoidCallback? onOpen;
  final VoidCallback? onOpenAuthor;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const PostCard({
    super.key,
    required this.post,
    required this.isMine,
    required this.onLike,
    this.onOpen,
    this.onOpenAuthor,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      elevation: 0,
      color: AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12.r),
        onTap: onOpen,
        child: Padding(
          padding: EdgeInsets.fromLTRB(12.w, 12.h, 4.w, 4.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              SizedBox(height: 10.h),
              Padding(
                padding: EdgeInsets.only(right: 8.w),
                child: Text(post.content, style: AppText.regular(size: 15)),
              ),
              SizedBox(height: 4.h),
              _buildActions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        GestureDetector(
          onTap: onOpenAuthor,
          child: UserAvatar(
            userId: post.author.id,
            name: post.author.displayName,
          ),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: GestureDetector(
            onTap: onOpenAuthor,
            behavior: HitTestBehavior.opaque,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(post.author.displayName, style: AppText.bold(size: 15)),
                Text(
                  '${timeAgo(post.createdAt)}${post.isEdited ? ' · đã chỉnh sửa' : ''}',
                  style: AppText.regular(
                    size: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (isMine)
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_horiz),
            onSelected: (value) =>
                value == 'edit' ? onEdit?.call() : onDelete?.call(),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'edit', child: Text('Sửa bài viết')),
              PopupMenuItem(value: 'delete', child: Text('Xóa bài viết')),
            ],
          ),
      ],
    );
  }

  Widget _buildActions() {
    return Row(
      children: [
        TextButton.icon(
          onPressed: onLike,
          icon: Icon(
            post.likedByMe ? Icons.favorite : Icons.favorite_border,
            color: post.likedByMe ? Colors.red : AppColors.textSecondary,
            size: 20.r,
          ),
          label: Text(
            '${post.likeCount}',
            style: AppText.medium(
              color: post.likedByMe ? Colors.red : AppColors.textSecondary,
            ),
          ),
        ),
        TextButton.icon(
          onPressed: onOpen,
          icon: Icon(
            Icons.mode_comment_outlined,
            color: AppColors.textSecondary,
            size: 20.r,
          ),
          label: Text(
            '${post.commentCount}',
            style: AppText.medium(color: AppColors.textSecondary),
          ),
        ),
      ],
    );
  }
}
