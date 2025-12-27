import 'package:shared_preferences/shared_preferences.dart';
import 'package:myyearmystory/supabase/supabase_config.dart';
import 'package:myyearmystory/utils/access_control.dart';

/// =============================================================
/// 🌸 GUEST CALENDAR LIMIT
/// =============================================================
class GuestCalendarLimit {
  static const _key = 'guest_calendar_event_count';
  static const maxFree = 2;

  static Future<int> getCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_key) ?? 0;
  }

  static Future<bool> canCreate() async {
    final count = await getCount();
    return count < maxFree;
  }

  static Future<void> increment() async {
    final prefs = await SharedPreferences.getInstance();
    final count = prefs.getInt(_key) ?? 0;
    await prefs.setInt(_key, count + 1);
  }
}

/// =============================================================
/// 🌸 CALENDAR EVENT SERVICE
/// =============================================================
class CalendarEventService {
  /// ---------------------------------------------------------
  /// 1) CREATE EVENT
  /// ---------------------------------------------------------
  static Future<String?> createEvent({
    required String userId,
    required int year,
    required int month,
    required int day,
    required String title,
    String? description,
    required String color,
    required int hour,
    bool remind = true,
    String repeatType = 'none',
    List<String>? repeatDays,
    int daysBefore = 0,
  }) async {
    final response = await SupabaseConfig.client
        .from('calendar_events')
        .insert({
          'user_id': userId,
          'year': year,
          'month': month,
          'day': day,
          'hour': hour,
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
  }

  /// ---------------------------------------------------------
  /// 2) UPDATE EVENT
  /// ---------------------------------------------------------
  static Future<bool> updateEvent({
    required String eventId,
    required String title,
    required String color,
    String? description,
    required int hour,
    bool remind = true,
    String repeatType = 'none',
    List<String>? repeatDays,
    int daysBefore = 0,
  }) async {
    await SupabaseConfig.client
        .from('calendar_events')
        .update({
          'title': title,
          'description': description,
          'color': color,
          'hour': hour,
          'remind': remind,
          'repeat_type': repeatType,
          'repeat_days': repeatDays ?? <String>[],
          'days_before': daysBefore,
        })
        .eq('id', eventId);

    return true;
  }

  /// ---------------------------------------------------------
  /// 3) CREATE OR UPDATE (GUEST + USER)
  /// ---------------------------------------------------------
  static Future<bool> saveOrUpdateEvent({
    required String? existingId,
    required String? userId,
    required int year,
    required int month,
    required int day,
    required int hour,
    required String title,
    required String color,
    String? description,
    bool remind = true,
    String repeatType = 'none',
    List<String>? repeatDays,
    int daysBefore = 0,
  }) async {
    /// 👤 GUEST
    if (userId == null) {
      if (existingId != null) return false;

      final canCreate = await GuestCalendarLimit.canCreate();
      if (!canCreate) return false;

      await GuestCalendarLimit.increment();
      return true;
    }

    /// 👤 USER (FREE / PREMIUM)
    final isPremium = await AccessControl.isPremium();

    if (!isPremium && existingId == null) {
      final count =
          await countUserEventsForMonth(userId, year, month);
      if (count >= 3) return false;
    }

    if (existingId == null) {
      await createEvent(
        userId: userId,
        year: year,
        month: month,
        day: day,
        hour: hour,
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

    return await updateEvent(
      eventId: existingId,
      title: title,
      description: description,
      color: color,
      hour: hour,
      remind: remind,
      repeatType: repeatType,
      repeatDays: repeatDays,
      daysBefore: daysBefore,
    );
  }

  /// ---------------------------------------------------------
  /// 4) EVENTS FOR DAY (MULTIPLE)
  /// ---------------------------------------------------------
  static Future<List<Map<String, dynamic>>> getEventsForDay({
    required String userId,
    required int year,
    required int month,
    required int day,
  }) async {
    final res = await SupabaseConfig.client
        .from('calendar_events')
        .select()
        .eq('user_id', userId)
        .eq('year', year)
        .eq('month', month)
        .eq('day', day)
        .order('hour');

    return List<Map<String, dynamic>>.from(res);
  }

  
  /// ---------------------------------------------------------
/// 5) EVENTS FOR MONTH (ORDERED + REPEAT EXPANSION)
/// ---------------------------------------------------------
static Future<List<Map<String, dynamic>>> getEventsForMonth({
  required String userId,
  required int year,
  required int month,
}) async {
  final res = await SupabaseConfig.client
      .from('calendar_events')
      .select()
      .eq('user_id', userId)
      .eq('year', year)
      .eq('month', month)
      .order('day')
      .order('hour');

  final List<Map<String, dynamic>> baseEvents =
      List<Map<String, dynamic>>.from(res);

  final List<Map<String, dynamic>> expandedEvents = [];

  final daysInMonth = DateTime(year, month + 1, 0).day;

  for (final e in baseEvents) {
    expandedEvents.add(e);

    final repeatType = e['repeat_type'] ?? 'none';
    final int startDay = e['day'];

    if (repeatType == 'daily') {
      for (int d = startDay + 1; d <= daysInMonth; d++) {
        expandedEvents.add({
          ...e,
          'day': d,
          'id': '${e['id']}_$d', // id fake (UI only)
        });
      }
    }

    if (repeatType == 'weekly') {
      final baseDate = DateTime(year, month, startDay);
      final weekday = baseDate.weekday;

      for (int d = 1; d <= daysInMonth; d++) {
        final date = DateTime(year, month, d);
        if (date.weekday == weekday && d != startDay) {
          expandedEvents.add({
            ...e,
            'day': d,
            'id': '${e['id']}_$d',
          });
        }
      }
    }

    if (repeatType == 'monthly') {
      // neste MVP, monthly = aparece só neste mês (já é o próprio evento)
      // preparado para evoluir depois
    }
  }

  expandedEvents.sort((a, b) {
    final dayCompare = a['day'].compareTo(b['day']);
    if (dayCompare != 0) return dayCompare;
    return a['hour'].compareTo(b['hour']);
  });

  return expandedEvents;
}


  /// ---------------------------------------------------------
  /// 6) COUNT EVENTS (MONTH)
  /// ---------------------------------------------------------
  static Future<int> countUserEventsForMonth(
    String userId,
    int year,
    int month,
  ) async {
    final res = await SupabaseConfig.client
        .from('calendar_events')
        .select('id')
        .eq('user_id', userId)
        .eq('year', year)
        .eq('month', month);

    return res.length;
  }

  /// ---------------------------------------------------------
  /// 7) DELETE EVENT
  /// ---------------------------------------------------------
  static Future<bool> deleteEvent(String eventId) async {
    await SupabaseConfig.client
        .from('calendar_events')
        .delete()
        .eq('id', eventId);

    return true;
  }
}
