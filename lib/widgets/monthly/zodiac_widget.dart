import 'package:flutter/material.dart';
import 'package:myyearmystory/widgets/shared/month_page_template.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:google_fonts/google_fonts.dart';

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

      // ------------------------
      // SIGNO DO DIA
      // ------------------------
      for (final row in rows) {
        final start = DateTime.parse(row['start_date']);
        final end = DateTime.parse(row['end_date']);

        if (!start.isAfter(now) && !end.isBefore(now)) {
          _todaySign = row;
          break;
        }
      }

      // ------------------------
      // SIGNO DO INÍCIO DO MÊS
      // ------------------------
      final monthStartDate = DateTime(widget.year, widget.month, 1);

      _startSign = rows.firstWhere(
        (row) {
          final s = DateTime.parse(row['start_date']);
          final e = DateTime.parse(row['end_date']);
          return !s.isAfter(monthStartDate) && !e.isBefore(monthStartDate);
        },
        orElse: () => {},
      );

      // ------------------------
      // SIGNO DO FIM DO MÊS
      // ------------------------
      final lastDay = DateTime(widget.year, widget.month + 1, 0);

      _endSign = rows.firstWhere(
        (row) {
          final s = DateTime.parse(row['start_date']);
          final e = DateTime.parse(row['end_date']);
          return !s.isAfter(lastDay) && !e.isBefore(lastDay);
        },
        orElse: () => {},
      );

      setState(() {});
    } catch (e) {
      debugPrint("Erro ao carregar signos → $e");
    }

    setState(() => _isLoading = false);
  }

  // -----------------------------------------------------
  // CARD DO SIGNO (um card completo, com tabela 2x3)
  // -----------------------------------------------------
  Widget _zodiacCard(Map<String, dynamic> sign) {
  final isEN = context.locale.languageCode == 'en';

  final name = isEN ? sign['signo_en'] : sign['signo_pt'];
  final description = isEN ? sign['descricao_en'] : sign['descricao_pt'];
  final phrase = isEN ? sign['frase_en'] : sign['frase_pt'];

  final period = isEN ? sign['periodo_en'] : sign['periodo_pt'];

  final color = const Color(0xFFF5DCEB);

  return Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 26),
    margin: const EdgeInsets.only(bottom: 28),
    decoration: BoxDecoration(
      color: color.withOpacity(0.45),
      borderRadius: BorderRadius.circular(26),
      border: Border.all(color: color, width: 2),
    ),
    child: Column(
      children: [
        // ÍCONE DO SIGNO
        Text(
          sign["emoji"] ?? "⭐",
          style: const TextStyle(fontSize: 60),
        ),

        const SizedBox(height: 12),

        // NOME DO SIGNO
        Text(
          name.toUpperCase(),
          style: GoogleFonts.poppins(
            fontSize: 26,
            fontWeight: FontWeight.w700,
          ),
        ),

        const SizedBox(height: 6),

        // PERÍODO ABAIXO DO NOME
        Text(
          period,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),

        const SizedBox(height: 18),

        // DESCRIÇÃO DO SIGNO
        Text(
          description,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 15,
            height: 1.45,
            color: Colors.black87,
          ),
        ),

        const SizedBox(height: 28),

        // TABELA 2x3 (SEM LINHA NO MEIO!)
        Row(
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

            const SizedBox(width: 20), // ESPAÇO ENTRE AS COLUNAS

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
        ),

        const SizedBox(height: 32),

        // FRASE DO SIGNO
        Text(
          "“$phrase”",
          textAlign: TextAlign.center,
          style: GoogleFonts.satisfy(
            fontSize: 22,
            height: 1.4,
            color: const Color(0xFF554587),
          ),
        ),

        const SizedBox(height: 12),
      ],
    ),
  );
}


  // -----------------------------------------------------
  // ITEM DA TABELA 2x3
  // -----------------------------------------------------
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
        Text(
          value,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 15),
        ),
      ],
    );
  }

  // -----------------------------------------------------
  // TELA COMPLETA
  // -----------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return MonthPageTemplate(
      month: widget.month,
      year: widget.year,
      title: '',
      pageLabel: 'zodiac.title'.tr(),
      labelColor: const Color.fromARGB(255, 141, 99, 195),
      
      description: "zodiac.month_description".tr(),
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    final isEN = context.locale.languageCode == 'en';

    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 14),

          // -----------------------
          // SIGNO DO DIA (linha discreta)
          // -----------------------
          if (_todaySign != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Text(
                "${'zodiac.today_sign'.tr()}: "
                "${isEN ? _todaySign!['signo_en'] : _todaySign!['signo_pt']}",
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  color: Colors.black.withOpacity(0.65),
                ),
                textAlign: TextAlign.center,
              ),
            ),

          // CARD DO INÍCIO DO MÊS
          if (_startSign != null && _startSign!.isNotEmpty)
            _zodiacCard(_startSign!),

          // CARD DO FIM DO MÊS (se diferente do primeiro)
          if (_endSign != null &&
              _endSign!.isNotEmpty &&
              _endSign!['id'] != _startSign!['id'])
            _zodiacCard(_endSign!),
        ],
      ),
    );
  }
}
