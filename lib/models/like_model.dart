class LikeModel {
  final String id;
  final String storyId;
  final String userId;
  final DateTime createdAt;

  LikeModel({
    required this.id,
    required this.storyId,
    required this.userId,
    required this.createdAt,
  });

  factory LikeModel.fromJson(Map<String, dynamic> json) {
    return LikeModel(
      id: json['id'],
      storyId: json['story_id'],
      userId: json['user_id'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'story_id': storyId,
      'user_id': userId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  LikeModel copyWith({
    String? id,
    String? storyId,
    String? userId,
    DateTime? createdAt,
  }) {
    return LikeModel(
      id: id ?? this.id,
      storyId: storyId ?? this.storyId,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}