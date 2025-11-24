import 'package:shared_preferences/shared_preferences.dart';

/// Nome da chave usada no SharedPreferences
const _historyKey = 'notification_history';

/// Separador seguro
const _separator = '||'; // menos chance do usuário digitar isso no título

/// Limite máximo opcional (ex: 200 itens)
const int _maxHistoryItems = 200;

/// ===============================================================
/// 🌸 1) SALVAR ALERTA NO HISTÓRICO
/// ===============================================================
Future<void> saveNotificationHistory({
  required String title,
  required DateTime date,
}) async {
  final prefs = await SharedPreferences.getInstance();

  /// Carrega histórico existente
  List<String> history = prefs.getStringList(_historyKey) ?? [];

  /// Adiciona novo registro usando separador seguro
  history.add("$title$_separator${date.toIso8601String()}");

  /// Limita tamanho (opcional e elegante)
  if (history.length > _maxHistoryItems) {
    history = history.sublist(history.length - _maxHistoryItems);
  }

  await prefs.setStringList(_historyKey, history);
}

/// ===============================================================
/// 🌸 2) LER ALERTAS SALVOS (ORDENADOS)
/// ===============================================================
Future<List<Map<String, dynamic>>> getNotificationHistory() async {
  final prefs = await SharedPreferences.getInstance();
  List<String> history = prefs.getStringList(_historyKey) ?? [];

  /// Converte itens com segurança
  final parsed = history.map((entry) {
    try {
      final parts = entry.split(_separator);
      if (parts.length != 2) throw Exception("Formato inválido");

      return {
        "title": parts[0],
        "date": DateTime.parse(parts[1]),
      };
    } catch (_) {
      return null; // Se quebrar, ignora o item
    }
  }).where((e) => e != null).cast<Map<String, dynamic>>().toList();

  /// Ordena da mais recente para a mais antiga
  parsed.sort((a, b) => b['date'].compareTo(a['date']));

  return parsed;
}

/// ===============================================================
/// 🌸 3) LIMPAR TUDO
/// ===============================================================
Future<void> clearNotificationHistory() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove(_historyKey);
}
