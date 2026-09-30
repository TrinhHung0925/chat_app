import '../utils/time_ago.dart';

// Một người bạn có đang mở app không, và lần cuối mở / rời app là lúc nào.
class PresenceModel {
  final bool online;
  final int? lastSeenAt;

  const PresenceModel({required this.online, this.lastSeenAt});

  factory PresenceModel.fromJson(Map<String, dynamic> json) => PresenceModel(
        online: json['online'] as bool,
        lastSeenAt: json['lastSeenAt'] as int?,
      );

  // Dòng chữ dưới tên trên màn chat. null = chưa từng thấy online (không hiện gì).
  String? get label {
    if (online) return 'Đang hoạt động';
    final at = lastSeenAt;
    if (at == null) return null;
    final ago = timeAgo(at);
    if (ago == 'vừa xong') return 'Vừa mới hoạt động';
    // timeAgo trả về ngày (dd/mm/yyyy) khi đã quá 7 ngày.
    if (ago.contains('/')) return 'Hoạt động ngày $ago';
    return 'Hoạt động $ago trước';
  }
}
