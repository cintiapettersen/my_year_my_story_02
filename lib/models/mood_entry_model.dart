class MoodEntry {
  final String id;
  final DateTime date;
  final String mood; // 'happy', 'sad', 'tired', 'neutral', 'sick', 'angry', 'excited'
  final String? notes;

  MoodEntry({
    required this.id,
    required this.date,
    required this.mood,
    this.notes,
  });

  String get moodEmoji {
    switch (mood) {
      case 'happy':
        return '😊';
      case 'sad':
        return '😢';
      case 'tired':
        return '😴';
      case 'neutral':
        return '😐';
      case 'sick':
        return '🤒';
      case 'angry':
        return '😡';
      case 'excited':
        return '🤩';
      default:
        return '😊';
    }
  }

  String get moodLabel {
    switch (mood) {
      case 'happy':
        return 'Feliz';
      case 'sad':
        return 'Triste';
      case 'tired':
        return 'Cansado';
      case 'neutral':
        return 'Neutro';
      case 'sick':
        return 'Doente';
      case 'angry':
        return 'Irritado';
      case 'excited':
        return 'Animado';
      default:
        return 'Feliz';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'mood': mood,
      'notes': notes,
    };
  }

  factory MoodEntry.fromJson(Map<String, dynamic> json) {
    return MoodEntry(
      id: json['id'],
      date: DateTime.parse(json['date']),
      mood: json['mood'],
      notes: json['notes'],
    );
  }
}