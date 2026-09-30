import 'friend_request_model.dart';

/// Danh sách lời mời kết bạn: [incoming] người khác gửi cho mình,
/// [outgoing] mình gửi cho người khác.
class FriendRequestsModel {
  final List<FriendRequestModel> incoming;
  final List<FriendRequestModel> outgoing;

  const FriendRequestsModel({required this.incoming, required this.outgoing});

  factory FriendRequestsModel.fromJson(Map<String, dynamic> json) {
    List<FriendRequestModel> parse(dynamic list) {
      return (list as List)
          .map((e) => FriendRequestModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    return FriendRequestsModel(
      incoming: parse(json['incoming']),
      outgoing: parse(json['outgoing']),
    );
  }
}
