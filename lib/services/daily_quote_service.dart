import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:myyearmystory/services/app_session.dart';

class DailyQuoteService {
  final supabase = Supabase.instance.client;

  Future<Map<String, dynamic>?> getRandomQuote(String lang) async {
    // 🛑 BLOQUEIO CRÍTICO — evita JWT expirado
    if (!AppSession.isAuthenticated) {
      print('⏸️ DailyQuoteService ignorado — usuário não autenticado');
      return null; // ou {"text": "..."} se quiser fallback
    }

    try {
      final response = await supabase
          .from('daily_quotes')
          .select('id, text, text_en')
          .order('id')
          .limit(200);

      if (response.isEmpty) {
        print("⚠️ Nenhuma frase encontrada.");
        return null;
      }

      response.shuffle();
      final quote = response.first;

      if (lang == "en") {
        final textEn = quote["text_en"]?.toString().trim();
        if (textEn != null && textEn.isNotEmpty) {
          return {"text": textEn};
        }
      }

      final textPt = quote["text"]?.toString().trim();
      if (textPt != null && textPt.isNotEmpty) {
        return {"text": textPt};
      }

      return {"text": ""};
    } catch (e) {
      print("❌ ERRO NO DailyQuoteService: $e");
      return null;
    }
  }
}
