class DiaryEntryModel {
  final String id;
  final String userId;
  final DateTime entryDate;
  final String content;
  final DateTime createdAt;

  DiaryEntryModel({
    required this.id,
    required this.userId,
    required this.entryDate,
    required this.content,
    required this.createdAt,
  });

  factory DiaryEntryModel.fromJson(Map<String, dynamic> json) {
    return DiaryEntryModel(
      id: json['id'],
      userId: json['user_id'],
      entryDate: DateTime.parse(json['entry_date']),
      content: json['content'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'entry_date': entryDate.toIso8601String(),
      'content': content,
      'created_at': createdAt.toIso8601String(),
    };
  }
}