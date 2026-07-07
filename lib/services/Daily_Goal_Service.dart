import 'package:myyearmystory/supabase/supabase_config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class DailyGoalService {
  static final _supabase = SupabaseConfig.client;

  static String _guestPrefsKey({
    required int month,
    required int year,
  }) =>
      'guest_daily_goals_${year}_${month.toString().padLeft(2, '0')}';

  static Future<List<Map<String, dynamic>>> _getGuestGoals({
    required int month,
    required int year,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_guestPrefsKey(month: month, year: year));
    if (raw == null || raw.trim().isEmpty) return <Map<String, dynamic>>[];

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return <Map<String, dynamic>>[];
      final out = <Map<String, dynamic>>[];
      for (final item in decoded) {
        if (item is Map) {
          out.add(Map<String, dynamic>.from(item));
        }
      }
      return out;
    } catch (_) {
      return <Map<String, dynamic>>[];
    }
  }

  static Future<void> _setGuestGoals({
    required int month,
    required int year,
    required List<Map<String, dynamic>> goals,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _guestPrefsKey(month: month, year: year),
      jsonEncode(goals),
    );
  }

  static String _newGuestId() =>
      'g_${DateTime.now().microsecondsSinceEpoch}';

  // --------------------------------------------------
  // 🔄 Buscar metas diárias por mês
  // --------------------------------------------------
  static Future<List<Map<String, dynamic>>> getAllByMonth({
    required int month,
    required int year,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      final local = await _getGuestGoals(month: month, year: year);
      local.sort((a, b) {
        final dateA = (a['date'] ?? '').toString();
        final dateB = (b['date'] ?? '').toString();
        final c = dateB.compareTo(dateA); // desc
        if (c != 0) return c;
        final createdA = (a['created_at'] ?? '').toString();
        final createdB = (b['created_at'] ?? '').toString();
        return createdB.compareTo(createdA); // desc
      });
      return local;
    }

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
    if (user == null) {
      final month = date.month;
      final year = date.year;
      final existing = await _getGuestGoals(month: month, year: year);
      final now = DateTime.now().toIso8601String();
      existing.add({
        'id': _newGuestId(),
        'user_id': 'guest',
        'date': _formatDate(date),
        'content': content,
        'completed': false,
        'created_at': now,
      });
      await _setGuestGoals(month: month, year: year, goals: existing);
      return;
    }

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
    int? month,
    int? year,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      final now = DateTime.now();
      final m = month ?? now.month;
      final y = year ?? now.year;
      final existing = await _getGuestGoals(month: m, year: y);
      final idx = existing.indexWhere(
        (g) => (g['id'] ?? '').toString() == goalId,
      );
      if (idx == -1) return;
      final updated = Map<String, dynamic>.from(existing[idx]);
      updated['completed'] = completed;
      existing[idx] = updated;
      await _setGuestGoals(month: m, year: y, goals: existing);
      return;
    }

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
  static Future<void> deleteGoal(
    String goalId, {
    int? month,
    int? year,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      final now = DateTime.now();
      final m = month ?? now.month;
      final y = year ?? now.year;
      final existing = await _getGuestGoals(month: m, year: y);
      final updated = existing
          .where((g) => (g['id'] ?? '').toString() != goalId)
          .toList();
      await _setGuestGoals(month: m, year: y, goals: updated);
      return;
    }

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
