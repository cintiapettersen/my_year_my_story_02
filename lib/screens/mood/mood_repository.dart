import 'package:supabase_flutter/supabase_flutter.dart';

class MoodRepository {
  final SupabaseClient client = Supabase.instance.client;

  static final MoodRepository _instance = MoodRepository._internal();
  factory MoodRepository() => _instance;
  MoodRepository._internal();

  /// ---------------------------------------
  /// SALVAR HUMOR DO DIA (corrigido)
  /// ---------------------------------------
  Future<void> saveMood({
    required String userId,
    required String moodKey,
    required DateTime date,
  }) async {
    // Data sem timezone e sem horário
    final dateOnlyString =
        "${date.year.toString().padLeft(4, '0')}-"
        "${date.month.toString().padLeft(2, '0')}-"
        "${date.day.toString().padLeft(2, '0')}";

    await client.from('mood_entries').upsert({
      'user_id': userId,
      'mood': moodKey,
      'entry_date': dateOnlyString, // <-- SAFE
      'month': date.month,
      'year': date.year,
      'created_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  /// ---------------------------------------
  /// BUSCAR TODOS OS HUMORES DO MÊS
  /// Apenas o ÚLTIMO humor por dia
  /// ---------------------------------------
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

    final List<Map<String, dynamic>> raw =
        List<Map<String, dynamic>>.from(response);

    // Monta map filtrando último humor do dia
    final Map<String, Map<String, dynamic>> lastByDay = {};

    for (final item in raw) {
      final dateStr = item['entry_date'];
      if (dateStr == null) continue;

      // Parseando sem mudar fuso
      final dateParts = dateStr.split("-");
      if (dateParts.length != 3) continue;

      final day = int.tryParse(dateParts[2]);
      if (day == null) continue;

      lastByDay[day.toString()] = item;
    }

    return lastByDay.values.toList();
  }

  /// ---------------------------------------
  /// BUSCAR HUMOR DE UM ÚNICO DIA
  /// ---------------------------------------
  Future<String?> getMoodForDate({
    required String userId,
    required DateTime date,
  }) async {
    final dateOnlyString =
        "${date.year.toString().padLeft(4, '0')}-"
        "${date.month.toString().padLeft(2, '0')}-"
        "${date.day.toString().padLeft(2, '0')}";

    final data = await client
        .from('mood_entries')
        .select('mood')
        .eq('user_id', userId)
        .eq('entry_date', dateOnlyString)
        .maybeSingle();

    return data?['mood'] as String?;
  }
}
