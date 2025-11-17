import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:math';
import 'package:easy_localization/easy_localization.dart';

import 'package:myyearmystory/widgets/shared/month_page_template.dart';
import 'package:myyearmystory/screens/premium/premium_popup.dart';
import 'package:myyearmystory/utils/month_colors.dart';
import 'package:myyearmystory/utils/label_colors.dart';

/// ------------------------------------------------------------
/// 💖 PALETA DE CATEGORIAS (Pinterest vibes, teen, suave)
/// ------------------------------------------------------------
final Map<String, Color> skillCategoryColors = {
  "autocuidado": Color(0xFFFAD4D8),
  "energia": Color(0xFFE9B9C9),
  "propósito": Color.fromARGB(255, 228, 201, 184),
  "leveza": Color(0xFFD7CFF2),
  "reflexão": Color(0xFFC9D8E2),
  "gratidão": Color(0xFFF2C3D9),
  "rotina": Color.fromARGB(255, 206, 223, 193),
  "crescimento": Color.fromARGB(255, 212, 178, 173),
  "confiança": Color(0xFFF7E2B5),
  "presença": Color.fromARGB(255, 238, 208, 241),
  "encerramento": Color.fromARGB(255, 198, 176, 193),
  "intuição": Color.fromARGB(255, 229, 208, 194),
};

/// ------------------------------------------------------------
/// ✨ Mapeia o texto → categoria
/// ------------------------------------------------------------
String mapTitleToCategory(String title) {
  title = title.toLowerCase();

  if (title.contains("pausa") || title.contains("calma")) return "leveza";
  if (title.contains("energia") || title.contains("proteja")) return "energia";
  if (title.contains("porquê") || title.contains("propósito")) return "propósito";
  if (title.contains("celebre") || title.contains("presença")) return "presença";
  if (title.contains("intuição") || title.contains("intuit")) return "intuição";
  if (title.contains("gratid")) return "gratidão";
  if (title.contains("ritmo") || title.contains("rotina")) return "rotina";
  if (title.contains("cres") || title.contains("mudou")) return "crescimento";
  if (title.contains("confiança") || title.contains("confie")) return "confiança";
  if (title.contains("reflet") || title.contains("entender")) return "reflexão";
  if (title.contains("encerr") || title.contains("ritual")) return "encerramento";

  return "autocuidado";
}

/// ------------------------------------------------------------
/// 🌈 WIDGET PRINCIPAL
/// ------------------------------------------------------------
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

  bool isLoading = true;
  bool isPressed = false;
  bool isPremiumUser = false;
  int refreshCount = 0;

  List<Map<String, dynamic>> skills = [];
  Color currentButtonColor = Colors.pinkAccent;

  @override
  void initState() {
    super.initState();
    currentButtonColor = getMonthColor(widget.month);
    _checkPremiumStatus();
    _loadData();
  }

  /// 🔐 Verifica usuário premium
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

  /// 🌍 PT / EN auto fallback
  String getLocalizedText(Map<String, dynamic> tip) {
    final locale = context.locale.languageCode;

    if (locale == "en" &&
        tip["text_en"] != null &&
        tip["text_en"].toString().trim().isNotEmpty) {
      return tip["text_en"];
    }

    return tip["text"];
  }

  /// 📌 Carrega dicas com agrupamento por categoria
  /// 📌 Carrega dicas com agrupamento por categoria (nova versão)
