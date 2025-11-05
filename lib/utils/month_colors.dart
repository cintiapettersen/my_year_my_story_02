import 'package:flutter/material.dart';

Color getMonthColor(int month) {
  const monthColors = [
    Color(0xFFfcdde8), // Janeiro
    Color(0xFFe04cb7), // Fevereiro
    Color(0xFFdbaf35), // Março
    Color(0xFF679bd3), // Abril
    Color(0xFFcf8ee8), // Maio
    Color(0xFFbeb6f2), // Junho
    Color(0xFF776fb5), // Julho
    Color(0xFFd83d78), // Agosto
    Color(0xFFb71691), // Setembro
    Color(0xFFc48c00), // Outubro
    Color(0xFF3983c6), // Novembro
    Color(0xFF9a5dba), // Dezembro
  ];
  return monthColors[month - 1];
}
