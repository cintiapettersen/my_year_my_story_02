import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'dart:ui' as ui;
import 'package:my_year_my_story/utils/month_colors.dart'; // 🌈 cores mensais
import 'package:my_year_my_story/widgets/monthly/dailyluckpage.dart';

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
    // 📱 Detecta idioma automaticamente
    final lang = ui.PlatformDispatcher.instance.locale.languageCode;
    final locale = lang == 'pt' ? const Locale('pt') : const Locale('en');

    // 📅 Nome e data formatados conforme idioma
    final String monthName =
    DateFormat.MMMM(locale.languageCode).format(DateTime(year, month)).capitalize();
    final String formattedDate =
    DateFormat("d 'de' MMMM 'de' y", locale.languageCode).format(DateTime.now());

    // 🌈 Cor dinâmica do mês
    final Color bannerColor = getMonthColor(month);

    // 💕 Janeiro mantém texto rosa
    final Color textColor = (month == 1) ? const Color(0xFFE2377D) : Colors.black;

    // 🌸 Itens do menu com chaves de tradução
    final List<Map<String, dynamic>> menuItems = [
      {'title': 'month_menu.goals', 'icon': PhosphorIconsRegular.sparkle, 'color': const Color(0xFF679BD3)},
      {'title': 'month_menu.about_me', 'icon': PhosphorIconsRegular.userCircle, 'color': const Color(0xFFcf8ee8)},
      {'title': 'month_menu.quiz', 'icon': PhosphorIconsRegular.listChecks, 'color': const Color(0xFFE2377D)},
      {'title': 'month_menu.signs', 'icon': PhosphorIconsRegular.moonStars, 'color': const Color(0xFFe04cb7)},
      {'title': 'month_menu.tips', 'icon': PhosphorIconsRegular.flower, 'color': const Color(0xFFb71691)},
      {'title': 'month_menu.facts', 'icon': PhosphorIconsRegular.lightbulb, 'color': const Color(0xFFdbaf35)},
      {'title': 'month_menu.interview', 'icon': PhosphorIconsRegular.microphone, 'color': const Color(0xFF3983c6)},
      {'title': 'month_menu.lists', 'icon': PhosphorIconsRegular.star, 'color': const Color(0xFF776fb5)},
      {'title': 'month_menu.gratitude', 'icon': PhosphorIconsRegular.heart, 'color': const Color(0xFFE2377D)},
      {'title': 'month_menu.reflections', 'icon': PhosphorIconsRegular.quotes, 'color': const Color(0xFFb71691)},
      {'title': 'month_menu.photos', 'icon': PhosphorIconsRegular.camera, 'color': const Color(0xFFdbaf35)},
      {'title': 'month_menu.fortune', 'icon': PhosphorIconsRegular.clover, 'color': const Color(0xFF4DB6AC)},
    ];

    return Container(
      color: const Color(0xFFFFF7FA),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 8),

          // 🌸 Banner colorido
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
                    "$monthName $year",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formattedDate,
                    style: TextStyle(
                      fontSize: 14,
                      color: textColor.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),
          Center(
            child: Text(
              '✨ ${'month_menu.choose_section'.tr()}', // chave de tradução da frase principal
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF120D0D),
                height: 1.3,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 🟪 Grade dos botões
          Expanded(
            child: GridView.builder(
              itemCount: menuItems.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1,
              ),
              itemBuilder: (context, index) {
                final item = menuItems[index];
                return GestureDetector(
                  onTap: () {
                    final String titleKey = item['title'];

                    // 🍀 Abre a página "Sorte do Dia"
                    if (titleKey == 'month_menu.fortune') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const DailyLuckPage(),
                        ),
                      );
                    } else if (onNavigateToPage != null) {
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
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(item['icon'] as IconData, color: Colors.white, size: 36),
                        const SizedBox(height: 10),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Text(
                            (item['title'] as String).tr(),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
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
