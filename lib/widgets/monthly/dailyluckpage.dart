import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:myyearmystory/widgets/shared/main_scaffold.dart';
import 'package:myyearmystory/supabase/supabase_config.dart';
import 'package:myyearmystory/screens/premium/premium_popup.dart';


class DailyLuckPage extends StatefulWidget {
  const DailyLuckPage({Key? key}) : super(key: key);

  @override
  State<DailyLuckPage> createState() => _DailyLuckPageState();
}

class _DailyLuckPageState extends State<DailyLuckPage> {
  bool _isLoading = false;
  String? _luckMessage;

  final supabase = SupabaseConfig.client;

  // CONTAGEM DE VIRADAS
  int _turnsToday = 0;
  DateTime? _lastTurnDate;

  // Premium (mudar depois)
  bool _isPremium = false;

  // Cor atual do card
  Color _cardColor = const Color(0xFFDAB6E8);

  // Cores aleatórias
  final List<Color> _cardColors = const [
    Color(0xFFDAB6E8),
    Color(0xFFE8D7F2),
    Color(0xFFECD9F6),
    Color(0xFFFFE3D3),
    Color(0xFFD9F2DC),
  ];

  @override
  void initState() {
    super.initState();

    _loadTurnData().then((_) {
      _loadSavedMessage();
    });
  }

  // ---------------------------------------------------------
  //  🔮 CARREGA ÚLTIMA MENSAGEM SALVA
  // ---------------------------------------------------------
  Future<void> _loadSavedMessage() async {
    final prefs = await SharedPreferences.getInstance();
    final lastMessage = prefs.getString("luck_last_message");

    setState(() {
      _luckMessage = lastMessage ??
          "Clique em 'Virar novamente' para revelar sua mensagem do dia ✨";
    });
  }

  // ---------------------------------------------------------
  //  🔮 CARREGA DADOS DE VIRADA
  // ---------------------------------------------------------
  Future<void> _loadTurnData() async {
    final prefs = await SharedPreferences.getInstance();

    final savedDate = prefs.getString("luck_last_turn_date");
    final savedTurns = prefs.getInt("luck_turns_today") ?? 0;

    if (savedDate != null) {
      _lastTurnDate = DateTime.parse(savedDate);

      if (!_isSameDay(_lastTurnDate!, DateTime.now())) {
        _turnsToday = 0;
      } else {
        _turnsToday = savedTurns;
      }
    }
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  // ---------------------------------------------------------
  //  🔮 VERIFICA SE PODE VIRAR HOJE
  // ---------------------------------------------------------
  Future<bool> _canTurnCard() async {
    if (_isPremium) {
      return _turnsToday < 1; 
    } else {
      return _turnsToday < 3;
    }
  }

  // ---------------------------------------------------------
  //  🔄 REGISTRA VIRADA
  // ---------------------------------------------------------
  Future<void> _registerTurn() async {
    final prefs = await SharedPreferences.getInstance();

    _turnsToday++;
    _lastTurnDate = DateTime.now();

    await prefs.setString(
      "luck_last_turn_date",
      _lastTurnDate!.toIso8601String(),
    );

    await prefs.setInt("luck_turns_today", _turnsToday);
  }

  // ---------------------------------------------------------
  //  🌟 BUSCA NOVA FRASE DO BANCO
  // ---------------------------------------------------------
  Future<void> _loadDailyLuck() async {
    setState(() {
      _isLoading = true;
      _luckMessage = null;
    });

    try {
      await Future.delayed(const Duration(seconds: 1));

      final currentLocale = context.locale.languageCode;
      final columnToUse = currentLocale == 'en' ? 'phrase_en' : 'phrase';

      final response = await supabase
          .from('daily_luck')
          .select(columnToUse)
          .eq('active', true);

      if (response.isNotEmpty) {
        final randomIndex = Random().nextInt(response.length);

        setState(() {
          _luckMessage = response[randomIndex][columnToUse];
          _cardColor = _cardColors[Random().nextInt(_cardColors.length)];
          _isLoading = false;
        });

        // SALVA A NOVA MENSAGEM
        final prefs = await SharedPreferences.getInstance();
        prefs.setString("luck_last_message", _luckMessage!);

      } else {
        setState(() {
          _luckMessage = "✨ ${"dailyLuck.comeBackTomorrow".tr()}";
          _isLoading = false;
        });
      }

    } catch (e) {
      setState(() {
        _luckMessage = "☁️ ${"dailyLuck.consultingUniverse".tr()}";
        _isLoading = false;
      });
    }
  }

  // ---------------------------------------------------------
  // ❤️ CORAÇÃO QUE PULSA
  // ---------------------------------------------------------
  Widget _pulseHeart(Color color, int delay) {
    return Icon(Icons.favorite, color: color, size: 26)
        .animate(
          onPlay: (c) => c.repeat(reverse: true),
          delay: Duration(milliseconds: delay),
        )
        .scale(begin: const Offset(0.8, 0.8), end: const Offset(1.2, 1.2))
        .fadeIn();
  }

  // ---------------------------------------------------------
  // ⏳ CARD DE LOADING
  // ---------------------------------------------------------
  Widget _buildLoadingCard() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _pulseHeart(const Color(0xFFA84ABF), 0),
            const SizedBox(width: 12),
            _pulseHeart(const Color(0xFFD4BA33), 150),
            const SizedBox(width: 12),
            _pulseHeart(const Color(0xFFC27FDB), 300),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          "Consultando o universo... ✨",
          style: GoogleFonts.robotoMono(
            fontSize: 14,
            color: Colors.black54,
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------
  //  💌 CARD DA MENSAGEM
  // ---------------------------------------------------------
  Widget _buildMessageCard() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [

        Text(
          DateFormat("dd, MMM yyyy").format(DateTime.now()).toUpperCase(),
          style: GoogleFonts.robotoMono(
            fontSize: 16,
            color: Colors.black87,
            letterSpacing: 2,
          ),
        ),

        const SizedBox(height: 22),

        Column(
          children: const [
            Icon(Icons.favorite, size: 22, color: Color(0xFFD4BA33)),
            SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.favorite, size: 22, color: Color(0xFFA84ABF)),
                SizedBox(width: 10),
                Icon(Icons.favorite, size: 20, color: Color(0xFFC27FDB)),
              ],
            ),
          ],
        ),

