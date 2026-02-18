import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/message_card.dart';
import '../models/message_category.dart';

import 'package:easy_localization/easy_localization.dart';

import 'package:flutter/widgets.dart';




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
      isFallback: false,
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
  String? semanticContext,
  required String outputLanguage,
}) async {
  final user = _client.auth.currentUser;

  if (user == null) {
    return _warmupCard(type);
  }

  final hasEnoughSignals = await _hasMinimumSignals();
  if (!hasEnoughSignals) {
    return _warmupCard(type);
  }



  final geminiText = await _tryGemini(
    type,
    semanticContext,
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

  return _fallbackCard(type);
}



  // ---------------------------------------------------------------------------
  // 🤖 Gemini helpers
  // ---------------------------------------------------------------------------

  Future<String?> _tryGemini(
  MessageType type,
  String? context,
  String outputLanguage,
) async {
 

  final prompt = _buildPrompt(
    type,
    context,
    outputLanguage,
  );

 

  try {
    final response = await Supabase.instance.client.functions.invoke(
      'generate-message',
      body: {
        'prompt': prompt,
      },
    );

    final result = response.data?['text'] as String?;

    

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
  outputLanguage == 'pt' || outputLanguage == 'pt-BR'
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
- 3 to 5 sentences
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


Rules:
- Do not introduce the text
- Do not explain the text
- Do not mention language
- Do not use titles
- Only output the final text

-Avoid generic inspirational phrases. Reference observable behaviors, recent time frames, and subtle patterns. 
-Keep it intimate but concrete.

''';



  final typeBlock = switch (type) {
    MessageType.weeklyReflection => '''
You are a reflective, observant presence.

You do not give advice.
You do not give instructions.
You do not tell the reader what to do.

Your role is to notice patterns and gently invite reflection.

You are a personal cycle analyst.

Write a reflective analysis about the person's most recent 7 or 15-day period.

Context:
- The text should analyze the overall atmosphere and energetic tone of this recent phase.
- It may reference themes such as transformation, increased awareness, personal authority, communication, inner shifts, or conscious growth.
- Focus on what marked this period and how it shaped the person’s development.

Objective:
- Describe the defining characteristics of the period.
- Highlight growth, awareness, or turning points.
- Maintain an evolutionary and constructive perspective.

Tone:
- warm
- Observant
- Mature
- Analytical yet sensitive
- Elegant and fluid language

Format:
- One single paragraph
- 2 to 5 sentences
- maximum 45 words
- Do not end with a question

Avoid:
- Describing permanent personality traits
- Focusing on isolated emotions
- Using mystical exaggeration


Focus on:
- recurring moments
- emotional undercurrents
- shifts in rhythm or energy
- what quietly asked for attention during the week



This text should feel like a pause —
a moment of recognition —
not a lesson, not a message, not a command.


''',

    MessageType.moodInsight => '''
You are an emotional insight specialist.

Write a text analyzing the predominant feelings experienced during the most recent period.

Context:
- The emotions are temporary and not fixed traits.
- The text should explore emotional states such as resentment, reconciliation, inner review, difficult decisions, closure of cycles, or deep emotional processing.

Objective:
- Translate what was emotionally experienced.
- Validate the emotional intensity.
- Show emotional maturation or inner processing.

Tone:
- Deep
- Introspective
- Sensitive
- Non-judgmental

Avoid:
- Describing permanent personality characteristics
- Making predictions
- Sounding like therapeutic advice

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


You are a behavioral pattern analyst.

You do not define personality.
You do not label traits.
You do not diagnose or analyze. 


Write a text describing the person's recurring patterns of thinking and behavior.

Context:
- Focus on structural and long-term traits.
- Describe how the person naturally acts, decides, positions themselves socially, and navigates life.
- You may mention imagination, courage, efficiency, depth, social presence, emotional attunement, or boldness.

Objective:
- Reveal recurring behavioral patterns.
- Show how these patterns influence decisions and life direction.
- Provide awareness without judgment.

Tone:
- Clear
- Confident
- Reflective
- Elegant

Avoid:
- Referring to the recent period
- Describing temporary emotions
- Making predictions 


Form:
- 2 to 5 sentences
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
