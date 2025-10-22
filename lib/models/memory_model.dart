class MemoryModel {
  final String id;
  final String storyId;
  final String userId;
  final String title;
  final String? description;
  final DateTime memoryDate;
  final String? location;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;

  MemoryModel({
    required this.id,
    required this.storyId,
    required this.userId,
    required this.title,
    this.description,
    required this.memoryDate,
    this.location,
    required this.tags,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MemoryModel.fromJson(Map<String, dynamic> json) {
    return MemoryModel(
      id: json['id'],
      storyId: json['story_id'],
      userId: json['user_id'],
      title: json['title'],
      description: json['description'],
      memoryDate: DateTime.parse(json['memory_date']),
      location: json['location'],
      tags: json['tags'] != null ? List<String>.from(json['tags']) : [],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'story_id': storyId,
      'user_id': userId,
      'title': title,
      'description': description,
      'memory_date': memoryDate.toIso8601String().split('T')[0], // Date only
      'location': location,
      'tags': tags,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  MemoryModel copyWith({
    String? id,
    String? storyId,
    String? userId,
    String? title,
    String? description,
    DateTime? memoryDate,
    String? location,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MemoryModel(
      id: id ?? this.id,
      storyId: storyId ?? this.storyId,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      memoryDate: memoryDate ?? this.memoryDate,
      location: location ?? this.location,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}