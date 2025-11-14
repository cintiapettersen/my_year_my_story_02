import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:myyearmystory/supabase/supabase_config.dart';
import 'package:flutter/material.dart';

class InterviewService {
  static final _client = SupabaseConfig.client;

  /// 🔹 Busca perguntas e texto inspiracional (tabela: interview_questions)
  static Future<Map<String, dynamic>> getInterviewData(int month, String lang) async {
    try {
      final columnQuestions = lang == 'en' ? 'questions_en' : 'questions_pt';
      final columnText =
      lang == 'en' ? 'inspirational_text_en' : 'inspirational_text_pt';

      final response = await _client
          .from('interview_questions')
          .select('$columnText, $columnQuestions')
          .eq('month', month)
          .maybeSingle();

      if (response == null) {
        debugPrint('⚠️ Nenhum registro encontrado para o mês $month');
        return {'description': '', 'questions': []};
      }

      final description = response[columnText] ?? '';
      final questionsData = response[columnQuestions];
      final questions = questionsData is List ? List<String>.from(questionsData) : [];

      return {
        'description': description,
        'questions': questions,
      };
    } catch (e) {
      debugPrint('❌ Erro ao buscar perguntas: $e');
      return {'description': '', 'questions': []};
    }
  }

  /// 🔹 Busca respostas já salvas (campo interview_data - formato JSON)
  static Future<Map<String, dynamic>> getInterviewDataFromEntries(
      int month, int year, String userId) async {
    try {
      final response = await _client
          .from('entries')
          .select('interview_data')
          .eq('user_id', userId)
          .eq('month', month)
          .eq('year', year)
          .maybeSingle();

      if (response == null || response['interview_data'] == null) {
        return {
          'person': {'name': '', 'relation': '', 'age': ''},
          'questions': [],
        };
      }

      return Map<String, dynamic>.from(response['interview_data']);
    } catch (e) {
      debugPrint('❌ Erro ao carregar entrevista: $e');
      return {
        'person': {'name': '', 'relation': '', 'age': ''},
        'questions': [],
      };
    }
  }

  /// 🔹 Salva ou atualiza respostas (em JSON no campo interview_data)
  static Future<void> saveInterviewAnswers({
    required List<String> questions,
    required List<String> answers,
    required int month,
    required int year,
    required String userId,
    required String interviewName,
    required String interviewRelation,
    required String interviewAge,
  }) async {
    try {
      final jsonData = {
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
      debugPrint('❌ Erro ao salvar entrevista: $e');
      rethrow;
    }
  }

  /// 🗑️ (Opcional) Função para limpar entrevista de um mês específico
  static Future<void> clearInterviewData(
      int month, int year, String userId) async {
    try {
      await _client
          .from('entries')
          .update({'interview_data': null})
          .eq('user_id', userId)
          .eq('month', month)
          .eq('year', year);
      debugPrint('🧹 Entrevista limpa com sucesso!');
    } catch (e) {
      debugPrint('❌ Erro ao limpar entrevista: $e');
    }
  }
}
