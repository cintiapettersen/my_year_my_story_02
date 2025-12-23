import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ZodiacWidget extends StatefulWidget {
  final int month;
  final int year;

  const ZodiacWidget({
    super.key,
    required this.month,
    required this.year,
  });

  @override
  State<ZodiacWidget> createState() => _ZodiacWidgetState();
}

class _ZodiacWidgetState extends State<ZodiacWidget> {
  bool _isLoading = false;

  Map<String, dynamic>? _todaySign;
  Map<String, dynamic>? _startSign;
  Map<String, dynamic>? _endSign;

  @override
  void initState() {
    super.initState();
    _loadZodiacData();
  }

  // --------------------------------------------------------
  // CARREGAR DADOS
  // --------------------------------------------------------
  Future<void> _loadZodiacData() async {
    setState(() => _isLoading = true);

    try {
      final supabase = Supabase.instance.client;
      final rows = await supabase.from('zodiac_signs').select('*');

      if (rows.isEmpty) {
        setState(() => _isLoading = false);
        return;
      }

      final now = DateTime.now();
      final monthStart = DateTime(widget.year, widget.month, 1);

      for (final row in rows) {
        final start = DateTime(
          widget.year,
          row['start_month'],
          row['start_day'],
        );
        final end = DateTime(
          widget.year,
          row['end_month'],
          row['end_day'],
        );

        if (!start.isAfter(now) && !end.isBefore(now)) {
          _todaySign = row;
        }

        if (!start.isAfter(monthStart) && !end.isBefore(monthStart)) {
          _startSign = row;
        }

        if (start.month == widget.month &&
            (_startSign == null || row['id'] != _startSign!['id'])) {
          _endSign = row;
        }
      }
    } catch (e) {
      debugPrint('Erro ao carregar signos: $e');
    }

    setState(() => _isLoading = false);
  }

  // --------------------------------------------------------
  // CORES
  // --------------------------------------------------------
  final Map<String, Color> zodiacColors = {
    "Áries": Color(0xFFEAB6B6),
    "Touro": Color(0xFFCBE8DE),
    "Gêmeos": Color(0xFFF0E9CC),
    "Câncer": Color(0xFFD1D3D5),
    "Leão": Color(0xFFE4B293),
    "Virgem": Color(0xFFDDECE4),
    "Libra": Color(0xFFEAD8EB),
    "Escorpião": Color(0xFFE4A1A1),
    "Sagitário": Color(0xFF9EADD3),
    "Capricórnio": Color(0xFFDDDDDD),
    "Aquário": Color(0xFFD3E6F6),
    "Peixes": Color(0xFFC9CDE8),
  };

  // --------------------------------------------------------
  // CARD
  // --------------------------------------------------------
  Widget _zodiacCard(Map<String, dynamic> sign) {
    final isEN = context.locale.languageCode == 'en';
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 700;

    final name = isEN ? sign['signo_en'] : sign['signo_pt'];
    final description = isEN ? sign['descricao_en'] : sign['descricao_pt'];
    final phrase = isEN ? sign['frase_en'] : sign['frase_pt'];
    final period = isEN ? sign['periodo_en'] : sign['periodo_pt'];

    final color = zodiacColors[name.trim()] ?? const Color(0xFFF5DCEB);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 28),
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 26),
      decoration: BoxDecoration(
        color: color.withOpacity(0.45),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: color, width: 2),
      ),
      child: Column(
        children: [
          Text(sign['emoji'] ?? '⭐', style: const TextStyle(fontSize: 60)),
          const SizedBox(height: 12),
          Text(
            name.toUpperCase(),
            style: GoogleFonts.poppins(
              fontSize: 26,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            period,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: 15),
          ),
          const SizedBox(height: 18),
          Text(
            description,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: 15, height: 1.45),
          ),
          const SizedBox(height: 28),

          isTablet
              ? Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: _infoRow(sign, isEN),
                  ),
                )
              : _infoRow(sign, isEN),

          const SizedBox(height: 32),
          Text(
            '“$phrase”',
            textAlign: TextAlign.center,
            style: GoogleFonts.satisfy(
              fontSize: 22,
              color: const Color(0xFF554587),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(Map<String, dynamic> sign, bool isEN) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            children: [
              _zItem("zodiac.color".tr(),
                  isEN ? sign['cor_en'] : sign['cor_pt']),
              const SizedBox(height: 18),
              _zItem("zodiac.number".tr(), sign['numero']),
              const SizedBox(height: 18),
              _zItem("zodiac.element".tr(),
                  isEN ? sign['elemento_en'] : sign['elemento_pt']),
            ],
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            children: [
              _zItem("zodiac.stone".tr(),
                  isEN ? sign['pedra_en'] : sign['pedra_pt']),
              const SizedBox(height: 18),
              _zItem("zodiac.flower".tr(),
                  isEN ? sign['flor_en'] : sign['flor_pt']),
              const SizedBox(height: 18),
              _zItem("zodiac.ruler".tr(),
                  isEN ? sign['regente_en'] : sign['regente_pt']),
            ],
          ),
        ),
      ],
    );
  }

  Widget _zItem(String label, String value) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(value, textAlign: TextAlign.center),
      ],
    );
  }

  // --------------------------------------------------------
  // BUILD
  // --------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            child: Column(
              children: [
                if (_todaySign != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Text(
                      "${'zodiac.today_sign'.tr()}: ${context.locale.languageCode == 'en' ? _todaySign!['signo_en'] : _todaySign!['signo_pt']}",
                      style: GoogleFonts.poppins(fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ),
                if (_startSign != null) _zodiacCard(_startSign!),
                if (_endSign != null &&
                    _endSign!['id'] != _startSign?['id'])
                  _zodiacCard(_endSign!),
              ],
            ),
          );
  }
}
