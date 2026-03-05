import 'package:google_generative_ai/google_generative_ai.dart';
import 'observer_system_instruction.dart';

final geminiModel = GenerativeModel(
  model: 'models/gemini-1.5-flash-latest',
  apiKey: const String.fromEnvironment('GEMINI_API_KEY'),
  systemInstruction: Content.text(observerSystemInstruction),
  generationConfig: GenerationConfig(
    temperature: 0.7,
  ),
);

final reflectionGeminiModel = GenerativeModel(
  model: 'models/gemini-1.5-flash-latest',
  apiKey: const String.fromEnvironment('GEMINI_API_KEY'),
  generationConfig: GenerationConfig(
    temperature: 0.6,
    maxOutputTokens: 250,
  ),
);



Future<String> generateDiaryResponse(String prompt) async {
  try {
    final response = await reflectionGeminiModel.generateContent(
      [Content.text(prompt)],
    );

    return response.text?.trim() ?? '';
  } catch (e) {
    rethrow;
  }

  
}
