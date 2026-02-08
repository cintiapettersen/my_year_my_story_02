import 'dart:convert';
import 'package:http/http.dart' as http;

class GeminiRestService {
  final String apiKey;

  GeminiRestService(this.apiKey);

  Future<String?> generate(String prompt) async {
    final url = Uri.parse(
  'https://generativelanguage.googleapis.com/v1/models/gemini-2.0-flash-lite:generateContent?key=$apiKey'

);


    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "contents": [
          {
            "parts": [
              {"text": prompt}
            ]
          }
        ]
      }),
    );

    if (response.statusCode != 200) {
      print('❌ Gemini HTTP error: ${response.body}');
      return null;
    }

    final data = jsonDecode(response.body);
    return data['candidates']?[0]?['content']?['parts']?[0]?['text'];
  }
}
