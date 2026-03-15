import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:myyearmystory/supabase/supabase_config.dart';

class LiteraryQuote {
  final String quote;
  final String author;
  final String? work;
  final String source; // gemini | fallback | cache

  const LiteraryQuote({
    required this.quote,
    required this.author,
    this.work,
    required this.source,
  });

  Map<String, dynamic> toJson() => {
        'quote': quote,
        'author': author,
        'work': work ?? '',
        'source': source,
      };

  static LiteraryQuote? fromJson(Map<String, dynamic> json) {
    final quote = (json['quote'] ?? '').toString().trim();
    final author = (json['author'] ?? '').toString().trim();
    final work = (json['work'] ?? '').toString().trim();
    final source = (json['source'] ?? '').toString().trim();
    if (quote.isEmpty || author.isEmpty) return null;
    return LiteraryQuote(
      quote: quote,
      author: author,
      work: work.isEmpty ? null : work,
      source: source.isEmpty ? 'cache' : source,
    );
  }
}

class LiteraryQuotesService {
  static const Duration _cacheTtl = Duration(days: 2);

  static bool get devPass =>
      const bool.fromEnvironment('DEV_PASS', defaultValue: false);

  static const List<String> _recurringAuthors = [
    'Lívia Solaris',
    'Mateo Vale',
    'Clara Nadir',
    'Elias Verne',
  ];

  static const List<String> _styleInfluences = [
    'Emily Dickinson',
    'William Shakespeare',
    'Jane Austen',
    'Louisa May Alcott',
    'Ralph Waldo Emerson',
    'Henry David Thoreau',
    'Oscar Wilde',
    'Mark Twain',
    'Leo Tolstoy',
    'Fyodor Dostoevsky',
    'Victor Hugo',
    'Charles Dickens',
    'Edgar Allan Poe',
    'Friedrich Nietzsche',
    'Marcus Aurelius',
    'Machado de Assis',
    'Fernando Pessoa',
    'Luís de Camões',
    'Florbela Espanca',
    'Virginia Woolf',
    'Eça de Queirós',
    'Almeida Garrett',
    'Olavo Bilac',
    'Castro Alves',
  ];

  static const int _maxQuoteChars = 280;
  static const int _maxPublicDomainQuoteChars = 160;

  static const List<LiteraryQuote> _publicDomainEn = [
    LiteraryQuote(
      quote: "To thine own self be true.",
      author: "William Shakespeare",
      work: "Hamlet",
      source: 'public_domain',
    ),
    LiteraryQuote(
      quote: "Brevity is the soul of wit.",
      author: "William Shakespeare",
      work: "Hamlet",
      source: 'public_domain',
    ),
    LiteraryQuote(
      quote: "The course of true love never did run smooth.",
      author: "William Shakespeare",
      work: "A Midsummer Night’s Dream",
      source: 'public_domain',
    ),
    LiteraryQuote(
      quote: "We are such stuff as dreams are made on.",
      author: "William Shakespeare",
      work: "The Tempest",
      source: 'public_domain',
    ),
    LiteraryQuote(
      quote: "All the world's a stage.",
      author: "William Shakespeare",
      work: "As You Like It",
      source: 'public_domain',
    ),
    LiteraryQuote(
      quote: "I am not afraid of storms, for I am learning how to sail my ship.",
      author: "Louisa May Alcott",
      work: "Little Women",
      source: 'public_domain',
    ),
  ];

  static const List<LiteraryQuote> _publicDomainPt = [
    LiteraryQuote(
      quote: "Amor é fogo que arde sem se ver.",
      author: "Luís de Camões",
      work: "Soneto",
      source: 'public_domain',
    ),
    LiteraryQuote(
      quote: "Mudam-se os tempos, mudam-se as vontades.",
      author: "Luís de Camões",
      work: "Soneto",
      source: 'public_domain',
    ),
    LiteraryQuote(
      quote: "Tudo vale a pena se a alma não é pequena.",
      author: "Fernando Pessoa",
      work: "Mensagem",
      source: 'public_domain',
    ),
    LiteraryQuote(
      quote: "Ao vencedor, as batatas.",
      author: "Machado de Assis",
      work: "Quincas Borba",
      source: 'public_domain',
    ),
  ];