Future<void> _loadData() async {
  setState(() => isLoading = true);

  try {
    // 1️⃣ Busca todas as dicas da tabela (já que não há mais mês/ano)
    final response = await supabase.from('skills_tips').select();

    if (response.isEmpty) {
      setState(() {
        skills = [];
        isLoading = false;
      });
      return;
    }

    // 2️⃣ Converte tudo pra lista tipada
    final allTips = List<Map<String, dynamic>>.from(response);

    // 3️⃣ Embaralha pra variar a cada carregamento
    allTips.shuffle();

    // 4️⃣ Agrupa por categoria
    final Map<String, List<Map<String, dynamic>>> grouped = {};

    for (var tip in allTips) {
      final localized = getLocalizedText(tip);
      final category = mapTitleToCategory(localized);

      grouped.putIfAbsent(category, () => []);
      grouped[category]!.add(tip);
    }

    // 5️⃣ Pega 1 dica de cada categoria
    final List<Map<String, dynamic>> onePerCategory = [];

    grouped.forEach((cat, list) {
      if (list.isNotEmpty) {
        onePerCategory.add(list.first);
      }
    });

    // 6️⃣ Embaralha só as categorias
    onePerCategory.shuffle();

    // 7️⃣ Pega só 5 categorias diferentes
    final selected = onePerCategory.take(5).toList();

    // 8️⃣ Se esgotar, mostra a mensagem PT / EN ✨
    if (selected.isEmpty) {
      final isEnglish = context.locale.languageCode == "en";

      setState(() {
        skills = [];
        isLoading = false;

        final message = isEnglish
            ? "You've seen all the tips for today. Come back tomorrow 💛"
            : "Você já viu todas as dicas de hoje. Volte amanhã 💛";

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            duration: const Duration(seconds: 3),
          ),
        );
      });

      return;
    }

    // 9️⃣ Atualiza a tela
    setState(() {
      skills = selected;
      isLoading = false;
    });
  } catch (e) {
    print("Erro ao carregar dicas: $e");
    setState(() => isLoading = false);
  }
}



  /// 🔄 Refresh com limite diário
  Future<void> _handleRefresh() async {
    final prefs = await SharedPreferences.getInstance();
    final key =
        "refresh_${widget.year}_${widget.month}_${DateTime.now().day}";
    final count = prefs.getInt(key) ?? 0;

    final isEnglish = context.locale.languageCode == "en";

    if (!isPremiumUser) {
      showPremiumPrompt(context);
      return;
    }

    if (count >= 3) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(
            isEnglish ? "Come back tomorrow ✨" : "Volte amanhã ✨",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Text(
            isEnglish
                ? "You've already refreshed your suggestions for today!"
                : "Você já atualizou suas dicas de hoje!",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(isEnglish ? "OK" : "Entendi"),
            )
          ],
        ),
      );
      return;
    }

    // 💜 Efeito de cor bonitinho
    final random = Random();
    final monthColor = getMonthColor(widget.month);
    final randomBlend = Color.lerp(
      monthColor,
      Colors.primaries[random.nextInt(Colors.primaries.length)],
      0.3,
    );

    if (randomBlend != null) {
      setState(() => currentButtonColor = randomBlend);
    }

    await _loadData();
    await prefs.setInt(key, count + 1);

    setState(() => refreshCount = count + 1);
  }

  Widget _divider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Row(
        children: [
          Expanded(child: Container(height: 1, color: Colors.black26)),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Icon(Icons.circle, size: 6, color: Colors.black38),
          ),
          Expanded(child: Container(height: 1, color: Colors.black26)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final isEnglish = context.locale.languageCode == "en";
    final labelText = isEnglish ? "Tips" : "Dicas do Mês";

    final fixedPageLabelColor = LabelColors.tips;

    return MonthPageTemplate(
      month: widget.month,
      year: widget.year,
      title: '',
      pageLabel: labelText,
      labelColor: fixedPageLabelColor,
      child: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                ...skills.asMap().entries.map((entry) {
                  final index = entry.key;
                  final tip = entry.value;

                  final text = getLocalizedText(tip);
                  final category = mapTitleToCategory(text);
                  final categoryColor = skillCategoryColors[category]!;

                  return TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: Duration(milliseconds: 600 + index * 150),
                    builder: (context, value, child) {
                      return Opacity(
                        opacity: value,
                        child: Transform.translate(
                          offset: Offset(0, (1 - value) * 20),
                          child: child,
                        ),
                      );
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: categoryColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            "♡ ${category[0].toUpperCase()}${category.substring(1)} ♡",
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              letterSpacing: .2,
                            ),
                          ),
                        ),

                        const SizedBox(height: 10),

                        Text(
                          text,
                          style: const TextStyle(
                            fontSize: 16,
                            height: 1.5,
                            color: Colors.black87,
                          ),
                        ),

                        if (index < skills.length - 1) _divider(),
                      ],
                    ),
                  );
                }).toList(),

                const SizedBox(height: 50),

                /// 🔄 Botão refresh
                GestureDetector(
                  onTapDown: (_) => setState(() => isPressed = true),
                  onTapUp: (_) async {
                    setState(() => isPressed = false);
                    await Future.delayed(
                        const Duration(milliseconds: 120));
                    _handleRefresh();
                  },
                  onTapCancel: () => setState(() => isPressed = false),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    transform:
                        Matrix4.identity()..scale(isPressed ? 0.93 : 1.0),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 28, vertical: 14),
                    decoration: BoxDecoration(
                      color: currentButtonColor,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: currentButtonColor.withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Text(
                      !isPremiumUser
                          ? (isEnglish
                              ? "See more tips (Premium)"
                              : "Ver mais dicas (Premium)")
                          : (refreshCount >= 3
                              ? (isEnglish
                                  ? "Come back tomorrow 🌙"
                                  : "Volte amanhã 🌙")
                              : isEnglish
                                  ? "See more tips (${3 - refreshCount} left)"
                                  : "Ver mais dicas (${3 - refreshCount} restantes)"),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
