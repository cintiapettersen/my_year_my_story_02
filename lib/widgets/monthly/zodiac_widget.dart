import 'package:flutter/material.dart';
import 'package:my_year_my_story/widgets/shared/month_header.dart';
import 'package:my_year_my_story/widgets/monthly/zodiac_content.dart';

class ZodiacWidget extends StatelessWidget {
  final int? month;
  final int? year;

  const ZodiacWidget({
    super.key,
    this.month,
    this.year,
  });

  @override
  Widget build(BuildContext context) {
    final selectedMonth = month ?? DateTime.now().month;
    final selectedYear = year ?? DateTime.now().year;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MonthHeader(
            month: selectedMonth,
            year: selectedYear,
            title: 'Signos do Mês',
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: ZodiacContent(month: selectedMonth),
          ),
        ],
      ),
    );
  }
}
