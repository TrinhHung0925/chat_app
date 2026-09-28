import 'user_model.dart';

class FriendRequestModel {
  final String id;

  /// The other person: the sender for incoming requests, the receiver for outgoing ones.
  final UserModel user;
  final int createdAt;

  const FriendRequestModel({
    required this.id,
    required this.user,
    required this.createdAt,
  });

  factory FriendRequestModel.fromJson(Map<String, dynamic> json) =>
      FriendRequestModel(
        id: json['id'] as String,
        user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
        createdAt: json['createdAt'] as int,
      );
}
