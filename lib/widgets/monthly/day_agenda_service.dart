import 'package:myyearmystory/supabase/supabase_config.dart';

class DayAgendaService {
  static const String table = 'day_agenda_entries';

  /// ------------------------------------------------------------
  /// GET entries for a specific day
  /// ------------------------------------------------------------
  static Future<List<Map<String, dynamic>>> getEntriesForDay({
    required String userId,
    required int year,
    required int month,
    required int day,
  }) async {
    final res = await SupabaseConfig.client
        .from(table)
        .select()
        .eq('user_id', userId)
        .eq('year', year)
        .eq('month', month)
        .eq('day', day)
        .order('hour')
        .order('minute');

    return List<Map<String, dynamic>>.from(res);
  }

  /// ------------------------------------------------------------
  /// CREATE new agenda entry
  /// ------------------------------------------------------------
  static Future<void> createEntry({
    required String userId,
    required int year,
    required int month,
    required int day,
    required int hour,
    int minute = 0,
    required String note,
  }) async {
    await SupabaseConfig.client.from(table).insert({
      'user_id': userId,
      'year': year,
      'month': month,
      'day': day,
      'hour': hour,
      'minute': minute,
      'note': note,
    });
  }

  /// ------------------------------------------------------------
  /// UPDATE existing agenda entry
  /// ------------------------------------------------------------
  static Future<void> updateEntry({
    required String entryId,
    required int hour,
    int minute = 0,
    required String note,
  }) async {
    await SupabaseConfig.client
        .from(table)
        .update({
          'hour': hour,
          'minute': minute,
          'note': note,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', entryId);
  }

  /// ------------------------------------------------------------
  /// DELETE agenda entry
  /// ------------------------------------------------------------
  static Future<void> deleteEntry({
    required String entryId,
  }) async {
    await SupabaseConfig.client
        .from(table)
        .delete()
        .eq('id', entryId);
  }
}
