import 'package:shared_preferences/shared_preferences.dart';

class ReviewStorage {
  static const _statusKey = 'review_status';
  static const _lastPromptKey = 'review_last_prompt';
  static const _firstOpenKey = 'review_first_open';
  static const _lastOpenDayKey = 'review_last_open_day';
  static const _consecutiveDaysKey = 'review_consecutive_days';

  static String _dayKey(DateTime dt) =>
      '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  static Future<String> getReviewStatus() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_statusKey) ?? 'never';
  }

  static Future<void> setReviewStatus(String status) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_statusKey, status);
  }

  static Future<DateTime?> getLastPrompt() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_lastPromptKey);
    return value != null ? DateTime.parse(value) : null;
  }

  static Future<void> saveLastPrompt(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastPromptKey, date.toIso8601String());
  }

  static Future<DateTime> getFirstOpenDate() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_firstOpenKey);

    if (value != null) {
      return DateTime.parse(value);
    }

    final now = DateTime.now();
    await prefs.setString(_firstOpenKey, now.toIso8601String());
    return now;
  }

  static Future<int> getConsecutiveOpenDays() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getInt(_consecutiveDaysKey);
    return value == null || value <= 0 ? 1 : value;
  }

  /// Chame uma vez por "abertura" do app (ex: ao entrar no Dashboard).
  /// Atualiza o contador de dias consecutivos (streak) sem duplicar no mesmo dia.
  static Future<int> recordOpenAndGetConsecutiveDays() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final today = _dayKey(now);

    final lastDay = prefs.getString(_lastOpenDayKey);
    var consecutive = prefs.getInt(_consecutiveDaysKey) ?? 1;
    if (consecutive <= 0) consecutive = 1;

    if (lastDay == null) {
      await prefs.setString(_lastOpenDayKey, today);
      await prefs.setInt(_consecutiveDaysKey, 1);
      return 1;
    }

    if (lastDay == today) {
      return consecutive;
    }

    final last = DateTime.tryParse(lastDay);
    if (last == null) {
      await prefs.setString(_lastOpenDayKey, today);
      await prefs.setInt(_consecutiveDaysKey, 1);
      return 1;
    }

    final lastDateOnly = DateTime(last.year, last.month, last.day);
    final todayDateOnly = DateTime(now.year, now.month, now.day);
    final diffDays = todayDateOnly.difference(lastDateOnly).inDays;

    if (diffDays == 1) {
      consecutive += 1;
    } else {
      consecutive = 1;
    }

    await prefs.setString(_lastOpenDayKey, today);
    await prefs.setInt(_consecutiveDaysKey, consecutive);
    return consecutive;
  }
}
