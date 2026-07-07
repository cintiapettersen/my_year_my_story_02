import 'package:myyearmystory/supabase/supabase_config.dart';

class InterviewAudioService {
  static final _supabase = SupabaseConfig.client;

  static Future<List<Map<String, dynamic>>> listForMonth({
    required String userId,
    required int month,
    required int year,
  }) async {
    try {
      final rows = await _supabase
          .from('interview_audio')
          .select('question_index, storage_path, mime_type, duration_seconds')
          .eq('user_id', userId)
          .eq('month', month)
          .eq('year', year);

      return List<Map<String, dynamic>>.from(rows);
    } catch (_) {
      return <Map<String, dynamic>>[];
    }
  }

  static Future<bool> upsertAudio({
    required String userId,
    required int month,
    required int year,
    required int questionIndex,
    required String storagePath,
    String? mimeType,
    int? durationSeconds,
  }) async {
    try {
      await _supabase.from('interview_audio').upsert(
        {
          'user_id': userId,
          'month': month,
          'year': year,
          'question_index': questionIndex,
          'storage_path': storagePath,
          'mime_type': mimeType,
          'duration_seconds': durationSeconds,
        },
        onConflict: 'user_id,year,month,question_index',
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> deleteAudio({
    required String userId,
    required int month,
    required int year,
    required int questionIndex,
  }) async {
    try {
      await _supabase
          .from('interview_audio')
          .delete()
          .eq('user_id', userId)
          .eq('month', month)
          .eq('year', year)
          .eq('question_index', questionIndex);
      return true;
    } catch (_) {
      return false;
    }
  }
}
