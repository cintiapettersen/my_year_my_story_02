import 'package:myyearmystory/supabase/supabase_config.dart';

/// =============================================================
/// 🌸 CALENDAR EVENT SERVICE
/// 
/// Responsável por criar, atualizar, excluir e buscar eventos
/// no calendário do app My Year, My Story.
///
/// Compatível com o schema:
/// - repeat_type (text)
/// - repeat_days (text[])
/// - days_before (integer)
/// - color (text)
/// - category, emoji (ignorados)
///
/// =============================================================
class CalendarEventService {
  /// ---------------------------------------------------------
  /// 1) CRIAR EVENTO
  /// ---------------------------------------------------------
  static Future<String?> createEvent({
    required String userId,
    required int year,
    required int month,
    required int day,
    required String title,
    String? description,
    required String color,
    bool remind = true,
    String repeatType = 'none',
    List<String>? repeatDays,
    int daysBefore = 0,
  }) async {
    try {
      final response = await SupabaseConfig.client
          .from('calendar_events')
          .insert({
            'user_id': userId,
            'year': year,
            'month': month,
            'day': day,
            'title': title,
            'description': description,
            'color': color,
            'remind': remind,
            'repeat_type': repeatType,
            'repeat_days': repeatDays ?? <String>[],
            'days_before': daysBefore,
          })
          .select('id')
          .single();

      return response['id'];
    } catch (e) {
      print("❌ createEvent error: $e");
      return null;
    }
  }

  /// ---------------------------------------------------------
  /// 2) ATUALIZAR EVENTO EXISTENTE
  /// ---------------------------------------------------------
  static Future<bool> updateEvent({
    required String eventId,
    required String title,
    required String color,
    String? description,
    bool remind = true,
    String repeatType = 'none',
    List<String>? repeatDays,
    int daysBefore = 0,
  }) async {
    try {
      await SupabaseConfig.client
          .from('calendar_events')
          .update({
            'title': title,
            'description': description,
            'color': color,
            'remind': remind,
            'repeat_type': repeatType,
            'repeat_days': repeatDays ?? <String>[],
            'days_before': daysBefore,
          })
          .eq('id', eventId);

      return true;
    } catch (e) {
      print("❌ updateEvent error: $e");
      return false;
    }
  }

  /// ---------------------------------------------------------
  /// 3) CRIAR OU ATUALIZAR AUTOMATICAMENTE
  /// ---------------------------------------------------------
  static Future<bool> saveOrUpdateEvent({
    required String? existingId,
    required String userId,
    required int year,
    required int month,
    required int day,
    required String title,
    required String color,
    String? description,
    bool remind = true,
    String repeatType = 'none',
    List<String>? repeatDays,
    int daysBefore = 0,
  }) async {
    // NOVO ALERTA
    if (existingId == null) {
      await createEvent(
        userId: userId,
        year: year,
        month: month,
        day: day,
        title: title,
        description: description,
        color: color,
        remind: remind,
        repeatType: repeatType,
        repeatDays: repeatDays,
        daysBefore: daysBefore,
      );
      return true;
    }

    // ATUALIZAÇÃO DE ALERTA EXISTENTE
    return await updateEvent(
      eventId: existingId,
      title: title,
      description: description,
      color: color,
      remind: remind,
      repeatType: repeatType,
      repeatDays: repeatDays,
      daysBefore: daysBefore,
    );
  }

  /// ---------------------------------------------------------
  /// 4) BUSCAR EVENTO ESPECÍFICO POR DIA
  /// ---------------------------------------------------------
  static Future<Map<String, dynamic>?> getEventForDay({
    required String userId,
    required int year,
    required int month,
    required int day,
  }) async {
    try {
      final result = await SupabaseConfig.client
          .from('calendar_events')
          .select()
          .eq('user_id', userId)
          .eq('year', year)
          .eq('month', month)
          .eq('day', day)
          .maybeSingle();

      return result;
    } catch (e) {
      print("❌ getEventForDay error: $e");
      return null;
    }
  }

  /// ---------------------------------------------------------
  /// 5) BUSCAR EVENTOS DO MÊS
  /// ---------------------------------------------------------
  static Future<List<Map<String, dynamic>>> getEventsForMonth({
    required String userId,
    required int year,
    required int month,
  }) async {
    try {
      final response = await SupabaseConfig.client
          .from('calendar_events')
          .select()
          .eq('user_id', userId)
          .eq('year', year)
          .eq('month', month)
          .order('day');

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print("❌ getEventsForMonth error: $e");
      return [];
    }
  }

  /// ---------------------------------------------------------
  /// 6) DELETAR EVENTO
  /// ---------------------------------------------------------
  static Future<bool> deleteEvent(String eventId) async {
    try {
      await SupabaseConfig.client
          .from('calendar_events')
          .delete()
          .eq('id', eventId);

      return true;
    } catch (e) {
      print("❌ deleteEvent error: $e");
      return false;
    }
  }
}
