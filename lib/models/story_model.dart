class StoryModel {
  final String id;
  final String userId;
  final int year;
  final String title;
  final String content;
  final String? coverImageUrl;
  final bool isPublic;
  final DateTime createdAt;
  final DateTime updatedAt;

  StoryModel({
    required this.id,
    required this.userId,
    required this.year,
    required this.title,
    required this.content,
    this.coverImageUrl,
    required this.isPublic,
    required this.createdAt,
    required this.updatedAt,
  });

  factory StoryModel.fromJson(Map<String, dynamic> json) {
    return StoryModel(
      id: json['id'],
      userId: json['user_id'],
      year: json['year'],
      title: json['title'],
      content: json['content'],
      coverImageUrl: json['cover_image_url'],
      isPublic: json['is_public'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'year': year,
      'title': title,
      'content': content,
      'cover_image_url': coverImageUrl,
      'is_public': isPublic,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  StoryModel copyWith({
    String? id,
    String? userId,
    int? year,
    String? title,
    String? content,
    String? coverImageUrl,
    bool? isPublic,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return StoryModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      year: year ?? this.year,
      title: title ?? this.title,
      content: content ?? this.content,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      isPublic: isPublic ?? this.isPublic,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}