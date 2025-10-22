class MemoryMediaModel {
  final String id;
  final String memoryId;
  final String userId;
  final String mediaUrl;
  final String mediaType; // 'image' or 'video'
  final String? caption;
  final int displayOrder;
  final DateTime createdAt;

  MemoryMediaModel({
    required this.id,
    required this.memoryId,
    required this.userId,
    required this.mediaUrl,
    required this.mediaType,
    this.caption,
    required this.displayOrder,
    required this.createdAt,
  });

  factory MemoryMediaModel.fromJson(Map<String, dynamic> json) {
    return MemoryMediaModel(
      id: json['id'],
      memoryId: json['memory_id'],
      userId: json['user_id'],
      mediaUrl: json['media_url'],
      mediaType: json['media_type'],
      caption: json['caption'],
      displayOrder: json['display_order'] ?? 0,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'memory_id': memoryId,
      'user_id': userId,
      'media_url': mediaUrl,
      'media_type': mediaType,
      'caption': caption,
      'display_order': displayOrder,
      'created_at': createdAt.toIso8601String(),
    };
  }

  MemoryMediaModel copyWith({
    String? id,
    String? memoryId,
    String? userId,
    String? mediaUrl,
    String? mediaType,
    String? caption,
    int? displayOrder,
    DateTime? createdAt,
  }) {
    return MemoryMediaModel(
      id: id ?? this.id,
      memoryId: memoryId ?? this.memoryId,
      userId: userId ?? this.userId,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      mediaType: mediaType ?? this.mediaType,
      caption: caption ?? this.caption,
      displayOrder: displayOrder ?? this.displayOrder,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}