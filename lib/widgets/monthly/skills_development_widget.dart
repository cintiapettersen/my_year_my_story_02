import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:math';
import 'package:my_year_my_story/widgets/monthly/monthly_page_template.dart';
import 'package:my_year_my_story/utils/month_colors.dart';

class SkillsDevelopmentWidget extends StatefulWidget {
  final int month;
  final int year;

  const SkillsDevelopmentWidget({
    super.key,
    required this.month,
    required this.year,
  });

  @override
  State<SkillsDevelopmentWidget> createState() =>
      _SkillsDevelopmentWidgetState();
}

class _SkillsDevelopmentWidgetState extends State<SkillsDevelopmentWidget>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final supabase = Supabase.instance.client;
  final player = AudioPlayer();

  List<Map<String, dynamic>> skills = [];
  bool isLoading = true;
  int refreshCount = 0;
  Color currentButtonColor = const Color(0xFFE2377D);
  bool isPressed = false;

  // 🌈 Paleta vibrante
  final Map<String, Color> categoryColors = {
    'inspiração': const Color(0xFF679BD3),
    'astronomia': const Color(0xFFDDBFEF),
    'ciência': const Color(0xFFE2377D),
    'universo': const Color(0xFFEA7ACD),
    'organização': const Color(0xFFCF8EE8),
    'autoconhecimento': const Color(0xFFD1C269),
    'saúde': const Color(0xFF9CBC68),
    'espiritualidade': const Color(0xFFF0D4B8),
    'gratidão': const Color(0xFFEAD7E5),
    'propósito': const Color(0xFFdbaf35),
    'equilíbrio emocional': const Color(0xFFFFB347),
    'autocuidado': const Color(0xFF8E7CC3),
    'amizade': const Color(0xFFFF9AA2),
    'motivação': const Color(0xFF90CAF9),
    'coragem': const Color(0xFFF48FB1),
    'esperança': const Color(0xFFFFE082),
  };


  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // ✨ Carrega dados com mix de categorias
  Future<void> _loadData({bool shuffle = false}) async {
    setState(() => isLoading = true);

    try {
      final response = await supabase
          .from('skills_tips')
          .select()
          .eq('year', widget.year)
          .eq('lang', 'pt');

      final allTips = List<Map<String, dynamic>>.from(response);
      allTips.shuffle(Random());

      final Map<String, List<Map<String, dynamic>>> grouped = {};
      for (final tip in allTips) {
        final category = (tip['category'] ?? 'Outros').toString();
        grouped.putIfAbsent(category, () => []).add(tip);
      }

      final categories = grouped.keys.toList()..shuffle(Random());
      final selected = categories.take(5);

      skills = [
        for (final cat in selected)
          if (grouped[cat]!.isNotEmpty) grouped[cat]!.first,
      ];

      if (shuffle) skills.shuffle(Random());
    } catch (e) {
      debugPrint('Erro ao carregar dados: $e');
    }

    setState(() => isLoading = false);
  }

  // 🔁 Controle de atualização (até 3 vezes por dia)
  Future<void> _handleRefresh() async {
    final prefs = await SharedPreferences.getInstance();
    final todayKey =
        "refresh_${DateTime.now().year}_${DateTime.now().month}_${DateTime.now().day}";
    final count = prefs.getInt(todayKey) ?? 0;

    if (count >= 3) {
      setState(() => refreshCount = 3);
      return;
    }

    // ✨ som suave e cor aleatória
    await player.play(AssetSource('sounds/pop.mp3'));
    final random = Random();
    final colors = categoryColors.values.toList();
    setState(() {
      currentButtonColor = colors[random.nextInt(colors.length)];
    });

    await _loadData(shuffle: true);
    await prefs.setInt(todayKey, count + 1);
    setState(() => refreshCount = count + 1);
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final monthColor = getMonthColor(widget.month);

    return MonthlyPageTemplate(
      month: widget.month,
      year: widget.year,
      title: 'Desenvolvendo Habilidades',
      child: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 🌼 Lista de dicas
          ...skills.asMap().entries.map((entry) {
            final index = entry.key;
            final tip = entry.value;

            final category =
            (tip['category'] ?? '').toString().toLowerCase();

            final bgColor = categoryColors.values.elementAt(
              Random().nextInt(categoryColors.length),
            );


            return TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: Duration(milliseconds: 600 + (index * 150)),
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, (1 - value) * 20),
                    child: child,
                  ),
                );
              },
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 10),
                padding: const EdgeInsets.symmetric(
                    vertical: 16, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 🔹 Etiqueta colorida
                    Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 4, horizontal: 12),
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _capitalize(tip['category'] ?? ''),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      tip['text'] ?? '',
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.5,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),

          const SizedBox(height: 20),

          // 🌟 Botão mágico
          Center(
            child: GestureDetector(
              onTapDown: (_) => setState(() => isPressed = true),
              onTapUp: (_) async {
                setState(() => isPressed = false);
                await Future.delayed(
                    const Duration(milliseconds: 120));
                _handleRefresh();
              },
              onTapCancel: () => setState(() => isPressed = false),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutBack,
                transform: Matrix4.identity()
                  ..scale(isPressed ? 0.93 : 1.0),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      currentButtonColor.withOpacity(0.9),
                      currentButtonColor.withOpacity(0.7),
                      Colors.white.withOpacity(0.1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: currentButtonColor.withOpacity(0.4),
                      blurRadius: 15,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 28, vertical: 14),
                  child: Text(
                    refreshCount >= 3
                        ? "Volte amanhã 🌙"
                        : "Ver mais dicas (${3 - refreshCount} restantes)",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
