// Một tin nhắn chat, đúng như ChatRoom (backend) gửi xuống.
class ChatMessageModel {
  final String id;
  final String senderId;
  final String senderName;
  final String text;
  final int createdAt;

  const ChatMessageModel({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.text,
    required this.createdAt,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) =>
      ChatMessageModel(
        id: json['id'] as String,
        senderId: json['senderId'] as String,
        senderName: json['senderName'] as String,
        text: json['text'] as String,
        createdAt: json['createdAt'] as int,
      );
}
