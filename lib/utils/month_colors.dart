import 'package:flutter/material.dart';

Color getMonthColor(int month) {
  const monthColors = [
    Color(0xFFe04cb7), // Janeiro
    Color.fromARGB(255, 175, 133, 203), // Fevereiro
    Color.fromARGB(255, 207, 135, 167), // Março
    Color.fromARGB(255, 151, 111, 208), // Abril
    Color.fromARGB(255, 240, 196, 74), // Maio
    Color(0xFFbeb6f2), // Junho
    Color(0xFF776fb5), // Julho
    Color.fromARGB(255, 240, 104, 160), // Agosto
    Color.fromARGB(255, 186, 119, 218), // Setembro
    Color(0xFFc48c00), // Outubro
    Color.fromARGB(255, 208, 37, 168), // Novembro
    Color(0xFF627fdd), // Dezembro
  ];
  return monthColors[month - 1];
}
