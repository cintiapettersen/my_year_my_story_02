import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:myyearmystory/supabase/supabase_config.dart';

class CalendarEventService {
  static final _client = SupabaseConfig.client;

  static Future<String?> createEvent({
    required String userId,
    required int year,
    required int month,
    required int day,
    required String title,
    String? description,
    bool remind = false,
    String repeatType = 'none',
    String? category,
    String? color,
    String? emoji,
  }) async {
    try {
      final response = await _client.from('calendar_events').insert({
        'user_id': userId,
        'year': year,
        'month': month,
        'day': day,
        'title': title,
        'description': description,
        'remind': remind,
        'repeat_type': repeatType,
        'category': category,
        'color': color,
        'emoji': emoji,
      }).select('id').single();

      return response['id'];
    } catch (e) {
      print('❌ createEvent error: $e');
      return null;
    }
  }
}
