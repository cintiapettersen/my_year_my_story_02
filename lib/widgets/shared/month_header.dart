import 'package:flutter/material.dart';
import '../../utils/month_colors.dart';

/// 🌸 Cabeçalho padronizado do app
/// Agora suporta etiqueta fixa dentro do banner 💕
class MonthHeader extends StatelessWidget {
  final int month;
  final int year;

  /// 🔸 "title" só aparece se NÃO tiver etiqueta
  final String? title;

  /// ⭐ Nome da etiqueta (ex: "Metas", "Quiz Interativo", "Meu Momento")
  final String? pageLabel;

  /// ⭐ Cor fixa da etiqueta (não depende do mês!)
  final Color? labelColor;

  const MonthHeader({
    super.key,
    required this.month,
    required this.year,
    this.title,
    this.pageLabel,
    this.labelColor,
  });

  /// 📅 Nome dos meses
  String getMonthName(int month) {
    const months = [
      'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
      'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro'
    ];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    final bannerColor = getMonthColor(month);
    final monthName = getMonthName(month);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(color: bannerColor),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          /// 📅 Mês + ano
          Text(
            '$monthName $year',
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 1.2,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 6),

          /// 🎀 ETIQUETA – se existir
          if (pageLabel != null && pageLabel!.trim().isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: labelColor ?? const Color(0xFFEDE3FF), // 💗 SEM OPACIDADE
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                pageLabel!,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white, // sempre branco
                  letterSpacing: 0.3,
                ),
              ),
            ),

          if (pageLabel != null && pageLabel!.trim().isNotEmpty)
            const SizedBox(height: 6),

          /// ✨ Título — só aparece se NÃO houver etiqueta
          if ((pageLabel == null || pageLabel!.trim().isEmpty) &&
              title != null &&
              title!.trim().isNotEmpty)
            Text(
              title!,
              style: TextStyle(
                fontSize: 16,
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
