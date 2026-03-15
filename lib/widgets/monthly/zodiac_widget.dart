import 'package:flutter/material.dart';
import 'package:myyearmystory/widgets/shared/month_page_template.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:myyearmystory/utils/month_colors.dart';
import 'package:myyearmystory/widgets/shared/app_pill_button.dart';

import 'package:myyearmystory/screens/popups/popup_login.dart';

import 'package:myyearmystory/widgets/shared/remote_data_wrapper.dart';




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
  
bool _isLoading = true;
bool _hasError = false;

  final List<Color> _zodiacAccentColors = const [
    Color(0xFF7FA9D1),
    Color(0xFFD7C3EE),
    Color(0xFFD84A75),
    Color(0xFFE78AC6),
    Color(0xFFCBA5E3),
    Color(0xFFD8CA7D),
  ];


 bool get isGuest {
  return Supabase.instance.client.auth.currentUser == null;
}



  Map<String, dynamic>? _todaySign;
  Map<String, dynamic>? _startSign;
  Map<String, dynamic>? _endSign;

  @override
  void initState() {
    super.initState();
    _initializePage();
   

  }

  Future<void> _initializePage() async {
  try {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    await _loadZodiacData();
  } catch (e) {
    _hasError = true;
    
  } finally {
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }
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
  final monthAccent = getMonthColor(widget.month);
  final accent =
      _zodiacAccentColors[personalYear.abs() % _zodiacAccentColors.length];

  showDialog(
    context: context,
    builder: (_) => Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 26, vertical: 40),
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  monthAccent.withValues(alpha: 0.22),
                  accent.withValues(alpha: 0.22),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 30,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: accent.withValues(alpha: 0.18),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Text(
                        year.toString(),
                        style: GoogleFonts.sacramento(
                          fontSize: 40,
                          color: monthAccent.withValues(alpha: 0.90),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        tr("zodiac.personal_year_title"),
                        style: GoogleFonts.satisfy(
                          fontSize: 22,
                          color: Colors.black.withValues(alpha: 0.75),
                        ),
                      ),
                      const SizedBox(height: 22),
                      Container(
                        width: 130,
                        height: 130,
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.18),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            "$personalYear",
                            style: GoogleFonts.poppins(
                              fontSize: 48,
                              fontWeight: FontWeight.w700,
                              color: accent.withValues(alpha: 0.92),
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
                          fontWeight: FontWeight.w700,
                          color: accent.withValues(alpha: 0.92),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        meaning,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          height: 1.45,
                          color: Colors.black.withValues(alpha: 0.78),
                        ),
                      ),
                      const SizedBox(height: 26),
                      Column(
                        children: [
                          Text(
                            tr("zodiac.personal_year_color_label"),
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.black.withValues(alpha: 0.80),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8EDF2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: accent.withValues(alpha: 0.35),
                                width: 1.2,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 14,
                                  height: 14,
                                  decoration: BoxDecoration(
                                    color: parsedColor,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color:
                                            Colors.black.withValues(alpha: 0.12),
                                        blurRadius: 6,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Flexible(
                                  child: Text(
                                    colorName,
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color:
                                          Colors.black.withValues(alpha: 0.75),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            right: 10,
            top: 10,
            child: InkResponse(
              onTap: () => Navigator.pop(context),
              radius: 22,
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.90),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.10),
                      blurRadius: 10,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.close,
                  color: Colors.black.withValues(alpha: 0.70),
                ),
              ),
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
  final rows = await Supabase.instance.client
      .from('zodiac_signs')
      .select('*');

  final List<Map<String, dynamic>> processed = rows.map((row) {
    final dates = _makeStartEnd(row, widget.year);
    return {
      "data": row,
      "start": dates["start"]!,
      "end": dates["end"]!,
    };
  }).toList();

  final DateTime now = DateTime.now();
  final DateTime monthStart = DateTime(widget.year, widget.month, 1);
  final DateTime monthEnd = DateTime(widget.year, widget.month + 1, 0);

  for (final item in processed) {
    if (!item["start"].isAfter(now) && !item["end"].isBefore(now)) {
      _todaySign = item["data"];
      break;
    }
  }

  for (final item in processed) {
    if (!item["start"].isAfter(monthStart) &&
        !item["end"].isBefore(monthStart)) {
      _startSign = item["data"];
      break;
    }
  }

  for (final item in processed) {
    if (!item["start"].isAfter(monthEnd) &&
        !item["end"].isBefore(monthEnd)) {
      _endSign = item["data"];
      break;
    }
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
    final monthAccent = getMonthColor(widget.month);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: AppPillButton(
          expand: true,
          text: tr("zodiac.discover_personal_year_button"),
          onPressed: _openPersonalYearDialog,
          backgroundColor: monthAccent,
          textStyle: GoogleFonts.poppins(
            fontSize: 16,
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
    final monthAccent = getMonthColor(widget.month);
    final idHash = (sign['id']?.toString() ?? (sign['signo_pt'] ?? 'z')).hashCode;
    final accent = _zodiacAccentColors[idHash.abs() % _zodiacAccentColors.length];

    final descriptionStyle = GoogleFonts.robotoSerif(
      fontSize: 14,
      height: 1.55,
      color: Colors.black.withValues(alpha: 0.82),
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 28),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            monthAccent.withValues(alpha: 0.22),
            accent.withValues(alpha: 0.22),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 26,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(22, 22, 22, 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: accent.withValues(alpha: 0.25),
          ),
        ),
        child: Column(
          children: [
            Text(
              sign['emoji'] ?? "⭐",
              style: const TextStyle(fontSize: 60),
            ),
            const SizedBox(height: 12),
            Text(
              (isEN ? sign['signo_en'] : sign['signo_pt']).toUpperCase(),
              style: GoogleFonts.poppins(
                fontSize: 26,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isEN ? sign['periodo_en'] : sign['periodo_pt'],
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.black.withValues(alpha: 0.55),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            Text(
              isEN ? sign['descricao_en'] : sign['descricao_pt'],
              textAlign: TextAlign.center,
              style: descriptionStyle,
            ),
            const SizedBox(height: 24),

            // 🔄 SWIPE
            _ZodiacInfoCarousel(
              pages: [
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
                  value: isEN ? sign['elemento_en'] : sign['elemento_pt'],
                  icon: Icons.local_fire_department,
                ),
                _zodiacPageItem(
                  label: "zodiac.stone".tr(),
                  value: isEN ? sign['pedra_en'] : sign['pedra_pt'],
                  icon: Icons.diamond,
                ),
                _zodiacPageItem(
                  label: "zodiac.flower".tr(),
                  value: isEN ? sign['flor_en'] : sign['flor_pt'],
                  icon: Icons.local_florist,
                ),
                _zodiacPageItem(
                  label: "zodiac.ruler".tr(),
                  value: isEN ? sign['regente_en'] : sign['regente_pt'],
                  icon: Icons.public,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              isEN ? "Swipe for more" : "Arraste para ver mais",
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.black.withValues(alpha: 0.45),
              ),
            ),

            const SizedBox(height: 28),

            Text(
              "“${isEN ? sign['frase_en'] : sign['frase_pt']}”",
              textAlign: TextAlign.center,
              style: descriptionStyle.copyWith(
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF554587).withValues(alpha: 0.90),
              ),
            ),
          ],
        ),
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
    child: RemoteDataWrapper(
      isLoading: _isLoading,
      hasError: _hasError,
      onRetry: _initializePage,
      child: Column(
        children: [
          if (_todaySign != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Text(
                "${'zodiac.today_sign'.tr()}: "
                "${context.locale.languageCode == 'en'
                    ? _todaySign!['signo_en']
                    : _todaySign!['signo_pt']}",
                textAlign: TextAlign.center,
              ),
            ),

          if (_startSign != null) _zodiacCard(_startSign!),

          if (_endSign != null && _endSign!['id'] != _startSign?['id'])
            _zodiacCard(_endSign!),

          const SizedBox(height: 30),

          _buildPersonalYearButton(),

          const SizedBox(height: 12),

          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: Text(
                tr("zodiac.personal_year_helper"),
                textAlign: TextAlign.center,
                maxLines: 2,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  height: 1.35,
                  color: Colors.black87,
                ),
              ),
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    ),
  );
}
}

class _ZodiacInfoCarousel extends StatefulWidget {
  final List<Widget> pages;

  const _ZodiacInfoCarousel({
    required this.pages,
  });

  @override
  State<_ZodiacInfoCarousel> createState() => _ZodiacInfoCarouselState();
}

class _ZodiacInfoCarouselState extends State<_ZodiacInfoCarousel> {
  late final PageController _controller;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController(viewportFraction: 0.84);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _previous() async {
    if (_index <= 0) return;
    await _controller.previousPage(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _next() async {
    if (_index >= widget.pages.length - 1) return;
    await _controller.nextPage(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final canGoBack = _index > 0;
    final canGoNext = _index < widget.pages.length - 1;

    return SizedBox(
      height: 132,
      child: Stack(
        children: [
          PageView(
            controller: _controller,
            physics: const BouncingScrollPhysics(),
            onPageChanged: (i) => setState(() => _index = i),
            children: widget.pages,
          ),
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: Center(
              child: IconButton(
                onPressed: canGoBack ? _previous : null,
                icon: Icon(
                  Icons.chevron_left_rounded,
                  size: 30,
                  color: Colors.black.withValues(
                    alpha: canGoBack ? 0.30 : 0.10,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            child: Center(
              child: IconButton(
                onPressed: canGoNext ? _next : null,
                icon: Icon(
                  Icons.chevron_right_rounded,
                  size: 30,
                  color: Colors.black.withValues(
                    alpha: canGoNext ? 0.30 : 0.10,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
