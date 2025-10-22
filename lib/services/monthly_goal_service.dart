import 'package:my_year_my_story/models/monthly_goal_model.dart';
import 'package:my_year_my_story/supabase/supabase_config.dart';

class MonthlyGoalService {
  static final _supabase = SupabaseConfig.client;

  /// Lista todas as metas do usuário
  static Future<List<MonthlyGoal>> getGoals(String userId) async {
    try {
      print('MonthlyGoalService: Fetching goals for user $userId');
      final response = await _supabase
          .from('metas')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      print('MonthlyGoalService: Raw response: $response');
      return (response as List)
          .map((goal) => MonthlyGoal.fromJson(goal))
          .toList();
    } catch (e) {
      print('MonthlyGoalService: Error fetching goals: $e');
      rethrow;
    }
  }

  /// Lista metas de um mês específico
  static Future<List<MonthlyGoal>> getGoalsByMonth(
    int mes,
    int ano,
    String userId,
  ) async {
    try {
      print('MonthlyGoalService: Fetching goals for user $userId, mês $mes, ano $ano');
      final response = await _supabase
          .from('metas')
          .select()
          .eq('user_id', userId)
          .eq('mes', mes)
          .eq('ano', ano)
          .order('created_at', ascending: false);

      print('MonthlyGoalService: Raw response: $response');
      return (response as List)
          .map((goal) => MonthlyGoal.fromJson(goal))
          .toList();
    } catch (e) {
      print('MonthlyGoalService: Error fetching goals by month: $e');
      rethrow;
    }
  }

  /// Cria uma nova meta
  static Future<MonthlyGoal> createGoal(
    String userId,
    int mes,
    int ano,
    String conteudo,
    bool concluido,
    DateTime createdAt,
  ) async {
    try {
      print('MonthlyGoalService: Creating goal for user $userId');
      print('MonthlyGoalService: Mês: $mes, Ano: $ano, Conteúdo: $conteudo');

      // Primeiro, vamos testar se conseguimos fazer um SELECT na tabela
      try {
        final testSelect = await _supabase.from('metas').select().limit(1);
        print('MonthlyGoalService: Test SELECT successful: $testSelect');
      } catch (selectError) {
        print('MonthlyGoalService: Test SELECT failed: $selectError');
        throw Exception('Problema de conexão ou permissão na tabela metas: $selectError');
      }

      // Agora tentamos o INSERT sem a coluna created_at primeiro
      final response = await _supabase
          .from('metas')
          .insert({
            'user_id': userId,
            'mes': mes,
            'ano': ano,
            'conteudo': conteudo,
            'concluida': concluido,
          })
          .select()
          .single();

      print('MonthlyGoalService: Goal created successfully: ${response['id']}');
      return MonthlyGoal.fromJson(response);
    } catch (e) {
      print('MonthlyGoalService: Error creating goal: $e');
      rethrow;
    }
  }

  /// Atualiza uma meta existente
  static Future<MonthlyGoal> updateGoal(
    String goalId,
    String conteudo,
    bool concluido,
  ) async {
    try {
      print('MonthlyGoalService: Updating goal $goalId');
      final response = await _supabase
          .from('metas')
          .update({
            'conteudo': conteudo,
            'concluida': concluido,
          })
          .eq('id', goalId)
          .select()
          .single();

      print('MonthlyGoalService: Goal updated successfully');
      return MonthlyGoal.fromJson(response);
    } catch (e) {
      print('MonthlyGoalService: Error updating goal: $e');
      rethrow;
    }
  }

  /// Exclui uma meta
  static Future<void> deleteGoal(String goalId) async {
    try {
      print('MonthlyGoalService: Deleting goal $goalId');
      await _supabase.from('metas').delete().eq('id', goalId);
      print('MonthlyGoalService: Goal deleted successfully');
    } catch (e) {
      print('MonthlyGoalService: Error deleting goal: $e');
      rethrow;
    }
  }
}
