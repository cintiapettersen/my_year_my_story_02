import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:easy_localization/easy_localization.dart';

import 'package:myyearmystory/widgets/monthly/interactive_quiz_widget.dart';
import 'package:myyearmystory/widgets/shared/month_page_template.dart';

class InteractiveQuizStandalone extends StatelessWidget {
  final int month;
  final int year;

  const InteractiveQuizStandalone({
    super.key,
    required this.month,
    required this.year,
  });

  @override
  Widget build(BuildContext context) {
    final String monthName = DateFormat.MMMM('pt_BR')
        .format(DateTime(0, month))
        .capitalize();

    return MonthPageTemplate(
      month: month,
      year: year,
      title: "",
      pageLabel: "month_menu.quiz".tr(),
      labelColor: const Color(0xFFFDD97B7),
      description: "quiz.description".tr(),
      useScaffoldContainer: true,
      child: MonthlyQuizWidget(
        month: month,
        year: year,
      ),
    );
  }
}

// mantém porque o screen usa .capitalize()
extension StringCasingExt on String {
  String capitalize() =>
      isEmpty ? this : "${this[0].toUpperCase()}${substring(1)}";
}
