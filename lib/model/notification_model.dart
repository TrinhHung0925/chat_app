import 'user_model.dart';

enum NotificationType { friendRequest, friendAccepted, unknown }

class NotificationModel {
  final String id;
  final NotificationType type;
  final UserModel actor;
  final String? refId;
  final int createdAt;
  final bool read;

  const NotificationModel({
    required this.id,
    required this.type,
    required this.actor,
    required this.createdAt,
    required this.read,
    this.refId,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) =>
      NotificationModel(
        id: json['id'] as String,
        type: switch (json['type']) {
          'friend_request' => NotificationType.friendRequest,
          'friend_accepted' => NotificationType.friendAccepted,
          _ => NotificationType.unknown,
        },
        actor: UserModel.fromJson(json['actor'] as Map<String, dynamic>),
        refId: json['refId'] as String?,
        createdAt: json['createdAt'] as int,
        read: json['read'] as bool,
      );

  /// The sentence after the actor's name.
  String get action => switch (type) {
        NotificationType.friendRequest => 'đã gửi cho bạn lời mời kết bạn',
        NotificationType.friendAccepted =>
          'đã chấp nhận lời mời kết bạn của bạn',
        NotificationType.unknown => 'có hoạt động mới',
      };
}
