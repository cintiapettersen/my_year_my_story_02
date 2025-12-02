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
  Map<String, dynamic>? _monthSign;

  String _bannerDescription = '';

  @override
  void initState() {
    super.initState();
    _loadZodiacData();
  }

  Future<void> _loadZodiacData() async {
    setState(() => _isLoading = true);

    try {
      final supabase = Supabase.instance.client;
      final now = DateTime.now();

      final rows = await supabase.from('zodiac_signs').select('*');

      if (rows.isEmpty) {
        setState(() => _isLoading = false);
        return;
      }

      // SIGNO DO DIA BLOQUEADO
      for (final row in rows) {
        final start = DateTime.tryParse(row['start_date'] ?? '') ?? now;
        final end = DateTime.tryParse(row['end_date'] ?? '') ?? now;

        if (!start.isAfter(now) && !end.isBefore(now)) {
          _todaySign = row;
          break;
        }
      }

      // SIGNO DO MÊS - corrigido
      _monthSign = rows.firstWhere(
        (row) => (row['mes'] ?? -1) == widget.month,
        orElse: () => {},
      );

      // descrição segura
      if (_todaySign != null) {
        _bannerDescription = context.locale.languageCode == 'en'
            ? (_todaySign!['descricao_en'] ?? '')
            : (_todaySign!['descricao_pt'] ?? '');
      }

      setState(() {});
    } catch (e) {
      debugPrint("Erro ao carregar signos → $e");
    }

    setState(() => _isLoading = false);
  }

  // BOX COLORIDA
  Widget _infoBox(String label, String? value, Color color) {
    if (value == null || value.trim().isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value.trim(),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 15, height: 1.35),
          )
        ],
      ),
    );
  }

  String formatDateShort(String date, bool isEN) {
    final dt = DateTime.tryParse(date) ?? DateTime.now();

    const monthsPt = [
      "Jan.", "Fev.", "Mar.", "Abr.", "Mai.", "Jun.",
      "Jul.", "Ago.", "Set.", "Out.", "Nov.", "Dez."
    ];

    const monthsEn = [
      "Jan.", "Feb.", "Mar.", "Apr.", "May.", "Jun.",
      "Jul.", "Aug.", "Sep.", "Oct.", "Nov.", "Dec."
    ];

    final month = isEN ? monthsEn[dt.month - 1] : monthsPt[dt.month - 1];

    return "${dt.day} $month";
  }

  @override
  Widget build(BuildContext context) {
    return MonthPageTemplate(
      month: widget.month,
      year: widget.year,
      title: '',
      pageLabel: 'zodiac.title'.tr(),
      labelColor: const Color.fromARGB(255, 141, 99, 195),
      useScaffoldContainer: false,
      description: _bannerDescription.isNotEmpty
          ? _bannerDescription
          : 'zodiac.description'.tr(),
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _todaySign == null
              ? Center(
                  child: Text(
                    'zodiac.no_data'.tr(),
                    style: const TextStyle(color: Colors.grey),
                  ),
                )
              : _buildZodiacContent(),
    );
  }

  Widget _buildZodiacContent() {
    final sign = _todaySign!;
    final isEN = context.locale.languageCode == 'en';

    // nome
    final name = (isEN ? sign['signo_en'] : sign['signo_pt']) ?? '—';

    // período abreviado
    final startShort = formatDateShort(sign['start_date'] ?? '', isEN);
    final endShort = formatDateShort(sign['end_date'] ?? '', isEN);
    final periodShort = "$startShort — $endShort";

    // dados do mês
    final colorText = _monthSign?[isEN ? "cor_en" : "cor_pt"] ?? '';
    final regenteText = _monthSign?[isEN ? "regente_en" : "regente_pt"] ?? '';
    final numeroText = _monthSign?["numero"]?.toString() ?? '';
    final elementoText =
        _monthSign?[isEN ? "elemento_en" : "elemento_pt"] ?? '';
    final pedraText = _monthSign?[isEN ? "pedra_en" : "pedra_pt"] ?? '';
    final florText = _monthSign?[isEN ? "flor_en" : "flor_pt"] ?? '';

    // LUA
    final moonPhase = getMoonPhase(DateTime.now(), isEN: isEN);
    final moonEmoji = getMoonEmoji(moonPhase);

    return Column(
      children: [
        const SizedBox(height: 20),
        Text(sign['emoji'] ?? '⭐', style: const TextStyle(fontSize: 60)),
        const SizedBox(height: 16),

        Text(
          'zodiac.today_sign'.tr(),
          style: const TextStyle(
              fontSize: 15,
              fontStyle: FontStyle.italic,
              color: Colors.black54),
        ),

        const SizedBox(height: 4),

        Text(
          name.toUpperCase(),
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),

        const SizedBox(height: 10),

        Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.black26, width: 1.2),
          ),
          child: Text(
            periodShort,
            style: const TextStyle(fontSize: 16),
          ),
        ),

        const SizedBox(height: 8),

        Text(
          "${'zodiac.moon_today'.tr()}: $moonEmoji $moonPhase",
          style: TextStyle(
              fontSize: 14,
              fontStyle: FontStyle.italic,
              color: Colors.black.withOpacity(0.7)),
        ),

        const SizedBox(height: 26),

        // GRID
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: 1.18,
          children: [
            _infoBox("Cor", colorText, const Color(0xFFFAD4D8)),
            _infoBox("Regente", regenteText, const Color(0xFFE95C8B)),
            _infoBox("Número", numeroText, const Color(0xFF97C0DB)),
            _infoBox("Elemento", elementoText, const Color(0xFFDCE073)),
            _infoBox("Pedra", pedraText, const Color(0xFFB49AE9)),
            _infoBox("Flor", florText, const Color(0xFFD7CFF2)),
          ],
        ),

        const SizedBox(height: 40),

        // FRASE
        Row(
          children: [
            Expanded(child: Container(height: 1, color: Colors.black26)),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Icon(Icons.circle, size: 6, color: Colors.black38),
            ),
            Expanded(child: Container(height: 1, color: Colors.black26)),
          ],
        ),

        const SizedBox(height: 24),

        Text(
          'zodiac.phrase_title'.tr(),
          style: GoogleFonts.satisfy(
            fontSize: 24,
            color: const Color(0xFF554587),
          ),
        ),

        const SizedBox(height: 12),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            (isEN ? sign['frase_en'] : sign['frase_pt']) ?? '',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 15, height: 1.4),
          ),
        ),

        const SizedBox(height: 30),
      ],
    );
  }

  // -----------------------------------------------
  // LUA
  // -----------------------------------------------
  String getMoonPhase(DateTime date, {required bool isEN}) {
    final lp = 2551443;
    final newDate = DateTime(1970, 1, 7, 20, 35);

    final phase =
        ((date.millisecondsSinceEpoch - newDate.millisecondsSinceEpoch) /
                1000) %
            lp;

    final phaseIndex = ((phase / (lp / 8))).floor();

    final phasesPt = [
      "Nova",
      "Crescente",
      "Quarto Crescente",
      "Gibosa Crescente",
      "Cheia",
      "Gibosa Minguante",
      "Quarto Minguante",
      "Minguante"
    ];

    final phasesEn = [
      "New Moon",
      "Waxing Crescent",
      "First Quarter",
      "Waxing Gibbous",
      "Full Moon",
      "Waning Gibbous",
      "Last Quarter",
      "Waning Crescent"
    ];

    return isEN ? phasesEn[phaseIndex] : phasesPt[phaseIndex];
  }

  String getMoonEmoji(String phase) {
  if (phase.contains('Nova') || phase.contains('New')) {
    return '🌑';
  }
  if (phase.contains('Waxing Crescent') || phase.contains('Crescente')) {
    return '🌒';
  }
  if (phase.contains('First Quarter') || phase.contains('Quarto Crescente')) {
    return '🌓';
  }
  if (phase.contains('Waxing Gibbous') || phase.contains('Gibosa Crescente')) {
    return '🌔';
  }
  if (phase.contains('Cheia') || phase.contains('Full')) {
    return '🌕';
  }
  if (phase.contains('Waning Gibbous') || phase.contains('Gibosa Minguante')) {
    return '🌖';
  }
  if (phase.contains('Last Quarter') || phase.contains('Quarto Minguante')) {
    return '🌗';
  }
  if (phase.contains('Waning Crescent') || phase.contains('Minguante')) {
    return '🌘';
  }

  return '✨';
}
}
