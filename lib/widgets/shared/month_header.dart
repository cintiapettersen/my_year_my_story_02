import 'package:flutter/material.dart';
import '../../utils/month_colors.dart';


/// 🌸 Cabeçalho padronizado — mesmo estilo do MonthlyPageTemplate
class MonthHeader extends StatelessWidget {
  final int month;
  final int year;
  final String title;

  const MonthHeader({
    super.key,
    required this.month,
    required this.year,
    required this.title,
  });

  /// 🌈 Cores rotativas (iguais ao MonthlyPageTemplate)
  Color getBannerColor(int month) {
    const colors = [
      Color(0xFFD891BD), // Rosa lavanda
      Color(0xFFF7DCE0), // Rosa pálido
      Color(0xFFE91E63), // Rosa forte
      Color(0xFF7FA1D3), // Azul suave
      Color(0xFFE8C7DA), // Lilás rosado
      Color(0xFFEAB96C), // Amarelo quente
    ];
    return colors[(month - 1) % colors.length];
  }

  /// 🎨 Cor do texto conforme contraste
  Color getTextColor(Color backgroundColor) {
    final brightness = backgroundColor.computeLuminance();
    return brightness > 0.6 ? Colors.black87 : Colors.white;
  }

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
    final color = getMonthColor(month);
    final textColor = getTextColor(color);
    final monthName = getMonthName(month);

    return Container(
      width: double.infinity,
      color: color,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Column(
        children: [
          Text(
            '$monthName $year',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: textColor,
              letterSpacing: 1.2,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: textColor.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }
}
