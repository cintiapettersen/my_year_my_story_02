import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DailyQuoteService {
  final supabase = Supabase.instance.client;

  Future<Map<String, dynamic>?> getRandomQuote(String lang) async {
    final user = supabase.auth.currentUser;
    if (user == null) return null;

    final prefs = await SharedPreferences.getInstance();
    final todayKey = _dateKey(DateTime.now());
    final cacheDateKey = 'daily_quote_${lang}_date';
    final cacheTextKey = 'daily_quote_${lang}_text';

    final cachedDate = prefs.getString(cacheDateKey);
    final cachedText = prefs.getString(cacheTextKey)?.trim();
    if (cachedDate == todayKey && cachedText != null && cachedText.isNotEmpty) {
      return {'text': cachedText};
    }

    try {
      final response = await supabase
          .from('daily_quotes')
          .select('id, text, text_en')
          .order('id')
          .limit(200);

      if (response.isEmpty) {
        return cachedText != null && cachedText.isNotEmpty ? {'text': cachedText} : null;
      }

      response.shuffle();
      final quote = response.first;

      String? resolved;
      if (lang == "en") {
        final textEn = quote["text_en"]?.toString().trim();
        if (textEn != null && textEn.isNotEmpty) {
          resolved = textEn;
        }
      }

      resolved ??= quote["text"]?.toString().trim();

      resolved = resolved?.trim();
      if (resolved != null && resolved.isNotEmpty) {
        await prefs.setString(cacheDateKey, todayKey);
        await prefs.setString(cacheTextKey, resolved);
        return {'text': resolved};
      }

      return cachedText != null && cachedText.isNotEmpty ? {'text': cachedText} : {'text': ''};
    } catch (e) {
      return cachedText != null && cachedText.isNotEmpty ? {'text': cachedText} : null;
    }
  }

  String _dateKey(DateTime dt) =>
      '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
}
