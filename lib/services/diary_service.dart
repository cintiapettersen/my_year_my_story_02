import 'package:myyearmystory/models/diary_entry.dart';
import 'package:myyearmystory/supabase/supabase_config.dart';

class DiaryService {
  static final _supabase = SupabaseConfig.client;

  // ===============================
  // DELETE ENTRY
  // ===============================
  static Future<void> deleteEntry(String entryId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      print("DiaryService → Deleting entry $entryId");

      await _supabase
          .from('diary_entries')
          .delete()
          .eq('id', entryId)
          .eq('user_id', user.id);

      print("DiaryService → Entry deleted");
    } catch (e) {
      print("DiaryService → Error deleting entry: $e");
      rethrow;
    }
  }

  // ===============================
  // GET ALL ENTRIES
  // ===============================
  static Future<List<DiaryEntryModel>> getEntries() async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      print('DiaryService → Guest user, returning empty list');
      return [];
    }

    try {
      print('DiaryService → Fetching entries for user ${user.id}');

      final response = await _supabase
          .from('diary_entries')
          .select()
          .eq('user_id', user.id)
          .order('entry_date', ascending: false);

      final entries = (response as List)
          .map((entry) => DiaryEntryModel.fromJson(entry))
          .toList();

      print('DiaryService → Parsed ${entries.length} entries');
      return entries;
    } catch (e) {
      print('DiaryService → Error fetching diary entries: $e');
      rethrow;
    }
  }

  // ===============================
  // CREATE ENTRY
  // ===============================
  static Future<DiaryEntryModel> createEntry(
    String content,
    DateTime entryDate, {
    String? moodIcon,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw Exception('Guest cannot create diary entry');
    }

    try {
      print('DiaryService → Creating entry (user: ${user.id}, mood: $moodIcon)');

      final response = await _supabase
          .from('diary_entries')
          .insert({
            'user_id': user.id,
            'entry_date': entryDate.toIso8601String(),
            'content': content,
            'mood_icon': moodIcon,

            // ⭐ mantém suporte ao calendário
            'day': entryDate.day,
            'month': entryDate.month,
            'year': entryDate.year,
          })
          .select()
          .single();

      print('DiaryService → Entry created: ${response['id']}');
      return DiaryEntryModel.fromJson(response);
    } catch (e) {
      print('DiaryService → Error creating entry: $e');
      rethrow;
    }
  }

  // ===============================
  // UPDATE ENTRY
  // ===============================
 static Future<DiaryEntryModel> updateEntry(
  String entryId,
  String content,
  DateTime entryDate, {
  String? moodIcon,
}) async {
  final user = _supabase.auth.currentUser;
  if (user == null) {
    throw Exception('Guest cannot update diary entry');
  }

  try {
    print('DiaryService → Updating entry $entryId');

    // Monta o payload dinamicamente
    final updateData = {
      'entry_date': entryDate.toIso8601String(),
      'content': content,

      // ⭐ mantém sincronia com o calendário
      'day': entryDate.day,
      'month': entryDate.month,
      'year': entryDate.year,
    };

    // Só atualiza o humor se ele foi passado
    if (moodIcon != null) {
      updateData['mood_icon'] = moodIcon;
    }

    final response = await _supabase
        .from('diary_entries')
        .update(updateData)
        .eq('id', entryId)
        .eq('user_id', user.id)
        .select()
        .single();

    print('DiaryService → Entry updated successfully');
    return DiaryEntryModel.fromJson(response);
  } catch (e) {
    print('DiaryService → Error updating entry: $e');
    rethrow;
  }
}

  // ===============================
  // GET ENTRIES BY DATE RANGE
  // ===============================
  static Future<List<DiaryEntryModel>> getEntriesByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];

    try {
      final response = await _supabase
          .from('diary_entries')
          .select()
          .eq('user_id', user.id)
          .gte('entry_date', startDate.toIso8601String())
          .lte('entry_date', endDate.toIso8601String())
          .order('entry_date', ascending: false);

      return (response as List)
          .map((entry) => DiaryEntryModel.fromJson(entry))
          .toList();
    } catch (e) {
      print('DiaryService → Error fetching entries by date: $e');
      rethrow;
    }
  }
}
