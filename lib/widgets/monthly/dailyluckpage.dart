import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:my_year_my_story/widgets/shared/main_scaffold.dart';
import 'package:my_year_my_story/supabase/supabase_config.dart';

class DailyLuckPage extends StatefulWidget {
  const DailyLuckPage({Key? key}) : super(key: key);

  @override
  State<DailyLuckPage> createState() => _DailyLuckPageState();
}

class _DailyLuckPageState extends State<DailyLuckPage> {
  bool _isLoading = false;
  String? _luckMessage;
  Color _cardColor = const Color(0xFFECC3E2); // 🎨 cor inicial do card

  final supabase = SupabaseConfig.client;
  final List<Color> _cardColors = [
    const Color(0xFFECC3E2), // rosa suave
    const Color(0xFFE8D4F2), // lilás
    const Color(0xFFD1E8F4), // azul clarinho
    const Color(0xFFE6EACB), // verde pálido
    const Color(0xFFFFE0CC), // pêssego
  ];

  @override
  void initState() {
    super.initState();
    _loadDailyLuck();
  }

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
        final randomIndex =
            DateTime.now().millisecondsSinceEpoch % response.length;
        final randomColor =
        _cardColors[Random().nextInt(_cardColors.length)]; // 🌈 cor aleatória

        setState(() {
          _luckMessage = response[randomIndex][columnToUse];
          _cardColor = randomColor;
          _isLoading = false;
        });
      } else {
        setState(() {
          _luckMessage = '✨ ${"dailyLuck.comeBackTomorrow".tr()}';
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Erro ao carregar sorte: $e');
      setState(() {
        _luckMessage = '☁️ ${"dailyLuck.consultingUniverse".tr()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      currentIndex: 2, // 🍀 menu Sorte do Dia
      title: "My Year, My Story",
      body: Stack(
        children: [
          Container(color: const Color(0xFFFDF9FF)),

          Column(
            children: [
              // 💜 Cabeçalho
              Container(
                width: double.infinity,
                padding:
                const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                margin: const EdgeInsets.only(bottom: 4), // 👈 aproxima do card
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.03),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'dailyLuck.discoverLuck'.tr(),
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFD1186C),
                        letterSpacing: 0.1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'dailyLuck.comeBackTomorrow'.tr(),
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: const Color(0xFF1B1F25),
                        height: 1.3,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12), // 💫 novo espaçamento controlado até o card

              // 🌙 Conteúdo principal
              Expanded(
                child: Center(
                  child: _isLoading
                      ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          3,
                              (i) => Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 5.0),
                            child: Icon(
                              Icons.auto_awesome,
                              color: const Color(0xFFE1BA22),
                              size: 30 + (i * 5),
                            )
                                .animate(
                              delay: Duration(milliseconds: i * 200),
                              onPlay: (controller) =>
                                  controller.repeat(reverse: true),
                            )
                                .scale(
                                begin: const Offset(0.8, 0.8),
                                end: const Offset(1.3, 1.3))
                                .fadeIn(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'dailyLuck.consultingUniverse'.tr(),
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  )
                      : Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28.0),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.easeInOut,
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: _cardColor, // 🌈 cor dinâmica do card
                        boxShadow: [
                          BoxShadow(
                            color: (_cardColor ?? const Color(0xFFECC3E2)).withOpacity(0.25),

                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.auto_awesome,
                              size: 40, color: Color(0xFFB83FA9))
                              .animate()
                              .scale(
                              duration: 1600.ms,
                              begin: const Offset(0.9, 0.9),
                              end: const Offset(1.1, 1.1))
                              .fadeIn(),

                          const SizedBox(height: 20),

                          Text(
                            _luckMessage ?? '',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 17,
                              fontStyle: FontStyle.italic,
                              fontWeight: FontWeight.w400,
                              color: const Color(0xFF151515),
                              height: 1.6,
                            ),
                          ).animate().fadeIn(duration: 1000.ms),

                          const SizedBox(height: 32),

                          ElevatedButton.icon(
                            onPressed: _loadDailyLuck,
                            icon: const Icon(Icons.refresh,
                                color: Colors.white, size: 18),
                            label: Text(
                              'dailyLuck.drawAnother'.tr(),
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF407CC1),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 22, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                          ).animate().fadeIn(delay: 800.ms),
                        ],
                      ),
                    ).animate().fadeIn(duration: 900.ms).scale(
                        begin: const Offset(0.97, 0.97),
                        end: const Offset(1, 1)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
