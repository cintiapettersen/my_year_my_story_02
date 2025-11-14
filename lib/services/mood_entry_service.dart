import 'package:myyearmystory/models/mood_entry_model.dart';
import 'package:myyearmystory/supabase/supabase_config.dart';

final supabase = SupabaseConfig.client;

class MoodEntryService {
  static Future<List<MoodEntry>> getMoodsByMonth(int month, int year, String userId) async {
    try {
      final startDate = DateTime(year, month, 1);
      final endDate = DateTime(year, month + 1, 1).subtract(Duration(days: 1));

      final response = await supabase
          .from('mood_entries')
          .select()
          .eq('user_id', userId)
          .gte('date', startDate.toIso8601String())
          .lte('date', endDate.toIso8601String())
          .order('date', ascending: false);

      return response.map<MoodEntry>((json) => MoodEntry.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching mood entries: $e');
      return [];
    }
  }

  static Future<List<MoodEntry>> getMoodsByDate(DateTime date, String userId) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(Duration(days: 1)).subtract(Duration(microseconds: 1));

      final response = await supabase
          .from('mood_entries')
          .select()
          .eq('user_id', userId)
          .gte('date', startOfDay.toIso8601String())
          .lte('date', endOfDay.toIso8601String())
          .order('date', ascending: false);

      return response.map<MoodEntry>((json) => MoodEntry.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching daily moods: $e');
      return [];
    }
  }

  static Future<MoodEntry?> createMoodEntry(MoodEntry mood, String userId) async {
    try {
      final response = await supabase
          .from('mood_entries')
          .insert({
            'user_id': userId,
            'date': mood.date.toIso8601String(),
            'mood': mood.mood,
          })
          .select()
          .single();

      return MoodEntry.fromJson(response);
    } catch (e) {
      print('Error creating mood entry: $e');
      return null;
    }
  }

  static Future<bool> deleteMoodEntry(String moodId, String userId) async {
    try {
      await supabase
          .from('mood_entries')
          .delete()
          .eq('id', moodId)
          .eq('user_id', userId);

      return true;
    } catch (e) {
      print('Error deleting mood entry: $e');
      return false;
    }
  }
}