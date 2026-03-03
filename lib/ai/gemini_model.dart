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
  print("==== GEMINI DIARY CALL ====");
  print("Prompt enviado:");
  print(prompt);

  try {
    final response = await reflectionGeminiModel.generateContent(
      [Content.text(prompt)],
    );

    print("Resposta bruta:");
    print(response.text);

    return response.text?.trim() ?? '';
  } catch (e, stack) {
    print("ERRO GEMINI:");
    print(e);
    print(stack);
    rethrow;
  }

  
}