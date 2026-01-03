import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';

import 'package:myyearmystory/supabase/supabase_config.dart';
import 'package:myyearmystory/screens/premium/premium_popup.dart';
import 'package:myyearmystory/widgets/shared/app_bottom_menu.dart';
import 'package:myyearmystory/screens/premium/limit_popup.dart';
import 'package:myyearmystory/screens/premium/free_limit_popup.dart';

import 'package:myyearmystory/utils/app_config.dart';
import 'package:myyearmystory/utils/access_control.dart';
import 'package:flutter/foundation.dart';

class DailyLuckPage extends StatefulWidget {
  const DailyLuckPage({Key? key}) : super(key: key);

  @override
  State<DailyLuckPage> createState() => _DailyLuckPageState();
}

class _DailyLuckPageState extends State<DailyLuckPage> {
  bool _isLoading = false;
  String? _luckMessage;

  final supabase = SupabaseConfig.client;

  int _turnsToday = 0;
  DateTime? _lastTurnDate;

  bool _isPremium = false;

  Color _cardColor = const Color(0xFFDAB6E8);

  final List<Color> _cardColors = const [
    Color(0xFFDAB6E8),
    Color(0xFFF2D7EA),
    Color(0xFFFABFE7),
    Color(0xFFEDC3EF),
    Color.fromARGB(255, 188, 209, 231),
  ];

  @override
  void initState() {
    super.initState();
    _initializePage();
  }

  Future<void> _initializePage() async {
    _isPremium = await AccessControl.isPremium();
    
    await _loadTurnData();

    final prefs = await SharedPreferences.getInstance();

    final lastMessage = prefs.getString("luck_last_message");
    final savedColorIndex = prefs.getInt("luck_last_color");

    if (savedColorIndex != null) {
      _cardColor = _cardColors[savedColorIndex];
    }

    if (_turnsToday > 0 && lastMessage != null) {
      _luckMessage = lastMessage;
    } else {
      _luckMessage = "dailyLuck.initialPlaceholder".tr();
    }

    setState(() {});
  }

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

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Future<bool> _canTurnCard() async {
  // 🔓 ilimitado SOMENTE no debug local
  if (kDebugMode) return true;

  if (_isPremium) {
    return _turnsToday < 3;
  }

  return _turnsToday < 1;
}

  Future<void> _registerTurn() async {
    final prefs = await SharedPreferences.getInstance();

    _turnsToday++;
    _lastTurnDate = DateTime.now();

    await prefs.setString("luck_last_turn_date", _lastTurnDate!.toIso8601String());
    await prefs.setInt("luck_turns_today", _turnsToday);

    // 🔥 analytics simples
    await prefs.setInt("luck_total_turns",
        (prefs.getInt("luck_total_turns") ?? 0) + 1);
  }

  Future<void> _loadDailyLuck() async {
  setState(() {
    _isLoading = true;
    _luckMessage = null;
  });

  try {
    await Future.delayed(const Duration(milliseconds: 800));

    final col = context.locale.languageCode == 'en'
        ? 'phrase_en'
        : 'phrase';

    final response = await supabase
        .from('daily_luck')
        .select(col)
        .eq('active', true);

    if (response.isNotEmpty) {
      // 🔮 sorteia mensagem
      final randomIndex = Random().nextInt(response.length);
      _luckMessage = response[randomIndex][col];

      // 🎨 sorteia cor sem repetir a anterior
      final prefs = await SharedPreferences.getInstance();
      final lastColorIndex = prefs.getInt("luck_last_color");

      int newColorIndex;
      do {
        newColorIndex = Random().nextInt(_cardColors.length);
      } while (newColorIndex == lastColorIndex && _cardColors.length > 1);

      _cardColor = _cardColors[newColorIndex];

      // 💾 salva estado
      prefs.setString("luck_last_message", _luckMessage!);
      prefs.setInt("luck_last_color", newColorIndex);
    } else {
      // fallback local
      final fallbackLocal = [
        "dailyLuck.fallback1".tr(),
        "dailyLuck.fallback2".tr(),
        "dailyLuck.fallback3".tr(),
      ];

      _luckMessage =
          fallbackLocal[Random().nextInt(fallbackLocal.length)];
    }
  } catch (_) {
    _luckMessage = "dailyLuck.consultingUniverse".tr();
  }

  setState(() {
    _isLoading = false;
  });
}

  Widget _pulseHeart(Color color, int delay) {
    return Icon(Icons.favorite, color: color, size: 28)
        .animate(delay: Duration(milliseconds: delay))
        .scale(begin: const Offset(0.8, 0.8), end: const Offset(1.25, 1.25))
        .fadeIn()
        .then(delay: 0.ms)
        .animate(onPlay: (c) => c.repeat(reverse: true));
  }

  Widget _buildLoadingCard() {
    return Column(
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
          "dailyLuck.consultingUniverse".tr(),
          style: GoogleFonts.robotoMono(fontSize: 14, color: Colors.black54),
        ),
      ],
    );
  }

  Widget _buildMessageCard() {
    return SingleChildScrollView(
      child: Column(
        children: [
          Text(
            DateFormat("dd, MMM yyyy").format(DateTime.now()).toUpperCase(),
            style: GoogleFonts.robotoMono(
              fontSize: 16,
              letterSpacing: 2,
              color: Colors.black87,
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
            style: GoogleFonts.satisfy(
              fontSize: 25,
              height: 1.6,
              color: const Color.fromARGB(221, 85, 38, 89),
            ),
          ),
          const SizedBox(height: 28),

          /// BOTÃO DE VIRAR CARTA
          TextButton.icon(
            onPressed: () async {
              if (_isLoading) return;

              final canTurn = await _canTurnCard();

              if (!canTurn) {
  if (_isPremium) {
    showLimitPopup(context);
  } else {
    showFreeLimitPopup(context);
  }
  return;
}

              HapticFeedback.lightImpact();

              setState(() => _isLoading = true);

              await _loadDailyLuck();
              await _registerTurn();
            },
            icon: const Icon(Icons.refresh, color: Color(0xFFA84ABF)),
            label: Text(
              "dailyLuck.turnAgain".tr(),
              style: GoogleFonts.robotoMono(fontSize: 14, color: Colors.black87),
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCE9EF),

      appBar: AppBar(
        backgroundColor: const Color(0xFFE91E63),
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          "My Year, My Story",
          style: GoogleFonts.cinzel(
            textStyle: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),

      bottomNavigationBar: const AppBottomMenu(currentIndex: null),

      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 45, bottom: 40),
            decoration: const BoxDecoration(
              color: Color.fromARGB(255, 243, 218, 231),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(100),
                bottomRight: Radius.circular(100),
              ),
            ),
            child: Column(
              children: [
                const Icon(Icons.favorite, color: Color(0xFFA84ABF), size: 35),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 22),
                  decoration: const BoxDecoration(
                    color: Color(0xFFEBCCE9),
                    borderRadius: BorderRadius.all(Radius.circular(14)),
                  ),
                  child: Text(
                    "dailyLuck.title".tr(),
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
                  "dailyLuck.subtitle".tr(),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.robotoMono(
                    fontSize: 11,
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
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 10,
                      spreadRadius: 0,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: AnimatedSwitcher(
                  duration: 600.ms,
                  child: _isLoading
                      ? _buildLoadingCard()
                      : _buildMessageCard(),
                ),
              )
                  .animate()
                  .moveY(begin: 60, end: 0, duration: 700.ms, curve: Curves.easeOutCubic)
                  .fadeIn(duration: 600.ms)
                  .scale(begin: const Offset(0.97, 0.97), end: const Offset(1, 1)),
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
