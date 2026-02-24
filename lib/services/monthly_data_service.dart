import 'package:myyearmystory/supabase/supabase_config.dart';

final supabase = SupabaseConfig.client;

class MonthlyDataService {
  // Diário pessoal
  static Future<List<Map<String, dynamic>>> getDiaryEntries(int month, int year, String userId) async {
    try {
      final response = await supabase
          .from('diary_entries')
          .select()
          .eq('user_id', userId)
          .eq('month', month)
          .eq('year', year)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  static Future<bool> saveDiaryEntry(String content, int month, int year, String userId) async {
    try {
      await supabase.from('diary_entries').insert({
        'user_id': userId,
        'month': month,
        'year': year,
        'content': content,
        'date': DateTime.now().toIso8601String(),
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  // Fatos aleatórios
  static Future<Map<String, String>> getFunFacts(int month, int year, String userId) async {
    try {
      final response = await supabase
          .from('fun_facts')
          .select()
          .eq('user_id', userId)
          .eq('month', month)
          .eq('year', year)
          .maybeSingle();

      if (response == null) return {};

      return Map<String, String>.from(response['answers'] ?? {});
    } catch (e) {
      return {};
    }
  }

  static Future<bool> saveFunFacts(Map<String, String> answers, int month, int year, String userId) async {
    try {
      await supabase.from('fun_facts').upsert({
        'user_id': userId,
        'month': month,
        'year': year,
        'answers': answers,
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  // Quiz results
  static Future<Map<String, dynamic>?> getQuizResult(int month, int year, String userId) async {
    try {
      final response = await supabase
          .from('quiz_results')
          .select()
          .eq('user_id', userId)
          .eq('month', month)
          .eq('year', year)
          .maybeSingle();

      return response;
    } catch (e) {
      return null;
    }
  }

  static Future<bool> saveQuizResult(Map<String, String> answers, String result, int month, int year, String userId) async {
    try {
      await supabase.from('quiz_results').upsert({
        'user_id': userId,
        'month': month,
        'year': year,
        'answers': answers,
        'result': result,
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  // Listas mensais (migrate to entries.lists)
  static Future<Map<String, List<String>>> getMonthlyLists(int month, int year, String userId) async {
    try {
      final row = await supabase
          .from('entries')
          .select('lists')
          .eq('user_id', userId)
          .eq('month', month)
          .eq('year', year)
          .maybeSingle();

      if (row == null) return {};
      final listsData = row['lists'];
      final result = <String, List<String>>{};
      if (listsData is Map) {
        Map<String, dynamic>.from(listsData).forEach((key, value) {
          if (value is List) {
            result[key] = List<String>.from(value);
          }
        });
      }
      return result;
    } catch (e) {
      return {};
    }
  }

  static Future<bool> saveMonthlyLists(Map<String, List<String>> lists, int month, int year, String userId) async {
    try {
      final existing = await supabase
          .from('entries')
          .select('id')
          .eq('user_id', userId)
          .eq('month', month)
          .eq('year', year)
          .maybeSingle();

      if (existing == null) {
        await supabase.from('entries').insert({
          'user_id': userId,
          'month': month,
          'year': year,
          'lists': lists,
        });
      } else {
        await supabase
            .from('entries')
            .update({'lists': lists})
            .eq('user_id', userId)
            .eq('month', month)
            .eq('year', year);
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  // Interview (migrate to entries.interview { interviewee, answers })
  static Future<Map<String, String>> getInterview(int month, int year, String userId) async {
    try {
      final row = await supabase
          .from('entries')
          .select('interview')
          .eq('user_id', userId)
          .eq('month', month)
          .eq('year', year)
          .maybeSingle();

      if (row == null) return {};
      final interview = row['interview'];
      if (interview is Map) {
        final answers = interview['answers'];
        if (answers is Map) {
          return Map<String, dynamic>.from(answers).map((k, v) => MapEntry(k, v?.toString() ?? ''));
        }
      }
      return {};
    } catch (e) {
      return {};
    }
  }

  static Future<bool> saveInterview(String interviewee, Map<String, String> answers, int month, int year, String userId) async {
    try {
      final payload = {
        'interviewee': interviewee,
        'answers': answers,
      };

      final existing = await supabase
          .from('entries')
          .select('id')
          .eq('user_id', userId)
          .eq('month', month)
          .eq('year', year)
          .maybeSingle();

      if (existing == null) {
        await supabase.from('entries').insert({
          'user_id': userId,
          'month': month,
          'year': year,
          'interview': payload,
        });
      } else {
        await supabase
            .from('entries')
            .update({'interview': payload})
            .eq('user_id', userId)
            .eq('month', month)
            .eq('year', year);
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  // Gratitude (migrate to entries.gratitude_entries)
  static Future<List<String>> getGratitudeList(int month, int year, String userId) async {
    try {
      final row = await supabase
          .from('entries')
          .select('gratitude_entries')
          .eq('user_id', userId)
          .eq('month', month)
          .eq('year', year)
          .maybeSingle();

      if (row == null) return [];
      final items = row['gratitude_entries'];
      if (items is List) {
        return List<String>.from(items);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<bool> saveGratitudeList(List<String> items, int month, int year, String userId) async {
    try {
      final existing = await supabase
          .from('entries')
          .select('id')
          .eq('user_id', userId)
          .eq('month', month)
          .eq('year', year)
          .maybeSingle();

      if (existing == null) {
        await supabase.from('entries').insert({
          'user_id': userId,
          'month': month,
          'year': year,
          'gratitude_entries': items,
        });
      } else {
        await supabase
            .from('entries')
            .update({'gratitude_entries': items})
            .eq('user_id', userId)
            .eq('month', month)
            .eq('year', year);
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  // Monthly reflections (migrate to entries.reflections)
  static Future<Map<String, String>> getReflections(int month, int year, String userId) async {
    try {
      final row = await supabase
          .from('entries')
          .select('reflections')
          .eq('user_id', userId)
          .eq('month', month)
          .eq('year', year)
          .maybeSingle();

      if (row == null) return {};
      final data = row['reflections'];
      if (data is Map) {
        final map = Map<String, dynamic>.from(data);
        return map.map((k, v) => MapEntry(k, v?.toString() ?? ''));
      }
      return {};
    } catch (e) {
      return {};
    }
  }

  static Future<bool> saveReflections(Map<String, String> reflections, int month, int year, String userId) async {
    try {
      final existing = await supabase
          .from('entries')
          .select('id')
          .eq('user_id', userId)
          .eq('month', month)
          .eq('year', year)
          .maybeSingle();

      if (existing == null) {
        await supabase.from('entries').insert({
          'user_id': userId,
          'month': month,
          'year': year,
          'reflections': reflections,
        });
      } else {
        await supabase
            .from('entries')
            .update({'reflections': reflections})
            .eq('user_id', userId)
            .eq('month', month)
            .eq('year', year);
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  // Photo gallery (kept as-is unless schema changes)
  static Future<List<Map<String, String>>> getPhotos(int month, int year, String userId) async {
    try {
      final response = await supabase
          .from('photo_gallery')
          .select()
          .eq('user_id', userId)
          .eq('month', month)
          .eq('year', year)
          .maybeSingle();

      if (response == null) return [];

      final photoUrls = List<String>.from(response['photo_urls'] ?? []);
      final photoDescriptions = List<String>.from(response['photo_descriptions'] ?? []);

      List<Map<String, String>> photos = [];
      for (int i = 0; i < photoUrls.length; i++) {
        photos.add({
          'url': photoUrls[i],
          'description': i < photoDescriptions.length ? photoDescriptions[i] : '',
        });
      }

      return photos;
    } catch (e) {
      return [];
    }
  }

  static Future<bool> savePhotos(List<Map<String, String>> photos, int month, int year, String userId) async {
    try {
      final photoUrls = photos.map((photo) => photo['url']!).toList();
      final photoDescriptions = photos.map((photo) => photo['description']!).toList();

      await supabase.from('photo_gallery').upsert({
        'user_id': userId,
        'month': month,
        'year': year,
        'photo_urls': photoUrls,
        'photo_descriptions': photoDescriptions,
      });
      return true;
    } catch (e) {
      return false;
    }
  }
}
