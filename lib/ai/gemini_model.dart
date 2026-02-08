import 'package:google_generative_ai/google_generative_ai.dart';
import 'observer_system_instruction.dart';

final geminiModel = GenerativeModel(
  model: 'gemini-3-pro-preview',
  apiKey: const String.fromEnvironment('GEMINI_API_KEY'),
  systemInstruction: Content.text(observerSystemInstruction),
  generationConfig: GenerationConfig(
    temperature: 0.7,
  ),
);
