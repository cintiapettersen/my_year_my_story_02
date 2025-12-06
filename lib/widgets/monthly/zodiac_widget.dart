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

  // --------------------------------------------------------
  // FUNÇÃO INFALÍVEL PARA GERAR INTERVALOS DE SIGNOS
  // --------------------------------------------------------
  Map<String, DateTime> _makeStartEnd(Map<String, dynamic> row, int year) {
    final startMonth = row['start_month'];
    final startDay = row['start_day'];
    final endMonth = row['end_month'];
    final endDay = row['end_day'];

    late DateTime start;
    late DateTime end;

    // SIGNOS QUE NÃO CRUZAM ANO
    if (startMonth <= endMonth) {
      start = DateTime(year, startMonth, startDay);
      end = DateTime(year, endMonth, endDay);
      return {"start": start, "end": end};
    }

    // SIGNOS QUE CRUZAM O ANO (ex: Capricórnio)
    // EX: 22/12 → 19/01
    // SEMPRE:
    // start = ano - 1
    // end   = ano
    start = DateTime(year - 1, startMonth, startDay);
    end = DateTime(year, endMonth, endDay);

    return {"start": start, "end": end};
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

      final year = widget.year;

      final List<Map<String, dynamic>> processed =
          rows.map<Map<String, dynamic>>((row) {
        final dates = _makeStartEnd(row, year);
        return {
          "data": row as Map<String, dynamic>,
          "start": dates["start"]!,
          "end": dates["end"]!,
        };
      }).toList();

      // -------------------------------
      // SIGNO DO DIA
      // -------------------------------
      final now = DateTime.now();
      for (final item in processed) {
        final s = item["start"] as DateTime;
        final e = item["end"] as DateTime;
        if (!s.isAfter(now) && !e.isBefore(now)) {
          _todaySign = item["data"];
          break;
        }
      }

      // -----------------------------------------
      // SIGNO ATIVO NO INÍCIO DO MÊS
      // -----------------------------------------
      final monthStart = DateTime(widget.year, widget.month, 1);

      for (final item in processed) {
        final s = item["start"] as DateTime;
        final e = item["end"] as DateTime;

        if (!s.isAfter(monthStart) && !e.isBefore(monthStart)) {
          _startSign = item["data"];
          break;
        }
      }

      // ---------------------------------------------------
      // SEGUNDO SIGNO DO MÊS → SIGNO QUE COMEÇA NO MÊS
      // ---------------------------------------------------
      for (final item in processed) {
        final s = item["start"] as DateTime;

        if (s.month == widget.month) {
          // evitar duplicar o mesmo signo
          if (_startSign == null ||
              item["data"]['id'] != _startSign!['id']) {
            _endSign = item["data"];
          }
          break;
        }
      }

      setState(() {});
    } catch (e) {
      debugPrint("Erro ao carregar signos → $e");
    }

    setState(() => _isLoading = false);
  }

  // --------------------------------------------------------
  // CORES DOS SIGNOS
  // --------------------------------------------------------
  final Map<String, Color> zodiacColors = {
    "Áries": Color.fromARGB(255, 236, 182, 182),
    "Touro": Color.fromARGB(255, 203, 232, 222),
    "Gêmeos": Color(0xFFF0E9CC),
    "Câncer": Color.fromARGB(255, 209, 211, 213),
    "Leão": Color.fromARGB(255, 228, 178, 147),
    "Virgem": Color(0xFFDDECE4),
    "Libra": Color(0xFFEAD8EB),
    "Escorpião": Color.fromARGB(255, 228, 161, 161),
    "Sagitário": Color.fromARGB(255, 158, 173, 211),
    "Capricórnio": Color.fromARGB(255, 221, 221, 221),
    "Aquário": Color.fromARGB(255, 211, 230, 246),
    "Peixes": Color.fromARGB(255, 201, 205, 232),
  };

  // --------------------------------------------------------
  // UI DO CARD
  // --------------------------------------------------------
  Widget _zodiacCard(Map<String, dynamic> sign) {
    final isEN = context.locale.languageCode == 'en';

    final name = isEN ? sign['signo_en'] : sign['signo_pt'];
    final description = isEN ? sign['descricao_en'] : sign['descricao_pt'];
    final phrase = isEN ? sign['frase_en'] : sign['frase_pt'];
    final period = isEN ? sign['periodo_en'] : sign['periodo_pt'];

    final color = zodiacColors[name.trim()] ?? const Color(0xFFF5DCEB);

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
          Text(sign["emoji"] ?? "⭐", style: const TextStyle(fontSize: 60)),
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
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 18),
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
          ),
          const SizedBox(height: 32),
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

  // --------------------------------------------------------
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

          if (_startSign != null) _zodiacCard(_startSign!),

          if (_endSign != null &&
              _endSign!['id'] != _startSign?['id'])
            _zodiacCard(_endSign!),
        ],
      ),
    );
  }
}
