import 'package:myyearmystory/supabase/supabase_config.dart';

class GratitudeService {
  static final _supabase = SupabaseConfig.client;

  static Future<List<String>> getGratitudeList(int month, int year, String userId) async {
    try {
      final row = await _supabase
          .from('entries')
          .select('gratitude_entries')
          .eq('user_id', userId)
          .eq('month', month)
          .eq('year', year)
          .maybeSingle();

      if (row == null) return <String>[];
      final data = row['gratitude_entries'];
      if (data is List) {
        return List<String>.from(data);
      }
      return <String>[];
    } catch (e) {
      print('Error fetching gratitude_entries from entries: $e');
      return <String>[];
    }
  }

  static Future<bool> saveGratitudeList(List<String> items, int month, int year, String userId) async {
    try {
      // Check if the entry already exists
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
          'gratitude_entries': items,
        });
      } else {
        await _supabase
            .from('entries')
            .update({'gratitude_entries': items})
            .eq('user_id', userId)
            .eq('month', month)
            .eq('year', year);
      }
      return true;
    } catch (e) {
      print('Error saving gratitude_entries to entries: $e');
      return false;
    }
  }
}
