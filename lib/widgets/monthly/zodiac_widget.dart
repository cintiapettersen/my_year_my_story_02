import 'package:flutter/material.dart';
import 'package:myyearmystory/widgets/shared/month_page_template.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:myyearmystory/screens/premium/premium_popup.dart';

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
  // PERSONAL YEAR CALCULATION (CORRIGIDO)
  // --------------------------------------------------------
  int _calculatePersonalYear(DateTime birthDate, int targetYear) {
    int sum(int n) =>
        n.toString().split('').fold(0, (a, b) => a + int.parse(b));

    int reduce(int n) {
      while (n > 9) n = sum(n);
      return n;
    }

    return reduce(birthDate.day + birthDate.month + targetYear);
  }

  // --------------------------------------------------------
  // RECONSTRUÇÃO DAS DATAS DOS SIGNOS
  // --------------------------------------------------------
  Map<String, DateTime> _makeStartEnd(
      Map<String, dynamic> row, int pageYear, int pageMonth) {
    final int sm = row['start_month'];
    final int sd = row['start_day'];
    final int em = row['end_month'];
    final int ed = row['end_day'];

    late DateTime start;
    late DateTime end;

    if (sm > em) {
      start = DateTime(pageYear - 1, sm, sd);
      end = DateTime(pageYear, em, ed);
    } else {
      start = DateTime(pageYear, sm, sd);
      end = DateTime(pageYear, em, ed);
    }

    return {"start": start, "end": end};
  }

  // --------------------------------------------------------
  // CARREGAR SIGNOS
  // --------------------------------------------------------
  Future<void> _loadZodiacData() async {
    setState(() => _isLoading = true);

    try {
      final supabase = Supabase.instance.client;
      final rows = await supabase.from('zodiac_signs').select('*');

      final processed = rows.map<Map<String, dynamic>>((row) {
        final dates = _makeStartEnd(row, widget.year, widget.month);
        return {
          "data": row,
          "start": dates["start"]!,
          "end": dates["end"]!,
        };
      }).toList();

      final now = DateTime.now();
      final monthStart = DateTime(widget.year, widget.month, 1);
      final monthEnd = DateTime(widget.year, widget.month + 1, 0);

      for (final item in processed) {
        if (!item["start"].isAfter(now) && !item["end"].isBefore(now)) {
          _todaySign = item["data"];
        }
        if (!item["start"].isAfter(monthStart) &&
            !item["end"].isBefore(monthStart)) {
          _startSign = item["data"];
        }
        if (!item["start"].isAfter(monthEnd) &&
            !item["end"].isBefore(monthEnd)) {
          _endSign = item["data"];
        }
      }

      setState(() {});
    } catch (e) {
      debugPrint("Erro signos → $e");
    }

    setState(() => _isLoading = false);
  }

  // --------------------------------------------------------
  // BOTÃO
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

  // --------------------------------------------------------
  // OPEN PERSONAL YEAR (CORRIGIDO)
  // --------------------------------------------------------
  Future<void> _openPersonalYearDialog() async {
    final DateTime freeUntil = DateTime(2026, 1, 20);
    final DateTime now = DateTime.now();

    final user = Supabase.instance.client.auth.currentUser;

    if (!now.isBefore(freeUntil)) {
      if (user == null) {
        _showLoginRequiredDialog();
        return;
      }
      showPremiumPopup(context);
      return;
    }

    if (user == null) {
      _showLoginRequiredDialog();
      return;
    }

    final profile = await Supabase.instance.client
        .from("profiles")
        .select("birth_date")
        .eq("id", user.id)
        .maybeSingle();

    if (profile == null || profile["birth_date"] == null) {
      _showMissingBirthDateDialog();
      return;
    }

    final birthDate = DateTime.parse(profile["birth_date"]);
    final personalYear = _calculatePersonalYear(birthDate, widget.year);

    final res = await Supabase.instance.client
        .from("personal_year_meanings")
        .select("*")
        .eq("number", personalYear)
        .maybeSingle();

    if (res == null) return;

    final bool isEN = context.locale.languageCode == "en";

    _showPersonalYearModal(
      parsedColor:
          Color(int.parse(res["color_hex"].replaceAll("#", "0xFF"))),
      year: widget.year,
      personalYear: personalYear,
      title: isEN ? res["title_en"] : res["title_pt"],
      meaning: isEN ? res["meaning_en"] : res["meaning_pt"],
      colorName: isEN ? res["color_name_en"] : res["color_name_pt"],
    );
  }

  // --------------------------------------------------------
  // MODAL FINAL
  // --------------------------------------------------------
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          tr("zodiac.personal_year_color_label"),
                          style: GoogleFonts.poppins(
                              fontSize: 15, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: parsedColor.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(8),
                            border:
                                Border.all(color: parsedColor, width: 1.5),
                          ),
                          child: Text(
                            colorName,
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
  // DIALOGS AUXILIARES
  // --------------------------------------------------------
  void _showMissingBirthDateDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(tr("zodiac.personal_year_no_birthdate_title")),
        content: Text(tr("zodiac.personal_year_no_birthdate_text")),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  void _showLoginRequiredDialog() {
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      backgroundColor: const Color(0xFFF5DCEB), // 🌸 fundo rosinha
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ❤️ coração
          Icon(
            Icons.favorite,
            color: const Color(0xFF8D63C3), // pode trocar pela cor do app
            size: 40,
          ),

          const SizedBox(height: 12),

          Text(
            tr("zodiac.login_required_title"),
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 10),

          Text(
            tr("zodiac.login_required_text"),
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: 14),
          ),
        ],
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            Navigator.pushNamed(context, '/login');
          },
          child: Text(
            tr("zodiac.login_required_button"),
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
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
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    final isEN = context.locale.languageCode == "en";

    return Column(
      children: [
        if (_todaySign != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Text(
              "${'zodiac.today_sign'.tr()}: "
              "${isEN ? _todaySign!['signo_en'] : _todaySign!['signo_pt']}",
            ),
          ),
        if (_startSign != null) _zodiacCard(_startSign!),
        if (_endSign != null && _endSign!['id'] != _startSign?['id'])
          _zodiacCard(_endSign!),
        const SizedBox(height: 30),
        _buildPersonalYearButton(),
      ],
    );
  }

  Widget _zodiacCard(Map<String, dynamic> sign) {
    final isEN = context.locale.languageCode == 'en';

    return Container(
      margin: const EdgeInsets.only(bottom: 28),
      padding: const EdgeInsets.all(26),
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
            style: GoogleFonts.poppins(fontSize: 26, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(isEN ? sign['periodo_en'] : sign['periodo_pt']),
          const SizedBox(height: 18),
          Text(
            isEN ? sign['descricao_en'] : sign['descricao_pt'],
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          Text(
            "“${isEN ? sign['frase_en'] : sign['frase_pt']}”",
            textAlign: TextAlign.center,
            style: GoogleFonts.satisfy(fontSize: 22),
          ),
        ],
      ),
    );
  }
}
