import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SecureStorageService {
  static const String _sessionKey = 'supabase_session_payload';

  static const FlutterSecureStorage _storage = FlutterSecureStorage(
  aOptions: AndroidOptions(
    encryptedSharedPreferences: true,
  ),
  iOptions: IOSOptions(
    accessibility: KeychainAccessibility.first_unlock,
  ),
);


  static Future<void> saveSession(Session? session) async {
    if (session == null) {
      await clearSession();
      return;
    }

    final jsonString = jsonEncode(session.toJson());
    await _storage.write(key: _sessionKey, value: jsonString);
  }

  static Future<String?> readSessionJson() {
    return _storage.read(key: _sessionKey);
  }

  static Future<Map<String, dynamic>?> readSessionMap() async {
    final jsonString = await readSessionJson();
    if (jsonString == null) return null;
    return jsonDecode(jsonString) as Map<String, dynamic>;
  }

  static Future<void> clearSession() {
    return _storage.delete(key: _sessionKey);
  }
}
