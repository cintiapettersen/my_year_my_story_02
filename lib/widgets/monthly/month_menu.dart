import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:myyearmystory/utils/month_colors.dart';


class MonthMenu extends StatelessWidget {
  final int month;
  final int year;
  final void Function(int index)? onNavigateToPage;

  const MonthMenu({
    super.key,
    required this.month,
    required this.year,
    this.onNavigateToPage,
  });

  @override
  Widget build(BuildContext context) {
    // 📐 Responsividade base
    final double screenWidth = MediaQuery.of(context).size.width;

    final double gridIconSize =
        (screenWidth * 0.070).clamp(26, 42);

    final double gridTextSize =
        (screenWidth * 0.027).clamp(11, 14);

    final double subtitleSize =
        (screenWidth * 0.032).clamp(13, 16);

    final double sectionTitleSize =
        (screenWidth * 0.036).clamp(15, 18);

    // 🌎 Detecta o idioma atual via EasyLocalization
    final locale = context.locale.languageCode;

    // 🗓 Nome do mês via JSON
    final String monthName = "months.$month".tr();

    // 📅 Data formatada
    final String formattedDate = locale == "pt"
        ? DateFormat("d 'de' MMMM 'de' y", "pt_BR")
            .format(DateTime.now())
        : DateFormat("MMMM d, y", "en_US")
            .format(DateTime.now());

    // 🌈 Cor dinâmica do mês
    final Color bannerColor = getMonthColor(month);

    // 💕 Janeiro mantém texto rosa
    final Color textColor =
        (month == 1) ? const Color(0xFFE2377D) : Colors.black;

    // 🌸 Itens do menu
    final List<Map<String, dynamic>> menuItems = [
      {'title': 'month_menu.goals', 'icon': PhosphorIconsRegular.target, 'color': const Color(0xFFe04cb7)},
      {'title': 'month_menu.about_me', 'icon': PhosphorIconsRegular.userCircle, 'color': const Color(0xFFc79fe2)},
      {'title': 'month_menu.between_lines', 'icon': PhosphorIconsRegular.notebook, 'color': const Color(0xFFE25BA6)},
      {'title': 'month_menu.quiz', 'icon': PhosphorIconsRegular.star, 'color': const Color.fromARGB(255, 221, 156, 183)},
      {'title': 'month_menu.signs', 'icon': PhosphorIconsRegular.moonStars, 'color': const Color(0xFF7654a3)},
      {'title': 'month_menu.tips', 'icon': PhosphorIconsRegular.flower, 'color': const Color(0xFFb539bc)},
      {'title': 'month_menu.facts', 'icon': PhosphorIconsRegular.lightbulb, 'color': const Color(0xFFdbaf35)},
      {'title': 'month_menu.interview', 'icon': PhosphorIconsRegular.microphone, 'color': const Color(0xFF7382D7)},
      {'title': 'month_menu.lists', 'icon': PhosphorIconsRegular.listChecks, 'color': const Color(0xFF776fb5)},
      {'title': 'month_menu.photos', 'icon': PhosphorIconsRegular.camera, 'color': const Color(0xFFb71691)},
      {'title': 'month_menu.dates', 'icon': PhosphorIconsRegular.calendarDots, 'color': const Color(0xFFbeb6f2)},
      {'title': 'month_menu.literary_quotes', 'icon': PhosphorIconsRegular.bookOpen, 'color': const Color(0xFF9A5DBA)},
      {'title': 'month_menu.time_capsule', 'icon': Icons.hourglass_bottom_rounded, 'color': const Color(0xFF679bd3)},
      {'title': 'month_menu.gratitude', 'icon': PhosphorIconsRegular.heart, 'color': const Color(0xFFE2377D)},
      {'title': 'month_menu.reflections', 'icon': PhosphorIconsRegular.quotes, 'color': const Color(0xFFcf78f7)},
    ];

    return Container(
      color: const Color(0xFFFFF7FA),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 8),

          // 🌸 Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: bannerColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [

                  Text(
  "$monthName $year".toLowerCase(),
  style: GoogleFonts.cinzelDecorative(

    fontSize: 20,
    
    fontWeight: FontWeight.w600,
    color: textColor,
    letterSpacing: 0.5,
  ),
  textAlign: TextAlign.center,
),

const SizedBox(height: 4),

Text(
  formattedDate,
  style: GoogleFonts.poppins(
    fontSize: subtitleSize,
    fontWeight: FontWeight.normal,
    color: textColor.withAlpha(204), // equivalente a 0.8
    letterSpacing: 1.0,
  ),
  textAlign: TextAlign.center,
),

                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          Center(
            child: Text(
              '✨ ${'month_menu.choose_section'.tr()}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: sectionTitleSize,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF120D0D),
                height: 1.3,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 🟪 Grid
          Expanded(
            child: GridView.builder(
              itemCount: menuItems.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 14,
                crossAxisSpacing: 12,
                childAspectRatio: 1.0,
              ),
              itemBuilder: (context, index) {
                final item = menuItems[index];

                return GestureDetector(
                  onTap: () {
                    if (onNavigateToPage != null) {
                      onNavigateToPage!(index + 1);
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: item['color'] as Color,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.10),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            item['icon'] as IconData,
                            size: gridIconSize,
                            color: Colors.white,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            (item['title'] as String).tr(),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: gridTextSize,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              height: 1.15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// 🔤 Capitaliza o nome do mês
extension StringCasing on String {
  String capitalize() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1);
  }
}
