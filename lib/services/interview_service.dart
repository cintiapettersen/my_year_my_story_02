import 'package:myyearmystory/supabase/supabase_config.dart';

class InterviewService {
  static final _client = SupabaseConfig.client;

  /// 🔹 Busca perguntas e texto inspiracional
  static Future<Map<String, dynamic>> getInterviewData(
    int month,
    String lang,
  ) async {
    final columnQuestions =
        lang == 'en' ? 'questions_en' : 'questions_pt';
    final columnText =
        lang == 'en' ? 'inspirational_text_en' : 'inspirational_text_pt';

    final response = await _client
        .from('interview_questions')
        .select('$columnText, $columnQuestions')
        .eq('month', month)
        .maybeSingle();

    if (response == null) {
   
      return {
        'description': '',
        'questions': <String>[],
      };
    }

    final description = response[columnText] ?? '';
    final questionsData = response[columnQuestions];

    final questions = questionsData is List
        ? List<String>.from(questionsData)
        : <String>[];

    return {
      'description': description,
      'questions': questions,
    };
  }

  /// 🔹 Busca respostas já salvas
  static Future<Map<String, dynamic>> getInterviewDataFromEntries(
    int month,
    int year,
    String userId,
  ) async {
    final response = await _client
        .from('entries')
        .select('interview_data, updated_at')
        .eq('user_id', userId)
        .eq('month', month)
        .eq('year', year)
        .maybeSingle();

    if (response == null || response['interview_data'] == null) {
      return {
        'person': {
          'name': '',
          'relation': '',
          'age': '',
        },
        'questions': [],
        'updated_at': response?['updated_at'],
      };
    }

    final payload = Map<String, dynamic>.from(response['interview_data']);
    payload['updated_at'] = response['updated_at'];
    return payload;
  }

  /// 🔹 Salva / atualiza entrevista
  static Future<void> saveInterviewAnswers({
    required List<String> questions,
    required List<String> answers,
    required int month,
    required int year,
    required String userId,
    required String interviewName,
    required String interviewRelation,
    required String interviewAge,
    String? createdAtIso,
  }) async {
    try {
      final createdAt = createdAtIso ?? DateTime.now().toIso8601String();
      final jsonData = {
        'created_at': createdAt,
        'person': {
          'name': interviewName,
          'relation': interviewRelation,
          'age': interviewAge,
        },
        'questions': List.generate(
          questions.length,
          (i) => {
            'q': questions[i],
            'a': i < answers.length ? answers[i] : '',
          },
        ),
      };

      await _client.from('entries').upsert(
        {
          'user_id': userId,
          'month': month,
          'year': year,
          'interview_data': jsonData,
          'updated_at': DateTime.now().toIso8601String(),
        },
        onConflict: 'user_id,month,year',
      );
    } catch (e) {
     
      rethrow; // ⬅️ importante
    }
  }

  /// 🗑️ Limpa entrevista
  static Future<void> clearInterviewData(
    int month,
    int year,
    String userId,
  ) async {
    try {
      await _client
          .from('entries')
          .update({'interview_data': null})
          .eq('user_id', userId)
          .eq('month', month)
          .eq('year', year);

     
    } catch (e) {
     
    }
  }
}
