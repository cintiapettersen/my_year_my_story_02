import 'package:supabase_flutter/supabase_flutter.dart';

class DailyQuoteService {
  final supabase = Supabase.instance.client;

  Future<Map<String, dynamic>?> getRandomQuote(String lang) async {
    try {
      // busca apenas as colunas necessárias
      final response = await supabase
          .from('daily_quotes')
          .select('id, text, text_en')
          .order('id')   // ok
          .limit(200);   // opcional

      if (response.isEmpty) {
        print("⚠️ Nenhuma frase encontrada.");
        return null;
      }

      // embaralha
      response.shuffle();
      final quote = response.first;

      print("📝 Quote sorteada: $quote");

      // idioma EN
      if (lang == "en") {
        final textEn = quote["text_en"]?.toString().trim();
        if (textEn != null && textEn.isNotEmpty) {
          print("🌎 Usando frase EN: $textEn");
          return {"text": textEn};
        }
      }

      // idioma PT
      final textPt = quote["text"]?.toString().trim();
      if (textPt != null && textPt.isNotEmpty) {
        print("🇧🇷 Usando frase PT: $textPt");
        return {"text": textPt};
      }

      print("⚠️ Quote vazia! Retornando fallback vazio.");
      return {"text": ""};

    } catch (e) {
      print("❌ ERRO NO DailyQuoteService: $e");
      return null;
    }
  }
}
