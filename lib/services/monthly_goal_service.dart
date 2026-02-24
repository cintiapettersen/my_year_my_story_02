import 'package:myyearmystory/models/monthly_goal_model.dart';
import 'package:myyearmystory/supabase/supabase_config.dart';

class MonthlyGoalService {
  static final _supabase = SupabaseConfig.client;

  // =====================================================
  // FETCH — metas do mês
  // - Guest → retorna lista vazia
  // =====================================================
  static Future<List<MonthlyGoal>> getGoalsByMonth({
    required int mes,
    required int ano,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return [];

      final response = await _supabase
          .from('metas')
          .select()
          .eq('user_id', user.id)
          .eq('mes', mes)
          .eq('ano', ano)
          .order('created_at', ascending: false);

      return (response as List)
          .map((e) => MonthlyGoal.fromJson(e))
          .toList();
    } catch (e) {
      return [];
    }
  }

  // =====================================================
  // CREATE — nova meta
  // - Guest → retorna null
  // =====================================================
  static Future<MonthlyGoal?> createGoal({
    required int mes,
    required int ano,
    required String conteudo,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return null;

      final response = await _supabase
          .from('metas')
          .insert({
            'user_id': user.id,
            'mes': mes,
            'ano': ano,
            'conteudo': conteudo,
            'concluida': false,
          })
          .select()
          .single();

      return MonthlyGoal.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  // =====================================================
  // UPDATE — meta existente
  // - Guest → retorna null
  // =====================================================
  static Future<MonthlyGoal?> updateGoal({
    required String goalId,
    required String conteudo,
    required bool concluido,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return null;

      final response = await _supabase
          .from('metas')
          .update({
            'conteudo': conteudo,
            'concluida': concluido,
          })
          .eq('id', goalId)
          .eq('user_id', user.id)
          .select()
          .single();

      return MonthlyGoal.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  // =====================================================
  // DELETE — meta
  // - Guest → retorna false
  // =====================================================
  static Future<bool> deleteGoal(String goalId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      await _supabase
          .from('metas')
          .delete()
          .eq('id', goalId)
          .eq('user_id', user.id);

      return true;
    } catch (e) {
      return false;
    }
  }
}
