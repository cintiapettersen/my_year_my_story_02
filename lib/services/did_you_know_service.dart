import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';

class DidYouKnowService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// 🔥 Busca curiosidades diárias (5 por dia)
  /// - Se premium → embaralha e permite refresh
  /// - Se gratuito → apenas pega as 5 do dia, sem refresh
  Future<List<Map<String, dynamic>>> fetchDailyCuriosities() async {
    try {
      final result = await _supabase
          .from('monthly_curiosities')
          .select(
              'id, category, category_en, content, text_en, created_at')
          .order('created_at', ascending: false);

      if (result.isEmpty) return [];

      // Embaralha para sempre gerar combinações novas
      final shuffled = List<Map<String, dynamic>>.from(result)..shuffle(Random());

      // Limita a 5 curiosidades por dia
      return shuffled.take(5).toList();
    } catch (error) {
      print('Erro ao carregar curiosidades diárias: $error');
      return [];
    }
  }
}
