import 'package:supabase_flutter/supabase_flutter.dart';

class DidYouKnowService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> fetchCuriosities(int month, int year) async {
    try {
      final response = await _supabase
          .from('monthly_curiosities')
          .select()
          .eq('month', month)
          .eq('year', year)
          .order('category', ascending: true);

      if (response.isEmpty) return [];

      return List<Map<String, dynamic>>.from(response);
    } catch (error) {
      print('Erro ao buscar curiosidades: $error');
      return [];
    }
  }
}
