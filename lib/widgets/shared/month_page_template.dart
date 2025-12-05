import 'package:flutter/material.dart';
import 'package:myyearmystory/widgets/shared/month_header.dart';
import 'package:myyearmystory/widgets/shared/app_bottom_menu.dart';

class MonthPageTemplate extends StatelessWidget {
  final int month;
  final int year;
  final String title;
  final String? description;

  final String? pageLabel;
  final Color? labelColor;

  final Widget child;

  const MonthPageTemplate({
    super.key,
    required this.month,
    required this.year,
    required this.title,
    this.description,
    this.pageLabel,
    this.labelColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final Map<String, Color> labelColors = {
      'Metas do Mês': Color.fromARGB(255, 227, 62, 123),
      'Sobre Mim': Color.fromARGB(255, 189, 134, 212),
      'Quiz Interativo': Color.fromARGB(255, 207, 148, 168),
      'Signos do Mês': Color.fromARGB(255, 145, 102, 189),
      'Dicas do Mês': Color(0xFFA8C5DB),
      'Entrevista': Color(0xFFE9B9C9),
      'Minhas Listas': Color(0xFFE18B50),
      'Página da Gratidão': Color.fromARGB(255, 129, 174, 230),
      'Reflexões': Color(0xFFC03B66),
      'Fotos do Mês': Color(0xFFA07756),
      'Sorte do Dia': Color(0xFF9CBC68),
    };

    final Color resolvedLabelColor =
        labelColor ?? labelColors[pageLabel] ?? Colors.black26;

    // 🔥 DETECTA SE ESTÁ DENTRO DO CARD DO MÊS (PageView)
    final bool insideAnotherScaffold = Scaffold.maybeOf(context) != null;

    // -------------------------------------------------------------
    // 🌸 CENÁRIO 1 — Página dentro do fluxo mensal (CARD)
    // -------------------------------------------------------------
    if (insideAnotherScaffold) {
      return Card(
  margin: EdgeInsets.zero,
  elevation: 4,
  color: Colors.white, // ← 🌟 FUNDO BRANCO AQUI!
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(20),
  ),
        child: Column(
          children: [
            // 🔥 Banner agora DENTRO do card
            MonthHeader(
              month: month,
              year: year,
              title: title,
              pageLabel: pageLabel,
              labelColor: resolvedLabelColor,
            ),

            // 🔥 Conteúdo rolável
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(10, 12, 10, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (description != null && description!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
                        child: Column(
                          children: [
                            Text(
                              description!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black54,
                                fontStyle: FontStyle.italic,
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              height: 1,
                              color: Color(0xFFE9B9C9),
                            ),
                          ],
                        ),
                      ),

                    child,
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    // -------------------------------------------------------------
    // 🌸 CENÁRIO 2 — Página aberta sozinha (via dashboard)
    // -------------------------------------------------------------
    return Scaffold(
      backgroundColor: const Color(0xFFFFF7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFE2377D),
        elevation: 0,
        centerTitle: true,
        title: Text(
          title.isEmpty ? (pageLabel ?? '') : title,
          style: const TextStyle(
            fontFamily: 'Cinzel',
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 1.1,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 40),
          child: Column(
            children: [
              MonthHeader(
                month: month,
                year: year,
                title: title,
                pageLabel: pageLabel,
                labelColor: resolvedLabelColor,
              ),
              const SizedBox(height: 12),
              child,
            ],
          ),
        ),
      ),
      bottomNavigationBar: AppBottomMenu(currentIndex: 1),
    );
  }
}
