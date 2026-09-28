/// How another user relates to the signed-in user.
enum RelationshipStatus { none, outgoing, incoming, friends, self }

class RelationshipModel {
  final RelationshipStatus status;

  /// The friendship row id; needed to accept, decline or cancel a request.
  final String? requestId;

  const RelationshipModel(this.status, [this.requestId]);

  static const none = RelationshipModel(RelationshipStatus.none);

  factory RelationshipModel.fromJson(Map<String, dynamic> json) =>
      RelationshipModel(
        RelationshipStatus.values.byName(json['status'] as String),
        json['requestId'] as String?,
      );
}
