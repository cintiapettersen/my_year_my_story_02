import 'package:myyearmystory/supabase/supabase_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GratitudeService {
  static final _supabase = SupabaseConfig.client;

  static String _guestPrefsKey({
    required int month,
    required int year,
  }) =>
      'guest_gratitude_${year}_${month.toString().padLeft(2, '0')}';

  /// 🔎 Busca a lista de gratidão do mês
  /// - Guest → busca local (SharedPreferences)
  /// - Usuário logado → busca no banco
  static Future<List<String>> getGratitudeList(
    int month,
    int year,
  ) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        final prefs = await SharedPreferences.getInstance();
        return prefs.getStringList(
              _guestPrefsKey(month: month, year: year),
            ) ??
            <String>[];
      }

      final row = await _supabase
          .from('entries')
          .select('gratitude_entries')
          .eq('user_id', user.id)
          .eq('month', month)
          .eq('year', year)
          .maybeSingle();

      if (row == null) return <String>[];

      final data = row['gratitude_entries'];
      if (data is List) {
        return List<String>.from(data);
      }

      return <String>[];
    } catch (e) {
      return <String>[];
    }
  }

  /// 💾 Salva a lista de gratidão
  /// - Guest → salva local (SharedPreferences)
  /// - Usuário logado → insere ou atualiza
  static Future<bool> saveGratitudeList(
    List<String> items,
    int month,
    int year,
  ) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setStringList(
          _guestPrefsKey(month: month, year: year),
          items,
        );
        return true;
      }

      final existing = await _supabase
          .from('entries')
          .select('id')
          .eq('user_id', user.id)
          .eq('month', month)
          .eq('year', year)
          .maybeSingle();

      if (existing == null) {
        await _supabase.from('entries').insert({
          'user_id': user.id,
          'month': month,
          'year': year,
          'gratitude_entries': items,
        });
      } else {
        await _supabase
            .from('entries')
            .update({'gratitude_entries': items})
            .eq('user_id', user.id)
            .eq('month', month)
            .eq('year', year);
      }

      return true;
    } catch (e) {
      return false;
    }
  }
}
