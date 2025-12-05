import 'package:myyearmystory/models/diary_entry.dart';
import 'package:myyearmystory/supabase/supabase_config.dart';

class DiaryService {
  static final _supabase = SupabaseConfig.client;


    /// Deleta entrada do diário
  static Future<void> deleteEntry(String entryId) async {
    try {
      print("DiaryService → Deleting entry $entryId");

      await _supabase
          .from('diary_entries')
          .delete()
          .eq('id', entryId);

      print("DiaryService → Entry deleted");
    } catch (e) {
      print("DiaryService → Error deleting entry: $e");
      rethrow;
    }
  }


  /// Lista todas as entradas de diário do usuário
  static Future<List<DiaryEntryModel>> getEntries(String userId) async {
    try {
      print('DiaryService → Fetching entries for user $userId');

      final response = await _supabase
          .from('diary_entries')
          .select()
          .eq('user_id', userId)
          .order('entry_date', ascending: false);

      print('DiaryService → Raw response: $response');

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

  /// Cria uma nova entrada de diário
  /// Agora aceita opcionalmente `moodIcon`
  /// Cria uma nova entrada de diário (com suporte a calendário)
static Future<DiaryEntryModel> createEntry(
  String userId,
  String content,
  DateTime entryDate, {
  String? moodIcon,
}) async {
  try {
    print('DiaryService → Creating entry (user: $userId, mood: $moodIcon)');

    final response = await _supabase
        .from('diary_entries')
        .insert({
          'user_id': userId,
          'entry_date': entryDate.toIso8601String(),
          'content': content,
          'mood_icon': moodIcon,

          // ⭐ NECESSÁRIO PARA O POPUP DO CALENDÁRIO FUNCIONAR
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


  /// Atualiza entrada (agora também permite atualizar moodIcon)
  static Future<DiaryEntryModel> updateEntry(
  String entryId,
  String content,
  DateTime entryDate, {
  String? moodIcon,
}) async {
  try {
    print('DiaryService → Updating entry $entryId');

    final response = await _supabase
        .from('diary_entries')
        .update({
          'entry_date': entryDate.toIso8601String(),
          'content': content,
          'mood_icon': moodIcon,

          // ⭐ mantém sincronia com o calendário
          'day': entryDate.day,
          'month': entryDate.month,
          'year': entryDate.year,
        })
        .eq('id', entryId)
        .select()
        .single();

    print('DiaryService → Entry updated successfully');

    return DiaryEntryModel.fromJson(response);
  } catch (e) {
    print('DiaryService → Error updating entry: $e');
    rethrow;
  }
}


  /// Lista entradas por intervalo de datas
  static Future<List<DiaryEntryModel>> getEntriesByDateRange(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final response = await _supabase
          .from('diary_entries')
          .select()
          .eq('user_id', userId)
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
