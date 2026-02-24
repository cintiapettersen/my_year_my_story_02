import 'package:myyearmystory/supabase/supabase_config.dart';

class DailyGoalService {
  static final _supabase = SupabaseConfig.client;

  // --------------------------------------------------
  // 🔄 Buscar metas diárias por mês
  // --------------------------------------------------
  static Future<List<Map<String, dynamic>>> getAllByMonth({
    required int month,
    required int year,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];

    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 0);

    final startDate = _formatDate(start);
    final endDate = _formatDate(end);

    try {
      final response = await _supabase
          .from('daily_goals')
          .select()
          .eq('user_id', user.id)
          .gte('date', startDate)
          .lte('date', endDate)
          .order('date', ascending: false)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  // --------------------------------------------------
  // ➕ Criar meta diária
  // --------------------------------------------------
  static Future<void> createGoal({
    required DateTime date,
    required String content,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      await _supabase.from('daily_goals').insert({
        'user_id': user.id,
        'date': _formatDate(date), // YYYY-MM-DD
        'content': content,
        'completed': false,
      });
    } catch (e) {}
  }

  // --------------------------------------------------
  // ✔️ Marcar como concluída
  // --------------------------------------------------
  static Future<void> toggleCompleted({
    required String goalId,
    required bool completed,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      await _supabase
          .from('daily_goals')
          .update({'completed': completed})
          .eq('id', goalId)
          .eq('user_id', user.id);
    } catch (e) {}
  }

  // --------------------------------------------------
  // 🗑️ Excluir meta
  // --------------------------------------------------
  static Future<void> deleteGoal(String goalId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      await _supabase
          .from('daily_goals')
          .delete()
          .eq('id', goalId)
          .eq('user_id', user.id);
    } catch (e) {}
  }

  // --------------------------------------------------
  // 🧩 Helper — formata DateTime para YYYY-MM-DD
  // --------------------------------------------------
  static String _formatDate(DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    return d.toIso8601String().split('T').first;
  }
}
