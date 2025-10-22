import 'package:flutter/material.dart';

class MonthCoverScreen extends StatelessWidget {
  final int monthIndex;
  final String lang;

  const MonthCoverScreen({
    super.key,
    required this.monthIndex,
    required this.lang,
  });

  @override
  Widget build(BuildContext context) {
    // Nome dos meses em português
    final monthsPt = [
      "Janeiro",
      "Fevereiro",
      "Março",
      "Abril",
      "Maio",
      "Junho",
      "Julho",
      "Agosto",
      "Setembro",
      "Outubro",
      "Novembro",
      "Dezembro"
    ];

    // Nome dos meses em inglês
    final monthsEn = [
      "January",
      "February",
      "March",
      "April",
      "May",
      "June",
      "July",
      "August",
      "September",
      "October",
      "November",
      "December"
    ];

    final monthName = lang == "pt" ? monthsPt[monthIndex] : monthsEn[monthIndex];

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "Bem-vindo ao mês de $monthName!",
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text("Voltar"),
          ),
        ],
      ),
    );
  }
  }