        const SizedBox(height: 22),

        Text(
          _luckMessage ?? "",
          textAlign: TextAlign.center,
          style: GoogleFonts.dmSerifDisplay(
            fontSize: 20,
            height: 1.6,
            color: const Color.fromARGB(221, 76, 30, 81),
          ),
        ),

        const SizedBox(height: 28),

        // ---------------------------------------------------------
        //  🌙 BOTÃO DE VIRAR
        // ---------------------------------------------------------
        TextButton.icon(
          onPressed: () async {
            final canTurn = await _canTurnCard();

            if (!canTurn) {
              if (_isPremium) {
                // PREMIUM → popup simples
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    title: const Text(
                      "Limite diário atingido 💜",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    content: const Text(
                      "Você já virou sua carta hoje.\nVolte amanhã para uma nova mensagem ✨",
                    ),
                  ),
                );
              } else {
                // FREE → popup premium padrao
                showPremiumPopup(context);
              }
              return;
            }

            setState(() => _isLoading = true);

            await _loadDailyLuck();
            await _registerTurn();
          },
          icon: const Icon(Icons.refresh, color: Color(0xFFA84ABF)),
          label: Text(
            "Virar novamente",
            style: GoogleFonts.robotoMono(
              color: Colors.black87,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------
  //  🌟 UI COMPLETA
  // ---------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      currentIndex: 2,
      title: "My Year, My Story",
      body: Stack(
        children: [
          Container(color: const Color(0xFFFDF9FF)),

          Column(
            children: [
              // 🌙 HEADER CURVO
              Container(
                width: double.infinity,
                padding: const EdgeInsets.only(top: 45, bottom: 40),
                decoration: const BoxDecoration(
                  color: Color(0xFFF1D7F2),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(120),
                    bottomRight: Radius.circular(120),
                  ),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.favorite,
                        color: Color(0xFFA84ABF), size: 35),
                    const SizedBox(height: 8),

                    Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 22),
                      decoration: const BoxDecoration(
                        color: Color(0xFFEBCCE9),
                        borderRadius: BorderRadius.all(Radius.circular(14)),
                      ),
                      child: Text(
                        "MENSAGEM DO DIA",
                        style: GoogleFonts.robotoMono(
                          fontSize: 18,
                          letterSpacing: 1.4,
                          color: Colors.black87,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    Text(
                      "TODO DIA UMA MENSAGEM NOVA PRA\nVOCÊ SE INSPIRAR",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.robotoMono(
                        fontSize: 12,
                        height: 1.4,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28.0),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 600),
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: _cardColor,
                      borderRadius: BorderRadius.circular(40),
                      boxShadow: [
                        BoxShadow(
                          color: _cardColor.withOpacity(0.30),
                          blurRadius: 22,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: AnimatedSwitcher(
                      duration: 600.ms,
                      transitionBuilder: (child, animation) {
                        return ScaleTransition(
                          scale: Tween(begin: 0.0, end: 1.0).animate(
                            CurvedAnimation(
                              parent: animation,
                              curve: Curves.easeOutBack,
                            ),
                          ),
                          child: child,
                        );
                      },
                      child:
                          _isLoading ? _buildLoadingCard() : _buildMessageCard(),
                    ),
                  )
                      .animate()
                      .moveY(
                        begin: 60,
                        end: 0,
                        duration: 700.ms,
                        curve: Curves.easeOutCubic,
                      )
                      .fadeIn(duration: 600.ms),
                ),
              ),

              Container(
                height: 1,
                color: Colors.black,
                margin: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 30,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
