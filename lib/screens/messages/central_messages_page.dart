import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../models/message_card.dart';
import '../../models/message_category.dart';
import '../../services/message_service_supabase.dart';
import '../../widgets/shared/remote_data_wrapper.dart';

import '../../widgets/shared/main_scaffold.dart';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';




class CentralMessagesPage extends StatefulWidget {
  const CentralMessagesPage({super.key});

  @override
  State<CentralMessagesPage> createState() => _CentralMessagesPageState();
}

class _CentralMessagesPageState extends State<CentralMessagesPage> {
  late final MessageServiceSupabase _messageService;

  MessageType _activeType = MessageType.weeklyReflection;
  MessageCard? _currentCard;
  bool _isLoading = false;
  bool _hasError = false;

  bool _isFavorite = false;
  bool _hasRequestedCard = false;


  final GlobalKey _cardKey = GlobalKey();

@override
void initState() {
  super.initState();

  _messageService = MessageServiceSupabase(
    Supabase.instance.client,
  );

  _loadCard(); // 👉 ESSENCIAL
}

 Future<void> _loadCard() async {
  setState(() {
    _isLoading = true;
    _hasError = false;
    _currentCard = null;
  });

  try {
    final outputLanguage = resolveOutputLanguage(context);

    if (kDebugMode) {
  debugPrint('OUTPUT LANGUAGE (UI): $outputLanguage');
}


    final card = await _messageService.getCardByType(
      _activeType,
      semanticContext: null, // ou seu texto
      outputLanguage: outputLanguage,
    );

    if (!mounted) return;

    setState(() {
      _currentCard = card;
      _isFavorite = false;
      _isLoading = false;
    });
  } catch (_) {
    if (!mounted) return;
    setState(() {
      _hasError = true;
      _isLoading = false;
    });
  }
}


 void _changeType(MessageType type) {
  setState(() {
    _activeType = type;
    _currentCard = null;
    _hasRequestedCard = false; // 👈 AQUI
  });
}




  Future<void> _toggleFavorite() async {
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null || _currentCard == null || _currentCard!.id == null) {
  return;
}


  final supabase = Supabase.instance.client;

  if (_isFavorite) {
    // remover favorito
    await supabase
        .from('favorites')
        .delete()
        .eq('user_id', user.id)
        .eq('message_id', _currentCard!.id!);

    setState(() => _isFavorite = false);
  } else {
    // salvar favorito
    await supabase.from('favorites').insert({
      'user_id': user.id,
      'message_id': _currentCard!.id,
    });

    setState(() => _isFavorite = true);
  }
}



Future<void> _saveCardAsImage() async {
  if (_cardKey.currentContext == null) {
   if (kDebugMode) {
  debugPrint('Erro ao salvar imagem: $e');
}

    return;
  }
  try {
    final boundary =
        _cardKey.currentContext!.findRenderObject() as RenderRepaintBoundary;

    final image = await boundary.toImage(pixelRatio: 3);
    final byteData =
        await image.toByteData(format: ui.ImageByteFormat.png);

    if (byteData == null) return;

    final pngBytes = byteData.buffer.asUint8List();

    await Share.shareXFiles(
      [
        XFile.fromData(
          pngBytes,
          mimeType: 'image/png',
          name: 'my_year_my_story.png',
        ),
      ],
      text: 'cards.share_text'.tr(),
    );

  if (!mounted) return;

ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Text(
      'cards.image_ready'.tr(),
      style: const TextStyle(color: Colors.white),
    ),
    backgroundColor: const Color.fromARGB(255, 203, 55, 151),
    behavior: SnackBarBehavior.floating,
    duration: const Duration(seconds: 2),
  ),
);


  } catch (e) {
    if (kDebugMode) {
  debugPrint('RepaintBoundary não está pronto');
}

  }
}


// ---------------------------------------------------------------------------
// 🌍 Idioma
// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------
// 🌍 Idioma de saída (fonte única de verdade para IA)
// ---------------------------------------------------------------------------



