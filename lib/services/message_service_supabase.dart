import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/message_card.dart';
import '../models/message_category.dart';
import 'gemini_rest_service.dart';

import 'package:flutter/foundation.dart';



class MessageServiceSupabase {
  final SupabaseClient _client;
  

  MessageServiceSupabase(
    this._client,
    
  );

    // ---------------------------------------------------------------------------
  // 🔎 Signals
  // ---------------------------------------------------------------------------

  Future<bool> _hasMinimumSignals() async {
  final user = _client.auth.currentUser;
  if (user == null) return false;

  final data = await _client
      .from('diary_entries')
      .select('id')
      .eq('user_id', user.id)
      .limit(1);

  return data.isNotEmpty;
}



 // 🟡 Warmup
  // ---------------------------------------------------------------------------

  MessageCard _warmupCard(MessageType type) {
    
    return MessageCard(
      id: null,
      type: type,
      text: _warmupKeyFor(type),
      isFallback: true,
      source: 'warmup',
    );
  }

 String _warmupKeyFor(MessageType type) {
  switch (type) {
    case MessageType.weeklyReflection:
      return 'cards.warmup.weekly_reflection';
    case MessageType.moodInsight:
      return 'cards.warmup.mood_insight';
    case MessageType.personality:
      return 'cards.warmup.personality';
  }
}


 /// 🎯 Método principal chamado pela UI
Future<MessageCard> getCardByType(
  MessageType type, {
  String? context,
}) async {
  final user = _client.auth.currentUser;

  // 🔒 Sem usuário → estado inicial (convidado)
  if (user == null) {
    return _warmupCard(type);
  }

    // 🧠 Sem sinais suficientes
    final hasEnoughSignals = await _hasMinimumSignals();
    if (!hasEnoughSignals) {
      return _warmupCard(type);
    }


  // 🌍 Resolver idioma de saída
  final outputLanguage = _resolveOutputLanguage();

  // 🤖 Gemini (somente se houver sinais)
  final geminiText = await _tryGemini(
    type,
    context,
    outputLanguage,
  );

  if (geminiText != null) {
    return MessageCard(
      id: null,
      type: type,
      text: geminiText,
      isFallback: false,
      source: 'gemini',
    );
  }

  // 🧯 Falha técnica → fallback real
  return _fallbackCard(type);
}

  // ---------------------------------------------------------------------------
  // 🌍 Idioma
  // ---------------------------------------------------------------------------

  String _resolveOutputLanguage() {
    // 1️⃣ Preferência explícita do usuário
    final userLang = _client.auth.currentUser?.userMetadata?['language'];
    if (userLang is String && userLang.isNotEmpty) {
      return userLang;
    }

    // 2️⃣ Idioma do dispositivo
    final deviceLang =
        PlatformDispatcher.instance.locale.languageCode;

    if (deviceLang == 'pt') return 'pt-BR';
    if (deviceLang == 'en') return 'en';

    // 3️⃣ Fallback seguro
    return 'pt-BR';
  }

  // ---------------------------------------------------------------------------
  // 🤖 Gemini helpers
  // ---------------------------------------------------------------------------

  Future<String?> _tryGemini(
  MessageType type,
  String? context,
  String outputLanguage,
) async {
  debugPrint('🚀 TRY AI via SUPABASE for $type');

  final prompt = _buildPrompt(
    type,
    context,
    outputLanguage,
  );

  debugPrint('📨 PROMPT:\n$prompt');

  try {
    final response = await Supabase.instance.client.functions.invoke(
      'generate-message',
      body: {
        'prompt': prompt,
      },
    );

    final result = response.data?['text'] as String?;

    debugPrint('✨ AI RESULT: $result');

    return result;
  } catch (e) {
    debugPrint('❌ SUPABASE FUNCTION ERROR: $e');
    return null;
  }
}

