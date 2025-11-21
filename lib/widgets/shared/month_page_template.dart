import 'package:flutter/material.dart';
import 'package:myyearmystory/widgets/shared/app_bottom_menu.dart';
import 'package:myyearmystory/widgets/shared/month_header.dart';

class MonthPageTemplate extends StatefulWidget {
  final int month;
  final int year;
  final String title;
  final String? description;

  final String? pageLabel;
  final Color? labelColor;

  final bool useScaffoldContainer;
  final Widget child;

  const MonthPageTemplate({
    super.key,
    required this.month,
    required this.year,
    required this.title,
    this.description,
    this.pageLabel,
    this.labelColor,
    this.useScaffoldContainer = true,
    required this.child,
  });

  @override
  State<MonthPageTemplate> createState() => _MonthPageTemplateState();
}

class _MonthPageTemplateState extends State<MonthPageTemplate> {
  Future<void> _playClick() async {
    try {} catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final hasScaffold = Scaffold.maybeOf(context) != null;

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
        widget.labelColor ?? labelColors[widget.pageLabel] ?? Colors.black26;

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MonthHeader(
          month: widget.month,
          year: widget.year,
          title: widget.title,
          pageLabel: widget.pageLabel,
          labelColor: resolvedLabelColor,
        ),

        const SizedBox(height: 8),

        if (widget.description != null && widget.description!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
            child: Column(
              children: [
                Text(
                  widget.description!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.black54,
                    fontStyle: FontStyle.italic,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  height: 1,
                  color: Color(0xFFE9B9C9),
                  margin: EdgeInsets.symmetric(horizontal: 12),
                ),
              ],
            ),
          ),

        /// 🌸 ÁREA LIVRE AMPLIADA
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
            child: GestureDetector(
              onTapDown: (_) => _playClick(),
              behavior: HitTestBehavior.translucent,
              child: widget.child,
            ),
          ),
        ),
      ],
    );

    if (hasScaffold || !widget.useScaffoldContainer) {
      return content;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFFF7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFE2377D),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'My Year, My Story',
          style: TextStyle(
            fontFamily: 'Cinzel',
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 1.2,
          ),
        ),
      ),
      body: SafeArea(
        child: Container(
          margin: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 6,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: content,
        ),
      ),
      bottomNavigationBar: const AppBottomMenu(currentIndex: 1),
    );
  }
}
