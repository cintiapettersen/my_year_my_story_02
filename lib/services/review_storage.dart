import 'package:shared_preferences/shared_preferences.dart';

class ReviewStorage {
  static const _statusKey = 'review_status';
  static const _lastPromptKey = 'review_last_prompt';
  static const _firstOpenKey = 'review_first_open';

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
}
