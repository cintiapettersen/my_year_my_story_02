import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';
import 'package:my_year_my_story/widgets/monthly/monthly_page_template.dart';
import 'package:my_year_my_story/utils/month_colors.dart';
import 'package:my_year_my_story/screens/premium/premium_popup.dart';

import '../../services/did_you_know_service.dart';

class DidYouKnowWidget extends StatefulWidget {
  final int month;
  final int year;

  const DidYouKnowWidget({
    super.key,
    required this.month,
    required this.year,
  });

  @override
  State<DidYouKnowWidget> createState() => _DidYouKnowWidgetState();
}

class _DidYouKnowWidgetState extends State<DidYouKnowWidget>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final supabase = Supabase.instance.client;
  final DidYouKnowService _service = DidYouKnowService();

  List<Map<String, dynamic>> curiosities = [];
  bool isLoading = true;
  bool isPressed = false;
  bool isPremiumUser = false;
  int refreshCount = 0;
  Color currentButtonColor = const Color(0xFFE2377D);

  final int maxRefresh = 3;

  final List<Color> categoryColors = const [
    Color(0xFF7FA9D1),
    Color(0xFFD7C3EE),
    Color(0xFFD84A75),
    Color(0xFFE78AC6),
    Color(0xFFCBA5E3),
    Color(0xFFD8CA7D),
  ];

  final Map<int, String> monthMessages = {
    1: "✨ Janeiro é um recomeço — hora de abrir o coração e se encher de curiosidade pelo novo!",
    2: "💫 Fevereiro traz leveza, cor e descobertas curiosas que aquecem o coração.",
    3: "🌿 Março é tempo de crescer, aprender e se encantar com o que o mundo tem pra contar.",
    4: "🌸 Abril desperta a criatividade — prepare-se para curiosidades cheias de vida!",
    5: "🌼 Maio é doce e inspirador — perfeito pra descobrir algo que te faça sorrir.",
    6: "🌞 Junho vem com energia boa e histórias fascinantes esperando por você!",
    7: "🌻 Julho é o mês das surpresas — mergulhe nessas curiosidades e se inspire.",
    8: "🌺 Agosto convida à reflexão e à descoberta de coisas novas e inesperadas.",
    9: "🍂 Setembro é pura inspiração — pequenas curiosidades pra te fazer ver o mundo com outros olhos.",
    10: "🌕 Outubro vem com mistério e magia — perfeito pra explorar o desconhecido!",
    11: "🍁 Novembro é um lembrete: nunca é tarde pra aprender algo novo e se surpreender.",
    12: "🎇 Dezembro fecha o ano com brilho — curiosidades pra encerrar com leveza e encantamento.",
  };

  @override
  void initState() {
    super.initState();
    _checkPremiumStatus();
    _loadCuriosities();
  }

  // 💎 Verifica status Premium ou convidado
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

  // ✨ Carrega curiosidades
  Future<void> _loadCuriosities({bool shuffle = false}) async {
    setState(() => isLoading = true);

    try {
      final data = await _service.fetchCuriosities(widget.month, widget.year);
      final shuffled = List<Map<String, dynamic>>.from(data)..shuffle();
      final limited = shuffled.take(5).toList();

      if (shuffle) limited.shuffle(Random());

      setState(() {
        curiosities = limited;
        isLoading = false;
      });
    } catch (e) {
      debugPrint("Erro ao carregar curiosidades: $e");
      setState(() => isLoading = false);
    }
  }

  // 🔄 Atualizar curiosidades (restrito)
  Future<void> _handleRefresh() async {
    if (!isPremiumUser) {
      showPremiumPrompt(context);
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final todayKey =
        "refresh_curiosities_${DateTime.now().year}_${DateTime.now().month}_${DateTime.now().day}";
    final count = prefs.getInt(todayKey) ?? 0;

    if (count >= maxRefresh) {
      setState(() => refreshCount = maxRefresh);
      return;
    }

    final random = Random();
    final colors = categoryColors;
    setState(() {
      currentButtonColor = colors[random.nextInt(colors.length)];
    });

    await _loadCuriosities(shuffle: true);
    await prefs.setInt(todayKey, count + 1);
    setState(() => refreshCount = count + 1);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final message = monthMessages[widget.month] ??
        "✨ Curiosidades que inspiram e surpreendem!";

    return MonthlyPageTemplate(
      month: widget.month,
      year: widget.year,
      title: "Você Sabia?",
      child: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding:
            const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 16,
                fontStyle: FontStyle.italic,
                color: Colors.black87,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          ...curiosities.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final color =
            categoryColors[index % categoryColors.length];

            final category = (item['category'] != null &&
                (item['category'] as String).isNotEmpty)
                ? '${item['category'][0].toUpperCase()}${item['category'].substring(1)}'
                : null;

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
              child: Card(
                color: Colors.white,
                margin: const EdgeInsets.symmetric(
                    vertical: 8, horizontal: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (category != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 4, horizontal: 8),
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            category,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      const SizedBox(height: 8),
                      Text(
                        item['content'] ?? '',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.justify,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),

          const SizedBox(height: 20),

          // 🌟 Botão com padrão premium
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
                transform:
                Matrix4.identity()..scale(isPressed ? 0.93 : 1.0),
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
                    isPremiumUser
                        ? (refreshCount >= maxRefresh
                        ? "Volte amanhã 🌙"
                        : "Ver mais curiosidades (${maxRefresh - refreshCount} restantes)")
                        : "Ver mais curiosidades 🌟 (Premium)",
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
