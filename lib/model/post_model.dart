import 'user_model.dart';

class PostModel {
  final String id;
  final UserModel author;
  final String content;
  final int createdAt;
  final int updatedAt;
  final int likeCount;
  final int commentCount;
  final bool likedByMe;

  const PostModel({
    required this.id,
    required this.author,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    required this.likeCount,
    required this.commentCount,
    required this.likedByMe,
  });

  bool get isEdited => updatedAt != createdAt;

  factory PostModel.fromJson(Map<String, dynamic> json) => PostModel(
    id: json['id'] as String,
    author: UserModel.fromJson(json['author'] as Map<String, dynamic>),
    content: json['content'] as String,
    createdAt: json['createdAt'] as int,
    updatedAt: json['updatedAt'] as int,
    likeCount: json['likeCount'] as int,
    commentCount: json['commentCount'] as int,
    likedByMe: json['likedByMe'] as bool,
  );

  PostModel copyWith({int? likeCount, int? commentCount, bool? likedByMe}) =>
      PostModel(
        id: id,
        author: author,
        content: content,
        createdAt: createdAt,
        updatedAt: updatedAt,
        likeCount: likeCount ?? this.likeCount,
        commentCount: commentCount ?? this.commentCount,
        likedByMe: likedByMe ?? this.likedByMe,
      );
}
