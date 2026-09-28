import 'relationship_model.dart';
import 'user_model.dart';

/// Another user as shown on their profile page or in search results.
class UserProfileModel {
  final UserModel user;
  final RelationshipModel relationship;
  final int friendCount;
  final int postCount;

  const UserProfileModel({
    required this.user,
    required this.relationship,
    this.friendCount = 0,
    this.postCount = 0,
  });

  bool get canSeePosts =>
      relationship.status == RelationshipStatus.friends ||
      relationship.status == RelationshipStatus.self;

  UserProfileModel copyWith({RelationshipModel? relationship}) =>
      UserProfileModel(
        user: user,
        relationship: relationship ?? this.relationship,
        friendCount: friendCount,
        postCount: postCount,
      );
}