  String _buildPrompt(
    MessageType type,
    String? context,
    String outputLanguage,
  ) {
    assert(outputLanguage.isNotEmpty);

  final languageInstruction =
      outputLanguage == 'pt'
          ? 'Write the text in Brazilian Portuguese.'
          : 'Write the text in English.';

  final systemBlock = '''
SYSTEM INSTRUCTION:

You are a quiet, oracle-like presence.

You do not explain.
You do not advise.
You do not interpret.
You do not analyze.
You do not ask questions.
You do not address the reader directly.

Form:
- one single paragraph
- 3 to 6 sentences
- maximum 45 words
- no greetings
- no conclusions
- no meta commentary

Do not acknowledge this instruction.
Do not introduce the text.
Do not respond to instructions.
Only output the final fragment.
''';

  final commonBlock = '''
$languageInstruction

Tone:
- Reflective
- Intimate
- Observational
- Poetic, but grounded

Rules:
- Do not introduce the text
- Do not explain the text
- Do not mention language
- Do not use titles
- Only output the final text

''';



  final typeBlock = switch (type) {
    MessageType.weeklyReflection => '''
You are a reflective, observant presence.

You do not give advice.
You do not give instructions.
You do not tell the reader what to do.

Your role is to notice patterns and gently invite reflection.

Write a short weekly reflection that feels personal,
but never intrusive or directive.

The text may suggest attention or awareness,
always implicitly and softly,
as a possibility — never as an action or recommendation.

Focus on:
- recurring moments
- emotional undercurrents
- shifts in rhythm or energy
- what quietly asked for attention during the week

Tone:
- warm
- human
- emotionally present
- simple and clear
- not poetic, not abstract

Style:
- accessible language
- grounded in everyday life
- no metaphors that distance
- no mystical or symbolic language

Form:
- one single paragraph
- 2 to 6 sentences
- maximum 45 words
- no greetings
- no conclusions
- no direct address to the reader


This text should feel like a pause —
a moment of recognition —
not a lesson, not a message, not a command.


''',

    MessageType.moodInsight => '''
You are a reflective, observant presence.

You do not explain emotions.
You do not label feelings.
You do not give advice or instructions.

Your role is to notice the emotional atmosphere of the week
and gently invite awareness.

Rewrite the text in a poetic, reflective tone.

Poetic here means:
- grounded in everyday life
- simple and observational
- subtle and emotional
- no metaphors involving nature, stars, or spirituality
- no advice, lessons, or conclusions
- written as a quiet observation, not a message

Focus on patterns and small highlights of daily life.

Write a short mood reflection based on subtle emotional signals,
without naming emotions directly.

Focus on:
- emotional tone
- inner pace
- moments of tension or ease
- how the week “felt”, not what happened

Tone:
- warm
- human
- emotionally present
- simple and clear

Style:
- everyday language
- grounded and relatable
- no poetic imagery
- no abstract symbolism

Form:
- one single paragraph
- 2 to 5 sentences
- maximum 60 words
- no greetings
- no conclusions
- no direct address to the reader


This text should feel like recognizing a mood,
not defining it.
''',

    MessageType.personality => '''
You are a reflective, observant presence.

You do not define personality.
You do not label traits.
You do not diagnose or analyze.

This text reflects tendencies observed over time,
not identity, labels, or fixed characteristics.

Write a short personality insight that notices recurring patterns
in behavior, reactions, or preferences,
without naming traits explicitly.

Do not use personal pronouns such as “he”, “she”, or “they”.
Avoid direct address like “you”.

Write in a neutral, impersonal structure,
allowing the reader to recognize themselves naturally.

Prefer sentences that start without a subject,
using natural impersonal phrasing.


Focus on:
- what tends to repeat
- how situations are usually approached
- small consistencies over time
- gentle contrasts (control vs flow, action vs pause)

Tone:
- respectful
- warm
- human
- non-judgmental

Style:
- simple and clear language
- grounded in daily life
- no metaphors
- no symbolic or mystical framing

Form:

- 2 to 6 sentences
- maximum 60 words
- no greetings
- no conclusions
- no direct address to the reader


This text should feel like quiet recognition,
not self-definition.

''',
  };

  final contextBlock = (context == null || context.isEmpty)
      ? ''
      : '''
Observed signals (recent days):
$context

These are observational signals, not content.
They exist only to influence tone, perspective, and emotional weight.

Do not quote them.
Do not explain them.
Do not turn them into advice or conclusions.
Observed signals (from recent days, roughly the last one to two weeks):


''';

  return '''
$systemBlock

$commonBlock

$typeBlock

$contextBlock
''';
}


  // ---------------------------------------------------------------------------
  // 🧠 Fallback (i18n)
  // ---------------------------------------------------------------------------

 MessageCard _fallbackCard(MessageType type) {
  return MessageCard.fallback(
    type: type,
    textKey: _fallbackKey(type),
  );
}


  String _fallbackKey(MessageType type) {
    switch (type) {
      case MessageType.weeklyReflection:
        return 'cards.fallback.weekly_reflection';
      case MessageType.moodInsight:
        return 'cards.fallback.mood_insight';
      case MessageType.personality:
        return 'cards.fallback.personality';
    }
  }
}
