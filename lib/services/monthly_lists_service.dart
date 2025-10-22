import 'package:my_year_my_story/supabase/supabase_config.dart';

class MonthlyListsService {
  static final _supabase = SupabaseConfig.client;

  static Future<Map<String, List<String>>> getMonthlyLists(int month, int year, String userId) async {
    try {
      final row = await _supabase
          .from('entries')
          .select('lists')
          .eq('user_id', userId)
          .eq('month', month)
          .eq('year', year)
          .maybeSingle();

      if (row == null) return <String, List<String>>{};
      final data = row['lists'];
      if (data is Map) {
        final dynamicMap = Map<String, dynamic>.from(data);
        final result = <String, List<String>>{};
        dynamicMap.forEach((key, value) {
          if (value is List) {
            result[key] = List<String>.from(value);
          }
        });
        return result;
      }
      return <String, List<String>>{};
    } catch (e) {
      print('Error fetching lists from entries: $e');
      return <String, List<String>>{};
    }
  }

  static Future<bool> saveMonthlyLists(Map<String, List<String>> lists, int month, int year, String userId) async {
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
          'lists': lists,
        });
      } else {
        await _supabase
            .from('entries')
            .update({'lists': lists})
            .eq('user_id', userId)
            .eq('month', month)
            .eq('year', year);
      }
      return true;
    } catch (e) {
      print('Error saving lists to entries: $e');
      return false;
    }
  }
}
