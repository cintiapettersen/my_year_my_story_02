import 'package:flutter/material.dart';
import 'package:myyearmystory/widgets/shared/month_page_template.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:myyearmystory/screens/popups/popup_login.dart';




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

 bool get isGuest {
  return Supabase.instance.client.auth.currentUser == null;
}



  Map<String, dynamic>? _todaySign;
  Map<String, dynamic>? _startSign;
  Map<String, dynamic>? _endSign;

  @override
  void initState() {
    super.initState();
    _loadZodiacData();
  }

  Map<String, DateTime> _makeStartEnd(
  Map<String, dynamic> row,
  int pageYear,
) {
  final int sm = row['start_month'];
  final int sd = row['start_day'];
  final int em = row['end_month'];
  final int ed = row['end_day'];

  late DateTime start;
  late DateTime end;

  // 🔁 signo atravessa o ano (ex: Capricórnio)
  if (sm > em) {
    start = DateTime(pageYear - 1, sm, sd);
    end = DateTime(pageYear, em, ed);
  } else {
    start = DateTime(pageYear, sm, sd);
    end = DateTime(pageYear, em, ed);
  }

  return {
    "start": start,
    "end": end,
  };
}

void _showPersonalYearModal({
  required Color parsedColor,
  required int year,
  required int personalYear,
  required String title,
  required String meaning,
  required String colorName,
}) {
  showDialog(
    context: context,
    builder: (_) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 26, vertical: 40),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(26),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Text(
                    year.toString(),
                    style: GoogleFonts.sacramento(
                      fontSize: 40,
                      color: parsedColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    tr("zodiac.personal_year_title"),
                    style: GoogleFonts.satisfy(fontSize: 22),
                  ),
                  const SizedBox(height: 22),
                  Container(
                    width: 130,
                    height: 130,
                    decoration: BoxDecoration(
                      color: parsedColor.withOpacity(0.20),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        "$personalYear",
                        style: GoogleFonts.poppins(
                          fontSize: 48,
                          fontWeight: FontWeight.w700,
                          color: parsedColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 26),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: parsedColor,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    meaning,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(fontSize: 15, height: 1.45),
                  ),
                  const SizedBox(height: 26),
                  Column(
  children: [
    Text(
      tr("zodiac.personal_year_color_label"),
      style: GoogleFonts.poppins(
        fontSize: 15,
        fontWeight: FontWeight.w700,
      ),
    ),
    const SizedBox(height: 8),
    Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: parsedColor.withOpacity(0.25),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: parsedColor, width: 1.5),
      ),
      child: Text(
        colorName,
        textAlign: TextAlign.center,
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: parsedColor,
        ),
      ),
    ),
  ],
),

                ],
              ),
            ),
          ),
          Positioned(
            right: 12,
            top: 12,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: const Icon(Icons.close),
            ),
          ),
        ],
      ),
    ),
  );
}

  // --------------------------------------------------------
  // LOAD ZODIAC DATA
  // --------------------------------------------------------
  Future<void> _loadZodiacData() async {
  if (mounted) {
  setState(() => _isLoading = true);
}

  try {
    final rows =
        await Supabase.instance.client.from('zodiac_signs').select('*');

    final List<Map<String, dynamic>> processed = rows.map((row) {
      final dates = _makeStartEnd(row, widget.year);
      return {
        "data": row,
        "start": dates["start"]!,
        "end": dates["end"]!,
      };
    }).toList();

    final DateTime now = DateTime.now();
    final DateTime monthStart =
        DateTime(widget.year, widget.month, 1);
    final DateTime monthEnd =
        DateTime(widget.year, widget.month + 1, 0);

    // 🔮 signo do dia
    for (final item in processed) {
      if (!item["start"].isAfter(now) &&
          !item["end"].isBefore(now)) {
        _todaySign = item["data"];
        break;
      }
    }

    // 📅 signo do início do mês
    for (final item in processed) {
      if (!item["start"].isAfter(monthStart) &&
          !item["end"].isBefore(monthStart)) {
        _startSign = item["data"];
        break;
      }
    }

    // 📅 signo do fim do mês
    for (final item in processed) {
      if (!item["start"].isAfter(monthEnd) &&
          !item["end"].isBefore(monthEnd)) {
        _endSign = item["data"];
        break;
      }
    }
  } catch (e) {
    debugPrint("Erro signos → $e");
  }

  if (mounted) {
    setState(() => _isLoading = false);
  }
}


  // --------------------------------------------------------
  // PERSONAL YEAR
  // --------------------------------------------------------
  int _calculatePersonalYear(DateTime birthDate, int year) {
    int sum(int n) =>
        n.toString().split('').fold(0, (a, b) => a + int.parse(b));
    int reduce(int n) {
     while (n > 9) {
  n = sum(n);
}
      return n;
    }

    return reduce(birthDate.day + birthDate.month + year);
  }

  Future<void> _openPersonalYearDialog() async {
  // 🌍 idioma (capturado antes de qualquer await)
  final bool isEN = context.locale.languageCode == "en";

  
 // 👤 usuário atual
final user = Supabase.instance.client.auth.currentUser;

if (user == null) {
  showLoginPrompt(context);
  return;
}

// 🧾 buscar perfil com data de nascimento
final profile = await Supabase.instance.client
    .from("profiles")
    .select("birth_date")
    .eq("id", user.id)
    .maybeSingle();


  if (!mounted) return;

  if (profile == null || profile["birth_date"] == null) {
    _showMissingBirthDateDialog();
    return;
  }

  // 🎂 data de nascimento
  final DateTime birthDate =
      DateTime.parse(profile["birth_date"]);

  // 🔢 calcular ano pessoal
  final int personalYear =
      _calculatePersonalYear(birthDate, widget.year);

  // 📘 buscar significado do ano pessoal
  final res = await Supabase.instance.client
      .from("personal_year_meanings")
      .select("*")
      .eq("number", personalYear)
      .maybeSingle();

  if (!mounted || res == null) return;

  // 🎨 cor do ano
  final Color parsedColor = Color(
    int.parse(res["color_hex"].replaceAll("#", "0xFF")),
  );

  // 🪄 abrir modal final
  _showPersonalYearModal(
    parsedColor: parsedColor,
    year: widget.year,
    personalYear: personalYear,
    title: isEN ? res["title_en"] : res["title_pt"],
    meaning: isEN ? res["meaning_en"] : res["meaning_pt"],
    colorName:
        isEN ? res["color_name_en"] : res["color_name_pt"],
  );
}

  // --------------------------------------------------------
  // UI HELPERS
  // --------------------------------------------------------
  Widget _buildPersonalYearButton() {
    return GestureDetector(
      onTap: _openPersonalYearDialog,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFBFA8E5),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          tr("zodiac.discover_personal_year_button"),
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _zodiacPageItem({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.85),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 28, color: const Color(0xFF8D63C3)),
            const SizedBox(height: 10),
            Text(label,
                style: GoogleFonts.poppins(
                    fontSize: 14, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(value,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontSize: 15)),
          ],
        ),
      ),
    );
  }

  Widget _zodiacCard(Map<String, dynamic> sign) {
    final isEN = context.locale.languageCode == 'en';

    return Container(
      margin: const EdgeInsets.only(bottom: 28),
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 26),
      decoration: BoxDecoration(
        color: const Color(0xFFF5DCEB).withOpacity(0.38),
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        children: [
          Text(sign['emoji'] ?? "⭐", style: const TextStyle(fontSize: 60)),
          const SizedBox(height: 12),
          Text(
            (isEN ? sign['signo_en'] : sign['signo_pt']).toUpperCase(),
            style: GoogleFonts.poppins(
                fontSize: 26, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(isEN ? sign['periodo_en'] : sign['periodo_pt']),
          const SizedBox(height: 18),
          Text(
            isEN ? sign['descricao_en'] : sign['descricao_pt'],
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 24),

          // 🔄 SWIPE
          SizedBox(
            height: 120,
            child: PageView(
              controller: PageController(viewportFraction: 0.85),
              children: [
                _zodiacPageItem(
                  label: "zodiac.color".tr(),
                  value: isEN ? sign['cor_en'] : sign['cor_pt'],
                  icon: Icons.palette,
                ),
                _zodiacPageItem(
                  label: "zodiac.number".tr(),
                  value: sign['numero'],
                  icon: Icons.filter_9_plus,
                ),
                _zodiacPageItem(
                  label: "zodiac.element".tr(),
                  value: isEN
                      ? sign['elemento_en']
                      : sign['elemento_pt'],
                  icon: Icons.local_fire_department,
                ),
                _zodiacPageItem(
                  label: "zodiac.stone".tr(),
                  value:
                      isEN ? sign['pedra_en'] : sign['pedra_pt'],
                  icon: Icons.diamond,
                ),
                _zodiacPageItem(
                  label: "zodiac.flower".tr(),
                  value:
                      isEN ? sign['flor_en'] : sign['flor_pt'],
                  icon: Icons.local_florist,
                ),
                _zodiacPageItem(
                  label: "zodiac.ruler".tr(),
                  value: isEN
                      ? sign['regente_en']
                      : sign['regente_pt'],
                  icon: Icons.public,
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          Text(
            "“${isEN ? sign['frase_en'] : sign['frase_pt']}”",
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

  // --------------------------------------------------------
  // DIALOGS
  // --------------------------------------------------------
  void _showMissingBirthDateDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(tr("zodiac.personal_year_no_birthdate_title")),
        content: Text(tr("zodiac.personal_year_no_birthdate_text")),
      ),
    );
  }


  // --------------------------------------------------------
  // BUILD
  // --------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return MonthPageTemplate(
      month: widget.month,
      year: widget.year,
      title: '',
      pageLabel: 'zodiac.title'.tr(),
      labelColor: const Color(0xFF8D63C3),
      description: 'zodiac.month_description'.tr(),
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (_todaySign != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Text(
                      "${'zodiac.today_sign'.tr()}: "
                      "${context.locale.languageCode == 'en' ? _todaySign!['signo_en'] : _todaySign!['signo_pt']}",
                      textAlign: TextAlign.center,
                    ),
                  ),
                if (_startSign != null) _zodiacCard(_startSign!),
                if (_endSign != null &&
                    _endSign!['id'] != _startSign?['id'])
                  _zodiacCard(_endSign!),
                const SizedBox(height: 30),
               _buildPersonalYearButton(),
              const SizedBox(height: 12),
Text(
  tr("zodiac.personal_year_helper"),
  textAlign: TextAlign.center,
  style: GoogleFonts.poppins(
    fontSize: 13,
    color: const Color(0xFF8D63C3).withOpacity(0.7),
  ),
),
const SizedBox(height: 40),
              ],
            ),
    );
  }
}
    