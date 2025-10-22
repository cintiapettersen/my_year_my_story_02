import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:intl/intl.dart'; // 👈 pra formatar o nome do mês

// Imports dos widgets mensais
import 'package:my_year_my_story/widgets/monthly/monthly_goals_widget.dart';
import 'package:my_year_my_story/widgets/monthly/curiosities_widget.dart';
import 'package:my_year_my_story/widgets/monthly/interactive_quiz_widget.dart';
import 'package:my_year_my_story/widgets/monthly/zodiac_widget.dart';
import 'package:my_year_my_story/widgets/monthly/skills_development_widget.dart';
import 'package:my_year_my_story/widgets/monthly/did_you_know_widget.dart';
import 'package:my_year_my_story/widgets/monthly/interview_widget.dart';
import 'package:my_year_my_story/widgets/monthly/monthly_lists_widget.dart';
import 'package:my_year_my_story/widgets/monthly/gratitude_widget.dart';
import 'package:my_year_my_story/widgets/monthly/reflections_widget.dart';
import 'package:my_year_my_story/widgets/monthly/photo_gallery_widget.dart';

class MonthMenu extends StatelessWidget {
  final int month;
  final int year;
  final void Function(int index)? onNavigateToPage;

  const MonthMenu({
    super.key,
    required this.month,
    required this.year,
    this.onNavigateToPage,
  });

  @override
  Widget build(BuildContext context) {
    final player = AudioPlayer();
    final String monthName = DateFormat.MMMM('pt_BR').format(DateTime(year, month)).capitalize();

    final List<Map<String, dynamic>> menuItems = [
      {'title': 'Metas do Mês', 'icon': Icons.flag, 'color': const Color(0xFF679BD3)},
      {'title': 'Curiosidades sobre Mim', 'icon': Icons.person_outline, 'color': const Color(0xFFDDBFEF)},
      {'title': 'Quiz Interativo', 'icon': Icons.quiz_outlined, 'color': const Color(0xFFE2377D)},
      {'title': 'Signos do Mês', 'icon': Icons.star_border_rounded, 'color': const Color(0xFFEA7ACD)},
      {'title': 'Desenvolvendo Habilidades', 'icon': Icons.trending_up_rounded, 'color': const Color(0xFFCF8EE8)},
      {'title': 'Você Sabia?', 'icon': Icons.lightbulb_outline, 'color': const Color(0xFFD1C269)},
      {'title': 'Entrevista do Mês', 'icon': Icons.mic_none_rounded, 'color': const Color(0xFF679BD3)},
      {'title': 'Minhas Listas Favoritas', 'icon': Icons.list_alt_outlined, 'color': const Color(0xFFDDBFEF)},
      {'title': 'Página da Gratidão', 'icon': Icons.favorite_border_rounded, 'color': const Color(0xFFE2377D)},
      {'title': 'Reflexões Mensais', 'icon': Icons.auto_stories_outlined, 'color': const Color(0xFFEA7ACD)},
      {'title': 'Galeria de Fotos', 'icon': Icons.photo_library_outlined, 'color': const Color(0xFFCF8EE8)},
    ];

    return Container(
      color: const Color(0xFFFFF7FA),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🌸 Banner com o mês atual
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              color: const Color(0xFFA3BE8C), // verdinho suave
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Text(
                  monthName,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Escolha uma página do mês',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          const Text(
            '✨ Por qual sessão do mês você quer passar hoje?',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF4F4F4F),
            ),
          ),
          const SizedBox(height: 20),

          // 🟢 Grade dos botões
          Expanded(
            child: GridView.builder(
              itemCount: menuItems.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1,
              ),
              itemBuilder: (context, index) {
                final item = menuItems[index];
                return GestureDetector(
                  onTap: () async {
                    await player.play(AssetSource('sounds/click.mp3'));
                    if (onNavigateToPage != null) {
                      onNavigateToPage!(index + 1);
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: item['color'] as Color,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(item['icon'] as IconData, color: Colors.white, size: 36),
                        const SizedBox(height: 10),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Text(
                            item['title'] as String,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// 🔤 Helper para capitalizar o nome do mês (ex: "outubro" → "Outubro")
extension StringCasing on String {
  String capitalize() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1);
  }
}
