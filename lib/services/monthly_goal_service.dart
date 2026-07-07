import 'package:myyearmystory/models/monthly_goal_model.dart';
import 'package:myyearmystory/supabase/supabase_config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class MonthlyGoalService {
  static final _supabase = SupabaseConfig.client;

  static String _guestPrefsKey({
    required int mes,
    required int ano,
  }) =>
      'guest_monthly_goals_${ano}_${mes.toString().padLeft(2, '0')}';

  static Future<List<MonthlyGoal>> _getGuestGoals({
    required int mes,
    required int ano,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_guestPrefsKey(mes: mes, ano: ano));
    if (raw == null || raw.trim().isEmpty) return <MonthlyGoal>[];

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return <MonthlyGoal>[];
      final out = <MonthlyGoal>[];
      for (final item in decoded) {
        if (item is Map) {
          out.add(MonthlyGoal.fromJson(Map<String, dynamic>.from(item)));
        }
      }
      return out;
    } catch (_) {
      return <MonthlyGoal>[];
    }
  }

  static Future<void> _setGuestGoals({
    required int mes,
    required int ano,
    required List<MonthlyGoal> goals,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final payload = goals.map((g) => g.toJson()).toList(growable: false);
    await prefs.setString(
      _guestPrefsKey(mes: mes, ano: ano),
      jsonEncode(payload),
    );
  }

  static String _newGuestId() =>
      'g_${DateTime.now().microsecondsSinceEpoch}';

  // =====================================================
  // FETCH — metas do mês
  // - Guest → busca local (SharedPreferences)
  // =====================================================
  static Future<List<MonthlyGoal>> getGoalsByMonth({
    required int mes,
    required int ano,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        final local = await _getGuestGoals(mes: mes, ano: ano);
        local.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return local;
      }

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
  // - Guest → salva local (SharedPreferences)
  // =====================================================
  static Future<MonthlyGoal?> createGoal({
    required int mes,
    required int ano,
    required String conteudo,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        final existing = await _getGuestGoals(mes: mes, ano: ano);
        final goal = MonthlyGoal(
          id: _newGuestId(),
          userId: 'guest',
          mes: mes,
          ano: ano,
          conteudo: conteudo,
          concluido: false,
          createdAt: DateTime.now(),
        );
        final updated = [goal, ...existing];
        await _setGuestGoals(mes: mes, ano: ano, goals: updated);
        return goal;
      }

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
  // - Guest → salva local (SharedPreferences)
  // =====================================================
  static Future<MonthlyGoal?> updateGoal({
    required String goalId,
    required String conteudo,
    required bool concluido,
    int? mes,
    int? ano,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        final now = DateTime.now();
        final m = mes ?? now.month;
        final y = ano ?? now.year;

        final existing = await _getGuestGoals(mes: m, ano: y);
        final idx = existing.indexWhere((g) => g.id == goalId);
        if (idx == -1) return null;

        final updatedGoal = existing[idx].copyWith(
          conteudo: conteudo,
          concluido: concluido,
        );
        final updated = [...existing]..[idx] = updatedGoal;
        await _setGuestGoals(mes: m, ano: y, goals: updated);
        return updatedGoal;
      }

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
  // - Guest → salva local (SharedPreferences)
  // =====================================================
  static Future<bool> deleteGoal(
    String goalId, {
    int? mes,
    int? ano,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        final now = DateTime.now();
        final m = mes ?? now.month;
        final y = ano ?? now.year;

        final existing = await _getGuestGoals(mes: m, ano: y);
        final updated = existing.where((g) => g.id != goalId).toList();
        await _setGuestGoals(mes: m, ano: y, goals: updated);
        return true;
      }

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
