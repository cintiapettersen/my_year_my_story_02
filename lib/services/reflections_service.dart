import 'package:myyearmystory/supabase/supabase_config.dart';

class ReflectionsService {
  static final _supabase = SupabaseConfig.client;

  static Future<Map<String, String>> getReflections(int month, int year, String userId) async {
    try {
      final row = await _supabase
          .from('entries')
          .select('reflections')
          .eq('user_id', userId)
          .eq('month', month)
          .eq('year', year)
          .maybeSingle();

      if (row == null) return <String, String>{};
      final data = row['reflections'];
      if (data is Map) {
        final map = Map<String, dynamic>.from(data);
        return map.map((k, v) => MapEntry(k, v?.toString() ?? ''));
      }
      return <String, String>{};
    } catch (e) {
      print('Error fetching reflections from entries: $e');
      return <String, String>{};
    }
  }

  static Future<bool> saveReflections(Map<String, String> reflections, int month, int year, String userId) async {
    try {
      final existing = await _supabase
          .from('entries')
          .select('id')
          .eq('user_id', userId)
          .eq('month', month)
          .eq('year', year)
          .maybeSingle();

      if (existing == null) {
        await _supabase.from('entries').insert({
          'user_id': userId,
          'month': month,
          'year': year,
          'reflections': reflections,
        });
      } else {
        await _supabase
            .from('entries')
            .update({'reflections': reflections})
            .eq('user_id', userId)
            .eq('month', month)
            .eq('year', year);
      }
      return true;
    } catch (e) {
      print('Error saving reflections to entries: $e');
      return false;
    }
  }
}
