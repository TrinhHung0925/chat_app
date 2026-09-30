import 'user_model.dart';

class CommentModel {
  final String id;
  final String postId;
  final UserModel author;
  final String content;
  final int createdAt;

  const CommentModel({
    required this.id,
    required this.postId,
    required this.author,
    required this.content,
    required this.createdAt,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) => CommentModel(
        id: json['id'] as String,
        postId: json['postId'] as String,
        author: UserModel.fromJson(json['author'] as Map<String, dynamic>),
        content: json['content'] as String,
        createdAt: json['createdAt'] as int,
      );
}
