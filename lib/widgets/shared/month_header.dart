import 'package:flutter/material.dart';
import '../../utils/month_colors.dart';
import 'package:easy_localization/easy_localization.dart';

class MonthHeader extends StatelessWidget {
  final int month;
  final int year;
  final String? title;
  final String? pageLabel;
  final Color? labelColor;

  const MonthHeader({
    super.key,
    required this.month,
    required this.year,
    this.title,
    this.pageLabel,
    this.labelColor,
  });

  /// Traduz os meses
  String getMonthName(int month) {
    // Usa as chaves existentes no JSON ("month.*") para evitar avisos de chave ausente
    const months = [
      'month.january',
      'month.february',
      'month.march',
      'month.april',
      'month.may',
      'month.june',
      'month.july',
      'month.august',
      'month.september',
      'month.october',
      'month.november',
      'month.december'
    ];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    final bannerColor = getMonthColor(month);
    final monthKey = getMonthName(month);
    final translated = monthKey.tr();
    final monthName = translated[0].toUpperCase() + translated.substring(1).toLowerCase();

    final monthShort =
        monthName.length >= 3 ? '${monthName.substring(0, 3)}.' : monthName;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 18),
      decoration: BoxDecoration(
        color: bannerColor,
        borderRadius: BorderRadius.zero,
      ),

      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [


  /// 🎀 Etiqueta fixa (páginas do mês)
          if (pageLabel != null && pageLabel!.trim().isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              decoration: BoxDecoration(
                color: labelColor ?? const Color(0xFFEDE3FF),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                pageLabel!,
                style: const TextStyle(
                  fontFamily: 'Cinzel',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.0,
                ),
              ),
            ),

          if (pageLabel != null && pageLabel!.trim().isNotEmpty)
            const SizedBox(height: 6),



          /// 📅 Mês + ano
          Text(
            "$monthShort $year",
            style: const TextStyle(
              fontFamily: 'Cinzel',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 0.9,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),

        
          /// ✨ Título alternativo
          if ((pageLabel == null || pageLabel!.trim().isEmpty) &&
              title != null &&
              title!.trim().isNotEmpty)
            Text(
              title!,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Colors.white.withOpacity(0.95),
              ),
              textAlign: TextAlign.center,
            ),
        ],
      ),
    );
  }
}
