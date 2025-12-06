import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';

class DidYouKnowService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// CARREGA curiosidades do mês + ano
  Future<List<Map<String, dynamic>>> fetchCuriositiesForMonth(int month, int year) async {
    try {
      final result = await _supabase
          .from('monthly_curiosities')
          .select('id, category, content, text_en, created_at, month, year')
          .eq('month', month)
          .eq('year', year)
          .order('created_at', ascending: true);

      if (result.isEmpty) return [];

      return List<Map<String, dynamic>>.from(result);
    } catch (e) {
      print('Erro ao carregar curiosidades do mês: $e');
      return [];
    }
  }

  /// --------------------------
  /// MÉTODO DE SELEÇÃO INTELIGENTE
  /// --------------------------
  List<Map<String, dynamic>> _smartBalancedSelection(List<Map<String, dynamic>> list) {
    if (list.isEmpty) return [];

    // 1. separar general das outras
    final general = list.where((c) => c["category"]?.toString().toLowerCase() == "general").toList();
    final nonGeneral = list.where((c) => c["category"]?.toString().toLowerCase() != "general").toList();

    nonGeneral.shuffle(Random());
    general.shuffle(Random());

    List<Map<String, dynamic>> selected = [];

    // 2. pegar primeiro as categorias não-general (PRIORIDADE)
    for (var item in nonGeneral) {
      if (selected.length == 5) break;

      final category = item["category"] ?? "";
      // evita repetição de categoria
      if (!selected.any((s) => s["category"] == category)) {
        selected.add(item);
      }
    }

    // 3. se ainda não deu 5, permitir *no máximo 1 general*
    if (selected.length < 5 && general.isNotEmpty) {
      selected.add(general.first);
    }

    // 4. se ainda faltar, repetimos categorias não-general se necessário
    int index = 0;
    while (selected.length < 5 && index < nonGeneral.length) {
      selected.add(nonGeneral[index]);
      index++;
    }

    // 5. embaralhar a lista final
    selected.shuffle();

    return selected;
  }

  /// --------------------------
  /// MODO DIÁRIO — versão inteligente
  /// --------------------------
  Future<List<Map<String, dynamic>>> fetchDailyCuriosities(int month, int year) async {
    try {
      final result = await _supabase
          .from('monthly_curiosities')
          .select('id, category, content, text_en, created_at')
          .eq('month', month)
          .eq('year', year)
          .order('created_at', ascending: false);

      if (result.isEmpty) return [];

      final list = List<Map<String, dynamic>>.from(result);

      return _smartBalancedSelection(list);
    } catch (error) {
      print('Erro ao carregar curiosidades diárias: $error');
      return [];
    }
  }
}
