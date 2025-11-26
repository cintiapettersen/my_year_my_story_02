import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DailyQuoteService {
  final supabase = Supabase.instance.client;

  // Carrega todas as frases
  Future<List<Map<String, dynamic>>> _fetchAllQuotes() async {
    final response = await supabase.from('daily_quotes').select();
    return response.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  // Salva histórico das últimas 5 frases
  Future<void> _saveHistory(int id) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> history = prefs.getStringList('quote_history') ?? [];

    history.insert(0, id.toString());

    if (history.length > 5) {
      history = history.sublist(0, 5);
    }

    await prefs.setStringList('quote_history', history);
  }

  // Retorna frase aleatória evitando repetição
  Future<Map<String, dynamic>> getRandomQuote() async {
    final prefs = await SharedPreferences.getInstance();
    final history = prefs.getStringList('quote_history') ?? [];

    final quotes = await _fetchAllQuotes();

    // Frases não usadas recentemente
    final filtered = quotes.where(
      (q) => !history.contains(q['id'].toString()),
    ).toList();

    final available = filtered.isNotEmpty ? filtered : quotes;

    final random = Random();
    final chosen = available[random.nextInt(available.length)];

    await _saveHistory(chosen['id']);

    return chosen;
  }
}
