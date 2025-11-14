import 'package:flutter/material.dart';
import 'package:myyearmystory/widgets/shared/app_bottom_menu.dart';
import 'package:myyearmystory/widgets/shared/month_header.dart';

/// 🌸 Template base para as páginas mensais do app
class MonthPageTemplate extends StatefulWidget {
  final int month;
  final int year;
  final String title;
  final String? description; // 👈 descrição opcional
  final Widget child;

  const MonthPageTemplate({
    super.key,
    required this.month,
    required this.year,
    required this.title,
    this.description,
    required this.child,
  });

  @override
  State<MonthPageTemplate> createState() => _MonthPageTemplateState();
}

class _MonthPageTemplateState extends State<MonthPageTemplate> {
  Future<void> _playClick() async {
    try {
      //await _player.play(AssetSource('sounds/click.mp3'));
    } catch (e) {
      debugPrint('Erro ao tocar som: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasScaffold = Scaffold.maybeOf(context) != null;

    final content = Column(
      children: [
        // Cabeçalho do mês
        MonthHeader(
          month: widget.month,
          year: widget.year,
          title: widget.title,
        ),

        // Descrição (fica fora do scroll do conteúdo principal)
        if (widget.description != null && widget.description!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
            child: Text(
              widget.description!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                color: Colors.black54,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),

        // Conteúdo rolável (para evitar conflitos com ListView ou Column interno)
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: GestureDetector(
              onTapDown: (_) => _playClick(),
              behavior: HitTestBehavior.translucent,
              child: widget.child,
            ),
          ),
        ),
      ],
    );

    if (hasScaffold) return content;

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
          margin: const EdgeInsets.all(16),
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

  @override
  void dispose() {
    //_player.dispose();
    super.dispose();
  }
}
