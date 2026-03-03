import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';

class DidYouKnowService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // --------------------------------------------------
  // UTIL: normaliza categorias (segurança total)
  // --------------------------------------------------
  String _normalizeCategory(dynamic value) {
    return value
            ?.toString()
            .toLowerCase()
            .trim()
            .replaceAll(' ', '_')
            .replaceAll('ç', 'c')
            .replaceAll('ã', 'a')
            .replaceAll('á', 'a')
            .replaceAll('é', 'e')
            .replaceAll('í', 'i')
            .replaceAll('ó', 'o')
            .replaceAll('ú', 'u') ??
        'general';
  }

  // --------------------------------------------------
  // CARREGA TODAS as curiosidades (sem filtro)
  // --------------------------------------------------
  Future<List<Map<String, dynamic>>> fetchAllCuriosities() async {
    try {
      final result = await _supabase
          .from('did_you_know')
          .select('id, category, content, text_en, created_at')
          .order('created_at', ascending: true);

      if (result.isEmpty) return [];

      return List<Map<String, dynamic>>.from(result);
    } catch (e) {
     
      return [];
    }
  }

  // --------------------------------------------------
  // SELEÇÃO INTELIGENTE (balanceada por categoria)
  // --------------------------------------------------
  List<Map<String, dynamic>> _smartBalancedSelection(
    List<Map<String, dynamic>> list,
  ) {
    if (list.isEmpty) return [];

    final normalizedList = list.map((item) {
      return {
        ...item,
        'normalized_category': _normalizeCategory(item['category']),
      };
    }).toList();

    final general = normalizedList
        .where((c) => c['normalized_category'] == 'general')
        .toList();

    final nonGeneral = normalizedList
        .where((c) => c['normalized_category'] != 'general')
        .toList();

    nonGeneral.shuffle(Random());
    general.shuffle(Random());

    List<Map<String, dynamic>> selected = [];

    // 1️⃣ prioriza categorias diferentes
    for (final item in nonGeneral) {
      if (selected.length == 5) break;

      final category = item['normalized_category'];
      final alreadyUsed =
          selected.any((s) => s['normalized_category'] == category);

      if (!alreadyUsed) {
        selected.add(item);
      }
    }

    // 2️⃣ permite no máximo 1 general
    if (selected.length < 5 && general.isNotEmpty) {
      selected.add(general.first);
    }

    // 3️⃣ completa se ainda faltar
    int index = 0;
    while (selected.length < 5 && index < nonGeneral.length) {
      selected.add(nonGeneral[index]);
      index++;
    }

    selected.shuffle(Random());

    // remove campo interno
    return selected.map((item) {
      final clean = Map<String, dynamic>.from(item);
      clean.remove('normalized_category');
      return clean;
    }).toList();
  }

  // --------------------------------------------------
  // MODO DIÁRIO (USADO PELO WIDGET)
  // --------------------------------------------------
  Future<List<Map<String, dynamic>>> fetchDailyCuriosities() async {
  try {
    final result = await _supabase
        .from('did_you_know')
        .select('id, category, content, text_en, created_at');

    if (result.isEmpty) return [];

    final list = List<Map<String, dynamic>>.from(result);
    return _smartBalancedSelection(list);
  } catch (e) {
   
    rethrow;
  }
}

}
