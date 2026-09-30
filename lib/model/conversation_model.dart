import 'presence_model.dart';
import 'user_model.dart';

// Một dòng trong danh sách chat: đang chat với ai, tin cuối là gì, còn mấy tin chưa đọc.
class ConversationModel {
  final String id;
  final UserModel other;
  final String? lastMessageText;
  final String? lastSenderId;
  final int? lastMessageAt;
  final int unreadCount;
  // Người kia có đang hoạt động không.
  final PresenceModel presence;

  const ConversationModel({
    required this.id,
    required this.other,
    required this.unreadCount,
    this.presence = const PresenceModel(online: false),
    this.lastMessageText,
    this.lastSenderId,
    this.lastMessageAt,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) =>
      ConversationModel(
        id: json['id'] as String,
        other: UserModel.fromJson(json['other'] as Map<String, dynamic>),
        lastMessageText: json['lastMessageText'] as String?,
        lastSenderId: json['lastSenderId'] as String?,
        lastMessageAt: json['lastMessageAt'] as int?,
        unreadCount: json['unreadCount'] as int,
        presence: json['presence'] == null
            ? const PresenceModel(online: false)
            : PresenceModel.fromJson(json['presence'] as Map<String, dynamic>),
      );

  // Bản sao với trạng thái hoạt động mới (khi nhận sự kiện "presence" qua WebSocket).
  ConversationModel copyWithPresence(PresenceModel presence) =>
      ConversationModel(
        id: id,
        other: other,
        unreadCount: unreadCount,
        presence: presence,
        lastMessageText: lastMessageText,
        lastSenderId: lastSenderId,
        lastMessageAt: lastMessageAt,
      );
}