String resolveOutputLanguage(BuildContext context) {
  final uiLang = context.locale.languageCode;

  if (uiLang == 'pt') return 'pt';
  if (uiLang == 'en') return 'en';

  return 'pt'; // fallback seguro
}




//titulos dentro do card
Widget _buildHeader() {
  return Padding(
    padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
    child: Column(
      children: [
        Text(
          tr('cards.page_title'), // ex: "Weekly Readings"
          style: GoogleFonts.monteCarlo (
            letterSpacing: 1.5,
            fontSize: 33,
            fontWeight: FontWeight.w600,


   //descricao         
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          tr('cards.onboarding'),
          style: GoogleFonts.robotoMono(
            fontSize: 12,
            color: const Color.fromARGB(137, 0, 0, 0),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );
}


/// UI Helpers
@override
Widget build(BuildContext context) {
  return MainScaffold(
    currentIndex: 1, // ajuste para o índice correto do menu inferior
    body: Container(
      color: const Color(0xFFFCE9EF), // fundo da página
      child: Column(
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
          _buildHint(),
          const SizedBox(height: 12),
          _buildTypeChips(),
          const SizedBox(height: 24),

          Expanded(
  child: _buildMainCard(),
),

        ],
      ),
    ),
  );
}




Widget _buildCardContent() {
  String resolveCardText(String rawText) {
    if (rawText.startsWith('cards.')) {
      return rawText.tr();
    }
    return rawText;
  }




  // 🟡 1. ANTES DE CLICAR EM REVEAL
  if (!_hasRequestedCard && _currentCard != null) {
    return Center(
      child: Text(
        resolveCardText(_currentCard!.text),
        textAlign: TextAlign.center,
        style: GoogleFonts.robotoSerif(
          fontSize: 14,
          height: 1.6,
          color: Colors.black45,
        ),
      ),
    );
  }

  // 🟡 2. ESTADO INICIAL ABSOLUTO
  if (!_hasRequestedCard) {
    return Center(
      child: Text(
        tr('cards.placeholder'),
        textAlign: TextAlign.center,
        style: GoogleFonts.robotoSerif(
          fontSize: 14,
          height: 1.6,
          color: Colors.black45,
        ),
      ),
    );
  }

  // ⏳ 3. LOADING
  if (_currentCard == null) {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

/// ✨ 4. CARTA — Gemini ou fallback
return Center(
  child: Stack(
    children: [
      // 🔹 Aspas decorativas
      Positioned(
        top: -35,
        left: 0,
        child: Text(
          '“',
          style: GoogleFonts.playfairDisplay(
            fontSize: 80,
            color: const Color.fromARGB(255, 7, 7, 7).withValues(alpha: 0.20),
          ),
        ),
      ),

      // 🔹 Texto principal
      Padding(
        padding: const EdgeInsets.only(top: 24),
        child: Align(
          alignment: Alignment.center,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 280,
            ),
            child: Text(
              resolveCardText(_currentCard!.text),
              textAlign: TextAlign.center,
              style: GoogleFonts.playfairDisplay(
                fontSize: 13,
                height: 1.5,
                letterSpacing: 0.2,
                color: const Color.fromARGB(255, 0, 0, 0),
              ),
            ),
          ),
        ),
      ),
    ],
  ),
);

}


  Widget _buildHint() {
  return Text(
    tr('cards.hint'),
    textAlign: TextAlign.center,
    style: GoogleFonts.robotoMono(
      fontSize: 12,
      color: const Color.fromARGB(255, 62, 58, 60), // 👈 aqui
    ),
  );
}


  Widget _buildTypeChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: MessageType.values.map((type) {
          final isActive = _activeType == type;
          final color = _colorForType(type);

          return GestureDetector(
            onTap: () => _changeType(type),
            child: Container(
  margin: const EdgeInsets.only(right: 10),
  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
  decoration: BoxDecoration(
    color: isActive ? color : color.withOpacity(0.25),
    borderRadius: BorderRadius.circular(20),
    boxShadow: isActive
        ? [
            BoxShadow(
              color: color.withOpacity(0.35),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ]
        : [],
  ),
  child: Text(
    tr(_labelKeyForType(type)),
    style: GoogleFonts.robotoMono(
      fontSize: 12,
      color: Colors.white,
      fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
    ),
  ),
)
);
        }).toList(),
      ),
    );
  }


//titulos dentro do card
Widget _buildMainCard() {
  return Center(
    child: AnimatedSwitcher(
      duration: const Duration(milliseconds: 600),
      transitionBuilder: (child, animation) {
        final rotate = Tween(begin: pi, end: 0.0).animate(animation);

        return AnimatedBuilder(
          animation: rotate,
          child: child,
          builder: (context, child) {
            final tilt =
                ((animation.value - 0.5).abs() - 0.5) * 0.003;

            return Transform(
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..rotateY(rotate.value)
                ..rotateZ(tilt),
              alignment: Alignment.center,
              child: child,
            );
          },
        );
      },

      child: RepaintBoundary(
        key: _cardKey, // 👈 AGORA AQUI (correto)
        child: Container(
          key: ValueKey(
            !_hasRequestedCard
                ? 'placeholder'
                : _currentCard == null
                    ? 'loading'
                    : _activeType,
          ),
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(32),
  boxShadow: [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.06),
      blurRadius: 30,
      offset: const Offset(0, 12),
    ),
  ],
),

          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              /// 🏷️ TÍTULO
              Text(
                tr(_titleKeyForType(_activeType)),
                style: GoogleFonts.robotoMono(
                  fontSize: 13,
                  letterSpacing: 2,
                ),
              ),

              const SizedBox(height: 14),

              /// 📅 DATA
              Text(
                DateFormat('dd/MM/yyyy').format(DateTime.now()),
                style: GoogleFonts.robotoMono(
                  fontSize: 11,
                  color: Colors.black38,
                  letterSpacing: 1,
                ),
              ),


              const SizedBox(height: 20),

              /// 🧠 CONTEÚDO
              Expanded(
                child: _buildCardContent(),
              ),

              const SizedBox(height: 24),

              /// 🔘 AÇÕES
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: _isLoading
                        ? null
                        : () {
                            setState(() => _hasRequestedCard = true);



                            _loadCard();
                          },
                    style: TextButton.styleFrom(
                      backgroundColor:
                          const Color.fromARGB(255, 255, 230, 233),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                    ),
                    child: Text(
                      tr('cards.reveal'),
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFF930F65),
                        letterSpacing: 0.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  IconButton(
                    icon: const Icon(Icons.photo_camera_outlined),
                    onPressed: _currentCard == null
                        ? null
                        : _saveCardAsImage,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

  Color _colorForType(MessageType type) {
    switch (type) {
      case MessageType.weeklyReflection:
        return const Color(0xFFE754A6);
      case MessageType.moodInsight:
        return const Color(0xFF9B59B6);
      case MessageType.personality:
        return const Color.fromARGB(255, 71, 151, 114);
     
    }
  }

  String _labelKeyForType(MessageType type) {
  switch (type) {
    case MessageType.weeklyReflection:
      return 'cards.card_types.weeklyReflection.label';
    case MessageType.moodInsight:
      return 'cards.card_types.moodInsight.label';
    case MessageType.personality:
      return 'cards.card_types.personality.label';
  }
}

String _titleKeyForType(MessageType type) {
  switch (type) {
    case MessageType.weeklyReflection:
      return 'cards.card_types.weeklyReflection.title';
    case MessageType.moodInsight:
      return 'cards.card_types.moodInsight.title';
    case MessageType.personality:
      return 'cards.card_types.personality.title';
  }
}

    
  }