  static String _dateKey(DateTime dt) =>
      '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  static String _prefsBaseKey({
    required String userKey,
    required DateTime day,
    required String lang,
    required int variant,
  }) {
    return 'literary_quote_${userKey}_${_dateKey(day)}_${lang.toLowerCase()}_v$variant';
  }

  static List<LiteraryQuote> _fallback(String lang) {
    final isEN = lang.toLowerCase().startsWith('en');
    if (isEN) {
      return const [
        LiteraryQuote(
          quote:
              "Some mornings feel like unfinished paragraphs — and that's still a kind of progress.",
          author: "Lívia Solaris",
          work: null,
          source: 'fallback',
        ),
        LiteraryQuote(
          quote:
              "When you can't move the whole world, move one small thought toward the light.",
          author: "Elias Verne",
          work: null,
          source: 'fallback',
        ),
        LiteraryQuote(
          quote:
              "A quiet mind doesn't erase the storm — it simply gives you a place to stand.",
          author: "Clara Nadir",
          work: null,
          source: 'fallback',
        ),
        LiteraryQuote(
          quote:
              "The bravest thing today might be staying soft while you learn to be strong.",
          author: "Mateo Vale",
          work: null,
          source: 'fallback',
        ),
        LiteraryQuote(
          quote:
              "You don't have to be certain to begin; you just have to be honest for one sentence.",
          author: "Lívia Solaris",
          work: null,
          source: 'fallback',
        ),
        LiteraryQuote(
          quote:
              "Let your next step be small enough to forgive, and real enough to matter.",
          author: "Elias Verne",
          work: null,
          source: 'fallback',
        ),
      ];
    }
    return const [
      LiteraryQuote(
        quote:
            "Tem dia que a coragem não grita: ela só fica, bem quieta, e continua.",
        author: "Clara Nadir",
        work: null,
        source: 'fallback',
      ),
      LiteraryQuote(
        quote:
            "Você não precisa entender tudo agora — só precisa se tratar com cuidado enquanto aprende.",
        author: "Mateo Vale",
        work: null,
        source: 'fallback',
      ),
      LiteraryQuote(
        quote:
            "Às vezes, crescer é fazer as pazes com o que você sente sem se desculpar por existir.",
        author: "Lívia Solaris",
        work: null,
        source: 'fallback',
      ),
      LiteraryQuote(
        quote:
            "O silêncio também pode ser resposta — quando ele vem cheio de respeito por você.",
        author: "Elias Verne",
        work: null,
        source: 'fallback',
      ),
      LiteraryQuote(
        quote:
            "Se hoje você só conseguir uma frase, que seja uma frase verdadeira.",
        author: "Clara Nadir",
        work: null,
        source: 'fallback',
      ),
      LiteraryQuote(
        quote:
            "O futuro não cobra perfeição; ele pede presença, um pouco de cada vez.",
        author: "Mateo Vale",
        work: null,
        source: 'fallback',
      ),
    ];
  }

  static LiteraryQuote fallbackQuote({
    required String lang,
    int variant = 0,
    DateTime? day,
  }) {
    final d = day ?? DateTime.now();
    final options = _fallback(lang);
    return options[(d.day + variant) % options.length];
  }

  static bool _shouldUsePublicDomain(DateTime day, int variant) {
    final seed = (day.year * 10000) + (day.month * 100) + day.day + (variant * 7);
    return (seed % 3) == 0; // ~1/3 dos dias/variantes
  }

  static List<LiteraryQuote> _publicDomainOptions(String lang) {
    final isEN = lang.toLowerCase().startsWith('en');
    return isEN ? _publicDomainEn : _publicDomainPt;
  }

  static LiteraryQuote publicDomainQuote({
    required String lang,
    int variant = 0,
    DateTime? day,
  }) {
    final d = day ?? DateTime.now();
    final options = _publicDomainOptions(lang);
    final quote = options[(d.day + (variant * 3)) % options.length];
    var text = quote.quote.trim();
    if (text.length > _maxPublicDomainQuoteChars) {
      text = text.substring(0, _maxPublicDomainQuoteChars).trimRight();
      text = text.replaceAll(RegExp(r'[.,;:!?]\s*$'), '');
      text = '$text…';
    }
    return LiteraryQuote(
      quote: text,
      author: quote.author,
      work: quote.work,
      source: 'public_domain',
    );
  }

  static String _authorsLine() {
    return _recurringAuthors.map((a) => '- $a').join('\n');
  }

  static String _influencesLine() {
    return _styleInfluences.map((a) => '- $a').join('\n');
  }

  static String _sanitizeExcerpt(String raw) {
    var text = raw.trim();
    if (text.isEmpty) return text;

    // Avoid meta-references like: "Como diria X em 'Obra'..."
    final match =
        RegExp(r'\bcomo diria\b', caseSensitive: false).firstMatch(text);
    if (match != null) {
      final before = text.substring(0, match.start).trim();
      if (before.length >= 20) {
        text = before;
      }
    }

    // If the model adds a fake title/attribution inside the quote (e.g. "em '...'" / "de Autor"),
    // cut the excerpt before that clause to keep the quote clean.
    final emTitle =
        RegExp("\\bem\\s+['\"“]", caseSensitive: false).firstMatch(text);
    if (emTitle != null) {
      final titleStart = emTitle.start;
      final before = text.substring(0, titleStart);
      final lastComma = before.lastIndexOf(',');
      final cutAt = (lastComma != -1 && (titleStart - lastComma) <= 140)
          ? lastComma
          : titleStart;
      text = text.substring(0, cutAt).trim();
      if (text.isNotEmpty && !RegExp(r'[.!?…]$').hasMatch(text)) {
        text = '$text…';
      }
    }

    // Remove any accidental author/title line breaks.
    text = text.replaceAll(RegExp(r'\s*\n+\s*'), ' ').trim();
    text = text.replaceAll(RegExp(r'\s+'), ' ').trim();

    if (text.length > _maxQuoteChars) {
      text = text.substring(0, _maxQuoteChars).trimRight();
      text = text.replaceAll(RegExp(r'[.,;:!?]\s*$'), '');
      text = '$text…';
    }

    return text.trim();
  }

  static bool _isAllowedAuthor(String author) {
    return _recurringAuthors.contains(author.trim());
  }

  static bool _looksInvalidQuote(String quote) {
    final q = quote.trim();
    if (q.isEmpty) return true;
    if (q.length < 24) return true;
    if (q.length > (_maxQuoteChars * 2)) return true; // before sanitization
    if (RegExp(r'\bcomo diria\b', caseSensitive: false).hasMatch(q)) {
      return true;
    }
    if (q.contains('—') || q.contains('--')) return true;
    if (RegExp("\\bem\\s+['\"“]", caseSensitive: false).hasMatch(q)) {
      return true;
    }
    if (RegExp(
      r'\b(autor|obra|livro|poema|música|music|song|poem|book)\b',
      caseSensitive: false,
    ).hasMatch(q)) {
      return true;
    }

    // Não permitir que o trecho contenha nomes de autores (evita “... de Elias Verne” etc).
    final lower = q.toLowerCase();
    for (final author in _recurringAuthors) {
      if (lower.contains(author.toLowerCase())) return true;
    }
    for (final author in [
      ..._publicDomainEn.map((e) => e.author),
      ..._publicDomainPt.map((e) => e.author),
    ]) {
      if (lower.contains(author.toLowerCase())) return true;
    }
    return false;
  }

  static String _buildPrompt(String lang) {
    final isEN = lang.toLowerCase().startsWith('en');
    if (isEN) {
      return '''
Write in English.

Create an ORIGINAL short literary excerpt for a reflective journaling app for teenagers.
Tone: poetic, encouraging, introspective.
Length: 2–3 sentences, max $_maxQuoteChars characters.

Use ALWAYS one recurring fictional author from this list (exact spelling):
${_authorsLine()}

To increase variety, pick ONE author from the list below as a very LIGHT stylistic inspiration
(rhythm / imagery only). Do NOT mention the author, do NOT mention any work/title, and do NOT quote.
${_influencesLine()}

Do NOT mention any real authors, real works, books, poems, songs, or sources.
Do NOT include any work/title. Do NOT add an attribution line like "— Author".
Do NOT include phrases like "in 'TITLE'" or "by AUTHOR" inside the excerpt.
Do NOT write meta phrases like "as X said" / "como diria".

Return ONLY a valid JSON object (no markdown, no code fences):
{"quote":"...","author":"...","work":""}
''';
    }

    return '''
Escreva em português do Brasil.

Crie um trecho literário ORIGINAL para um app de diário reflexivo voltado para adolescentes.
Tom: poético, acolhedor e introspectivo.
Tamanho: 2–3 frases, no máximo $_maxQuoteChars caracteres.

Use SEMPRE um autor fictício recorrente desta lista (exatamente como está escrito):
${_authorsLine()}

Para aumentar a variedade, escolha UM autor da lista abaixo como inspiração MUITO LEVE
(ritmo / imagens apenas). Não cite o autor, não cite obras e não copie trechos.
${_influencesLine()}

Não mencione autores reais, obras reais, livros, poemas, músicas ou fontes.
Não inclua nome de obra/título. Não escreva linha de autoria tipo "— Autor".
Não inclua “em 'TÍTULO'” nem “de AUTOR” dentro do trecho.
Não use aspas para simular nome de obra (evite '...' e "...").
Não use meta frases como “como diria”.

Responda APENAS com um JSON válido (sem markdown / sem crases):
{"quote":"...","author":"...","work":""}
''';
  }

  static String _stripCodeFences(String text) {
    var t = text.trim();
    if (t.startsWith('```')) {
      t = t.replaceFirst(RegExp(r'^```[a-zA-Z]*\n?'), '');
      t = t.replaceFirst(RegExp(r'```$'), '');
    }
    return t.trim();
  }

  static Map<String, dynamic>? _tryParseJson(String raw) {
    final cleaned = _stripCodeFences(raw);
    final start = cleaned.indexOf('{');
    final end = cleaned.lastIndexOf('}');
    if (start == -1 || end == -1 || end <= start) return null;
    final slice = cleaned.substring(start, end + 1);
    try {
      final decoded = jsonDecode(slice);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<LiteraryQuote> getDailyQuote({
    required String userKey,
    required String lang,
    int variant = 0,
  }) async {
    final day = DateTime.now();
    SharedPreferences? prefs;
    try {
      prefs = await SharedPreferences.getInstance();
    } catch (_) {
      return _shouldUsePublicDomain(day, variant)
          ? publicDomainQuote(lang: lang, variant: variant, day: day)
          : fallbackQuote(lang: lang, variant: variant, day: day);
    }

    final base = _prefsBaseKey(
      userKey: userKey,
      day: day,
      lang: lang,
      variant: variant,
    );

    LiteraryQuote? staleCache;
    try {
      final ts = prefs.getInt('${base}_ts');
      final raw = prefs.getString('${base}_json');
      if (raw != null && raw.trim().isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          final cached = LiteraryQuote.fromJson(
            Map<String, dynamic>.from(decoded),
          );
          if (cached != null) {
            staleCache = cached;
            if (ts != null) {
              final createdAt = DateTime.fromMillisecondsSinceEpoch(ts);
              if (DateTime.now().difference(createdAt) <= _cacheTtl) {
                final cleanedQuote = _sanitizeExcerpt(cached.quote);
                if (!_looksInvalidQuote(cleanedQuote)) {
                  return LiteraryQuote(
                    quote: cleanedQuote,
                    author: cached.author,
                    work: cached.work,
                    source: 'cache',
                  );
                }
              }
            }
          }
        }
      }
    } catch (_) {
      // ignore cache issues and proceed
    }

    if (_shouldUsePublicDomain(day, variant)) {
      final pd = publicDomainQuote(lang: lang, variant: variant, day: day);
      try {
        await prefs.setInt('${base}_ts', DateTime.now().millisecondsSinceEpoch);
        await prefs.setString('${base}_json', jsonEncode(pd.toJson()));
      } catch (_) {
        // ignore cache write failures
      }
      return pd;
    }

    // Gemini via Edge Function (mesmo padrão do app)
    try {
      final accessToken =
          Supabase.instance.client.auth.currentSession?.accessToken ??
              SupabaseConfig.supabaseAnonKey;
      final response = await Supabase.instance.client.functions.invoke(
        'generate-message',
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
        body: {
          'prompt': _buildPrompt(lang),
        },
      );
      final text = (response.data?['text'] as String?)?.trim();
      final json = text == null ? null : _tryParseJson(text);
      final parsed = json == null ? null : LiteraryQuote.fromJson(json);
      if (parsed != null &&
          _isAllowedAuthor(parsed.author) &&
          !_looksInvalidQuote(parsed.quote)) {
        final fixedQuote = _sanitizeExcerpt(parsed.quote);
        if (_looksInvalidQuote(fixedQuote)) {
          throw Exception('Invalid quote after sanitization');
        }
        final value = parsed.toJson()..['source'] = 'gemini';
        value['author'] = parsed.author.trim();
        value['quote'] = fixedQuote;
        value['work'] = '';
        await prefs.setInt(
          '${base}_ts',
          DateTime.now().millisecondsSinceEpoch,
        );
        await prefs.setString('${base}_json', jsonEncode(value));
        return LiteraryQuote(
          quote: fixedQuote,
          author: parsed.author.trim(),
          work: null,
          source: 'gemini',
        );
      }
    } catch (_) {
      // ignore and fallback
    }

    if (staleCache != null) {
      final cleanedQuote = _sanitizeExcerpt(staleCache.quote);
      if (!_looksInvalidQuote(cleanedQuote)) {
        return LiteraryQuote(
          quote: cleanedQuote,
          author: staleCache.author,
          work: staleCache.work,
          source: 'cache',
        );
      }
    }

    final fallback = fallbackQuote(lang: lang, variant: variant, day: day);
    try {
      await prefs.setInt('${base}_ts', DateTime.now().millisecondsSinceEpoch);
      await prefs.setString('${base}_json', jsonEncode(fallback.toJson()));
    } catch (_) {
      // ignore cache write failures
    }
    return fallback;
  }
}
