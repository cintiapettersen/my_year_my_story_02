import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';

class StorageService {
  final _supabase = Supabase.instance.client;

  /// Salvar dados (automático: local ou remoto)
  Future<void> saveData(String key, Map<String, dynamic> data) async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      // 🟡 Convidado → salva localmente
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, jsonEncode(data));
    } else {
      // 🟢 Usuário logado → salva no Supabase
      await _supabase.from('entries').upsert(data);
    }
  }

  /// Ler dados
  Future<Map<String, dynamic>?> getData(String key) async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      // 🟡 Convidado → lê do local
      final prefs = await SharedPreferences.getInstance();
      final str = prefs.getString(key);
      if (str != null) {
        return jsonDecode(str);
      }
    } else {
      // 🟢 Usuário logado → lê do Supabase
      final response = await _supabase.from('entries').select().maybeSingle();
      return response;
    }
    return null;
  }

  /// Apagar dados (opcional)
  Future<void> deleteData(String key) async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(key);
    } else {
      await _supabase.from('entries').delete().eq('key', key);
    }
  }
}
