import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';

import 'package:easy_localization/easy_localization.dart';
import 'package:myyearmystory/widgets/shared/month_page_template.dart';
import 'package:myyearmystory/screens/premium/premium_popup.dart';
import 'package:myyearmystory/services/did_you_know_service.dart';
import 'package:myyearmystory/screens/premium/premium_popup.dart';



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

  Future<void> _loadCuriosities({bool shuffle = false}) async {
  setState(() => isLoading = true);

  try {
    // O RPC retorna um List puro (NÃO tem .data)
    final result = await supabase.rpc('get_daily_curiosities');

    if (result == null || result is! List || result.isEmpty) {
      debugPrint("❌ RPC retornou vazio ou formato inesperado: $result");
      setState(() => isLoading = false);
      return;
    }

    debugPrint("📌 RPC RECEBIDO (${result.length} itens): $result");

    // Garante que veio no formato certo
    final List<dynamic> data = result;

    final formatted = data.map((item) {
      return {
        'id': item['id'],
        'category': item['category'],
        'category_en': item['category_en'],
        'content': item['content'],
        'text_en': item['text_en'],
      };
    }).toList();

    if (shuffle) {
      formatted.shuffle(Random());
    }

    // GARANTE QUE MOSTRA SÓ 5 SEMPRE
    final limited = formatted.take(5).toList();

    setState(() {
      curiosities = limited;
      isLoading = false;
    });
  } catch (e) {
    debugPrint("Erro ao carregar curiosidades via RPC: $e");
    setState(() => isLoading = false);
  }
}




  Future<void> _handleRefresh() async {
    if (!isPremiumUser) {
      showPremiumPopup(context);
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

    await _loadCuriosities(shuffle: true);
    await prefs.setInt(todayKey, count + 1);
    setState(() => refreshCount = count + 1);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final message = monthMessages[widget.month] ??
        "✨ Curiosidades que inspiram e surpreendem!";

    return MonthPageTemplate(
      month: widget.month,
      year: widget.year,
      title: "",
      pageLabel: "Você Sabia?",
      labelColor: const Color(0xFFdbaf35),
      description: message,
      child: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),

                ...curiosities.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  final color = categoryColors[index % categoryColors.length];

                  final category = (item['category'] != null &&
                          (item['category'] as String).isNotEmpty)
                      ? '${item['category'][0].toUpperCase()}${item['category'].substring(1)}'
                      : null;

                  return TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration:
                        Duration(milliseconds: 600 + (index * 140)),
                    builder: (context, value, child) {
                      return Opacity(
                        opacity: value,
                        child: Transform.translate(
                          offset: Offset(0, (1 - value) * 16),
                          child: child,
                        ),
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: const Color(0xFFF2D7E0), width: 1),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (category != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 4, horizontal: 8),
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                category,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          const SizedBox(height: 8),
                          Text(
                            item['content'] ?? '',
                            style: const TextStyle(
                              fontSize: 15,
                              color: Colors.black87,
                              height: 1.5,
                            ),
                            textAlign: TextAlign.left,
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),

                const SizedBox(height: 24),

                // -------------------------------
                //      BOTÃO VER MAIS
                // -------------------------------
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FittedBox(
                      child: GestureDetector(
                        onTapDown: (_) => setState(() => isPressed = true),
                        onTapUp: (_) async {
                          setState(() => isPressed = false);
                          await Future.delayed(const Duration(milliseconds: 120));
                          _handleRefresh();
                        },
                        onTapCancel: () => setState(() => isPressed = false),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          transform: Matrix4.identity()
                            ..scale(isPressed ? 0.93 : 1.0),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(255, 214, 86, 150),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            isPremiumUser
      ? (refreshCount >= maxRefresh
          ? (context.locale.languageCode == "en"
              ? "Come back tomorrow 🌙"
              : "Volte amanhã 🌙")
          : (context.locale.languageCode == "en"
              ? "See more curiosities (${maxRefresh - refreshCount})"
              : "Ver mais curiosidades (${maxRefresh - refreshCount})"))
      : (context.locale.languageCode == "en"
          ? "See more 🌟"
          : "Ver mais 🌟"),
  textAlign: TextAlign.center,
  style: const TextStyle(
    color: Colors.white,
    fontSize: 13,
    fontWeight: FontWeight.w600,
  ),
),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 40),
              ],
            ),
    );
  }
}
