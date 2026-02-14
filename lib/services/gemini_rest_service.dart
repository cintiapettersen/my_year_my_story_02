import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';


class SupabaseMessageService {
  final String supabaseUrl;
  final String anonKey;

  SupabaseMessageService({
    required this.supabaseUrl,
    required this.anonKey,
  });

  Future<String?> generate(String prompt) async {
    final url = Uri.parse(
      '$supabaseUrl/functions/v1/generate-message',
    );

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $anonKey',
      },
      body: jsonEncode({
        'prompt': prompt,
      }),
    );

    if (response.statusCode != 200) {
      if (kDebugMode) {
      debugPrint('SupabaseMessageService error (${response.statusCode})');
}
      return null;
    }

    final data = jsonDecode(response.body);
    return data['text'];
  }
}
