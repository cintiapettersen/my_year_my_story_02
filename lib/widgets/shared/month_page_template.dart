import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:my_year_my_story/widgets/shared/app_bottom_menu.dart';
import 'package:my_year_my_story/widgets/shared/month_header.dart';

/// 🌸 Template base para as páginas mensais do app
class MonthPageTemplate extends StatefulWidget {
  final int month;
  final int year;
  final String title;
  final String? description; // 👈 agora o parâmetro existe
  final Widget child;

  const MonthPageTemplate({
    super.key,
    required this.month,
    required this.year,
    required this.title,
    this.description, // 👈 adicionado corretamente
    required this.child,
  });

  @override
  State<MonthPageTemplate> createState() => _MonthPageTemplateState();
}

class _MonthPageTemplateState extends State<MonthPageTemplate> {
  final AudioPlayer _player = AudioPlayer();

  Future<void> _playClick() async {
    try {
      await _player.play(AssetSource('sounds/click.mp3'));
    } catch (e) {
      debugPrint('Erro ao tocar som: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasScaffold = Scaffold.maybeOf(context) != null;

    final content = SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              MonthHeader(
                month: widget.month,
                year: widget.year,
                title: widget.title,
              ),
              if (widget.description != null) // 👈 exibe só se tiver texto
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
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
              Padding(
                padding: const EdgeInsets.all(16),
                child: GestureDetector(
                  onTapDown: (_) => _playClick(),
                  behavior: HitTestBehavior.translucent,
                  child: widget.child,
                ),
              ),
            ],
          ),
        ),
      ),
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
      body: content,
      bottomNavigationBar: const AppBottomMenu(currentIndex: 1),
    );
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}
