import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter/foundation.dart';




class MessageServiceGemini {
  final GenerativeModel _model;

  MessageServiceGemini(String apiKey)
      : _model = GenerativeModel(
          model: 'models/gemini-1.0-pro',
          apiKey: apiKey,
          generationConfig: GenerationConfig(
            temperature: 0.7,
            maxOutputTokens: 180,
          ),
        );

  /// Gera texto a partir de um prompt.
  /// Retorna null se falhar por qualquer motivo.
  Future<String?> generate(String prompt) async {
  try {
    final response = await _model.generateContent([
      Content.text(prompt),
    ]);

   

    final text = response.text?.trim();

    if (text == null || text.isEmpty) {
      
      return null;
    }

    return text;
  } catch (e, s) {
    debugPrint('❌ GEMINI ERROR: $e');
    debugPrint('📌 STACKTRACE:\n$s');
    return null;
  }
}




}