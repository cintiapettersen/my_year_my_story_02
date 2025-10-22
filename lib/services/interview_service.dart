import 'package:my_year_my_story/supabase/supabase_config.dart';

class InterviewService {
  static final _supabase = SupabaseConfig.client;

  // Returns a map with keys: 'interviewee' (String?) and 'answers' (Map<String,String>)
  static Future<Map<String, dynamic>> getInterview(int month, int year, String userId) async {
    try {
      final row = await _supabase
          .from('entries')
          .select('interview')
          .eq('user_id', userId)
          .eq('month', month)
          .eq('year', year)
          .maybeSingle();

      if (row == null) return {'interviewee': null, 'answers': <String, String>{}};

      final data = row['interview'];
      if (data is Map) {
        final map = Map<String, dynamic>.from(data);
        final interviewee = map['interviewee']?.toString();
        final answersDyn = map['answers'];
        final answers = <String, String>{};
        if (answersDyn is Map) {
          answers.addAll(Map<String, dynamic>.from(answersDyn).map((k, v) => MapEntry(k, v?.toString() ?? '')));
        }
        return {'interviewee': interviewee, 'answers': answers};
      }

      return {'interviewee': null, 'answers': <String, String>{}};
    } catch (e) {
      print('Error fetching interview from entries: $e');
      return {'interviewee': null, 'answers': <String, String>{}};
    }
  }

  static Future<bool> saveInterview(String interviewee, Map<String, String> answers, int month, int year, String userId) async {
    try {
      final payload = {
        'interviewee': interviewee,
        'answers': answers,
      };

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
          'interview': payload,
        });
      } else {
        await _supabase
            .from('entries')
            .update({'interview': payload})
            .eq('user_id', userId)
            .eq('month', month)
            .eq('year', year);
      }
      return true;
    } catch (e) {
      print('Error saving interview to entries: $e');
      return false;
    }
  }
}
