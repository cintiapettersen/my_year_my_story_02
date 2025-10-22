import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_year_my_story/widgets/monthly/interactive_quiz_widget.dart';

extension StringCasingExtension on String {
  String capitalize() =>
      isNotEmpty ? '${this[0].toUpperCase()}${substring(1)}' : this;
}

class InteractiveQuizScreen extends StatelessWidget {
  final int month;
  final int year;

  const InteractiveQuizScreen({
    Key? key,
    required this.month,
    required this.year,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final String monthName =
    DateFormat.MMMM('pt_BR').format(DateTime(0, month)).capitalize();

    return Scaffold(
      backgroundColor: const Color(0xFFFFFBFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.8,
        centerTitle: true,
        iconTheme: const IconThemeData(
          color: Color(0xFFE18B50),
        ),
        title: Text(
          'Quiz de $monthName 💕',
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Color(0xFF4F4F4F),
          ),
        ),
      ),
      body: SafeArea(
        child: InteractiveQuizWidget(
          month: month,
          year: year,
          monthName: monthName, // 🌸 adicionado aqui
        ),
      ),
    );
  }

}
