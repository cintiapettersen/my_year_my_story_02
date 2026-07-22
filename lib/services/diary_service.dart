import 'package:myyearmystory/models/diary_entry.dart';
import 'package:myyearmystory/supabase/supabase_config.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class DiaryService {
  static final _supabase = SupabaseConfig.client;

  // ===============================
  // DELETE ENTRY
  // ===============================
  static Future<void> deleteEntry(String entryId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      await _supabase
          .from('diary_entries')
          .delete()
          .eq('id', entryId)
          .eq('user_id', user.id);
    } catch (e) {
      rethrow;
    }
  }

  // ===============================
  // GET ALL ENTRIES
  // ===============================
  static Future<List<DiaryEntryModel>> getEntries() async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      return [];
    }

    try {
      final response = await _supabase
          .from('diary_entries')
          .select()
          .eq('user_id', user.id)
          .order('entry_date', ascending: false);

      final entries =
          (response as List)
              .map((entry) => DiaryEntryModel.fromJson(entry))
              .toList();

      return entries;
    } catch (e) {
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
      final response =
          await _supabase
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

      return DiaryEntryModel.fromJson(response);
    } catch (e) {
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

      final response =
          await _supabase
              .from('diary_entries')
              .update(updateData)
              .eq('id', entryId)
              .eq('user_id', user.id)
              .select()
              .single();

      return DiaryEntryModel.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  //
  // generate Diario

  static Future<String?> generateDiaryWithAI(String prompt) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw Exception('Guest cannot use AI diary');
    }

    final session = _supabase.auth.currentSession;
    final accessToken = session?.accessToken;

    if (accessToken == null) {
      throw Exception('No access token found');
    }

    final url =
        'https://abrctowsfsgfxdoszmdq.functions.supabase.co/generate-diary';

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
      body: jsonEncode({'prompt': prompt}),
    );

    if (response.statusCode != 200) {
      throw Exception('AI request failed');
    }

    final data = jsonDecode(response.body);

    final text =
        data['raw']?['candidates']?[0]?['content']?['parts']?[0]?['text'];
    return text;
  }

  // ===============================
  // GET ENTRIES BY DATE RANGE
  // ===============================
  static Future<List<DiaryEntryModel>> getEntriesByDateRange(
    DateTime startDate,
    DateTime endDateExclusive,
  ) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];

    try {
      final response = await _supabase
          .from('diary_entries')
          .select()
          .eq('user_id', user.id)
          .gte('entry_date', startDate.toIso8601String())
          .lt('entry_date', endDateExclusive.toIso8601String())
          .order('entry_date', ascending: false);

      return (response as List)
          .map((entry) => DiaryEntryModel.fromJson(entry))
          .toList();
    } catch (e) {
      rethrow;
    }
  }
}
