class UserModel {
  final String id;
  final String handle;
  final String displayName;
  final int createdAt;

  /// Only present for the signed-in user; other users' login names are private.
  final String? username;

  const UserModel({
    required this.id,
    required this.handle,
    required this.displayName,
    required this.createdAt,
    this.username,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    id: json['id'] as String,
    handle: json['handle'] as String,
    displayName: json['displayName'] as String,
    createdAt: json['createdAt'] as int,
    username: json['username'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'handle': handle,
    'displayName': displayName,
    'createdAt': createdAt,
    'username': username,
  };
}
