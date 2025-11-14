import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';
import 'package:myyearmystory/widgets/monthly/monthly_page_template.dart';
import 'package:myyearmystory/screens/premium/premium_popup.dart';

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
  List<Map<String, dynamic>> skills = [];
  bool isLoading = true;
  int refreshCount = 0;
  bool isPremiumUser = false;
  bool isPressed = false;
  Color currentButtonColor = const Color(0xFFE2377D);

  final Map<String, Color> categoryColors = {
    'inspiração': Color(0xFF679BD3),
    'astronomia': Color(0xFFDDBFEF),
    'ciência': Color(0xFFE2377D),
    'universo': Color(0xFFEA7ACD),
    'organização': Color(0xFFCF8EE8),
    'autoconhecimento': Color(0xFFD1C269),
    'saúde': Color(0xFF9CBC68),
    'espiritualidade': Color(0xFFF0D4B8),
    'gratidão': Color(0xFFEAD7E5),
    'propósito': Color(0xFFdbaf35),
    'equilíbrio emocional': Color(0xFFFFB347),
    'autocuidado': Color(0xFF8E7CC3),
    'amizade': Color(0xFFFF9AA2),
    'motivação': Color(0xFF90CAF9),
    'coragem': Color(0xFFF48FB1),
    'esperança': Color(0xFFFFE082),
  };

  @override
  void initState() {
    super.initState();
    _checkPremiumStatus();
    _loadData();
  }

  Future<void> _checkPremiumStatus() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      setState(() => isPremiumUser = false);
      return;
    }

    final response = await supabase
        .from('users')
        .select('is_premium')
        .eq('id', user.id)
        .maybeSingle();

    setState(() {
      isPremiumUser = response != null && response['is_premium'] == true;
    });
  }

  Future<void> _loadData({bool shuffle = false}) async {
    setState(() => isLoading = true);

    try {
      final response = await supabase
          .from('skills_tips')
          .select()
          .eq('year', widget.year)
          .eq('lang', 'pt');

      final all = List<Map<String, dynamic>>.from(response)..shuffle();

      final grouped = <String, List<Map<String, dynamic>>>{};

      for (final tip in all) {
        final category = (tip['category'] ?? 'Outros').toString();
        grouped.putIfAbsent(category, () => []).add(tip);
      }

      final categories = grouped.keys.toList()..shuffle();
      final selected = categories.take(5);

      skills = [
        for (final cat in selected)
          if (grouped[cat]!.isNotEmpty) grouped[cat]!.first,
      ];

      if (shuffle) skills.shuffle();
    } catch (_) {}

    setState(() => isLoading = false);
  }

  Future<void> _handleRefresh() async {
    if (!isPremiumUser) {
      showPremiumPrompt(context);
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final key =
        "refresh_${DateTime.now().year}_${DateTime.now().month}_${DateTime.now().day}";
    final count = prefs.getInt(key) ?? 0;

    if (count >= 3) {
      setState(() => refreshCount = 3);
      return;
    }

    final random = Random();
    currentButtonColor =
        categoryColors.values.elementAt(random.nextInt(categoryColors.length));

    await _loadData(shuffle: true);

    await prefs.setInt(key, count + 1);
    setState(() => refreshCount = count + 1);
  }

  String _cap(String t) {
    if (t.isEmpty) return t;
    return t[0].toUpperCase() + t.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return MonthlyPageTemplate(
      month: widget.month,
      year: widget.year,
      title: 'Desenvolvendo Habilidades',
      description:
          'Todo mês traz uma chance de aprender algo novo e fortalecer quem você é. Explore com leveza e veja o que mais combina com você!',
      child: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ...skills.asMap().entries.map((entry) {
                  final index = entry.key;
                  final tip = entry.value;

                  final category = (tip['category'] ?? '').toLowerCase();
                  final bgColor =
                      categoryColors[category] ?? Colors.pinkAccent;

                  return TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration:
                        Duration(milliseconds: 600 + (index * 150)),
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
                      margin: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 4),
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // categoria colorida
                          Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 4, horizontal: 10),
                            decoration: BoxDecoration(
                              color: bgColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _cap(tip['category'] ?? ''),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),

                          // texto da dica
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

                // ---- BOTÃO ----
                GestureDetector(
                  onTapDown: (_) => setState(() => isPressed = true),
                  onTapUp: (_) async {
                    setState(() => isPressed = false);
                    await Future.delayed(
                      const Duration(milliseconds: 120),
                    );
                    _handleRefresh();
                  },
                  onTapCancel: () => setState(() => isPressed = false),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    transform: Matrix4.identity()
                      ..scale(isPressed ? 0.93 : 1.0),
                    curve: Curves.easeOutBack,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 28, vertical: 14),
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
                    child: Text(
                      isPremiumUser
                          ? (refreshCount >= 3
                              ? "Volte amanhã 🌙"
                              : "Ver mais dicas (${3 - refreshCount} restantes)")
                          : "Ver mais dicas 🌟 (Premium)",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
