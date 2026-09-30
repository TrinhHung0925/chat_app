import 'user_model.dart';

/// Kết quả đăng nhập / đăng ký: token + thông tin user.
class SessionModel {
  final String accessToken;
  final UserModel user;

  const SessionModel({required this.accessToken, required this.user});

  factory SessionModel.fromJson(Map<String, dynamic> json) {
    return SessionModel(
      accessToken: json['accessToken'] as String,
      user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}
