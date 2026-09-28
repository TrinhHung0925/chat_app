class UserModel {
  final String id;
  final String username;
  final String displayName;
  final int createdAt;

  const UserModel({
    required this.id,
    required this.username,
    required this.displayName,
    required this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    id: json['id'] as String,
    username: json['username'] as String,
    displayName: json['displayName'] as String,
    createdAt: json['createdAt'] as int,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'username': username,
    'displayName': displayName,
    'createdAt': createdAt,
  };
}
