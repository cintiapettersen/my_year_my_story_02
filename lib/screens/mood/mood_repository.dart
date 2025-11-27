import 'package:supabase_flutter/supabase_flutter.dart';

class MoodRepository {
  final SupabaseClient client = Supabase.instance.client;

  static final MoodRepository _instance = MoodRepository._internal();
  factory MoodRepository() => _instance;
  MoodRepository._internal();

  /// Salvar ou atualizar humor do dia
  Future<void> saveMood({
    required String userId,
    required String moodKey,
    required DateTime date,
  }) async {
    final dateOnly = DateTime(date.year, date.month, date.day);

    await client.from('mood_entries').upsert({
      'user_id': userId,
      'mood': moodKey,
      'entry_date': dateOnly.toIso8601String(),
      'month': date.month,
      'year': date.year,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  /// Buscar todos os humores do mês
  Future<List<Map<String, dynamic>>> getMoodsForMonth({
    required String userId,
    required int month,
    required int year,
  }) async {
    final response = await client
        .from('mood_entries')
        .select('mood, entry_date')
        .eq('user_id', userId)
        .eq('month', month)
        .eq('year', year)
        .order('entry_date', ascending: true);

    return List<Map<String, dynamic>>.from(response);
  }

  /// Buscar humor de um único dia
  Future<String?> getMoodForDate({
    required String userId,
    required DateTime date,
  }) async {
    final dateOnly = DateTime(date.year, date.month, date.day).toIso8601String();

    final data = await client
        .from('mood_entries')
        .select('mood')
        .eq('user_id', userId)
        .eq('entry_date', dateOnly)
        .maybeSingle();

    if (data == null) return null;

    return data['mood'] as String?;
  }
}
