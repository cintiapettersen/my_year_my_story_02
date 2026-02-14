import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:easy_localization/easy_localization.dart';

import 'package:myyearmystory/widgets/shared/month_page_template.dart';
import 'package:myyearmystory/utils/month_colors.dart';
import 'package:myyearmystory/utils/responsive.dart';
import 'package:myyearmystory/utils/localized_tip.dart';
import 'package:myyearmystory/utils/access_control.dart';
import 'package:myyearmystory/utils/app_config.dart';
import 'package:myyearmystory/screens/popups/popup_login.dart';
import 'package:myyearmystory/widgets/shared/remote_data_wrapper.dart';

/// 🎨 Categorias oficiais
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
  "intuição": Color.fromARGB(255, 229, 208, 194),
  "hábitos": Color.fromARGB(255, 216, 216, 181),
};

/// 🔎 Fallback de categoria
String fallbackCategory(String text) {
  text = text.toLowerCase();

  if (text.contains("pausa") || text.contains("calma")) return "leveza";
  if (text.contains("energia") || text.contains("proteja")) return "energia";
  if (text.contains("porquê") || text.contains("propósito")) return "propósito";
  if (text.contains("celebre") || text.contains("presença")) return "presença";
  if (text.contains("intuit")) return "intuição";
  if (text.contains("gratid")) return "gratidão";
  if (text.contains("ritmo") || text.contains("rotina")) return "rotina";
  if (text.contains("cres")) return "crescimento";
  if (text.contains("confian")) return "confiança";
  if (text.contains("reflet") || text.contains("entender")) return "reflexão";
  if (text.contains("hábito")) return "hábitos";

  return "autocuidado";
}

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

  static const int maxRefresh = 3;

  final supabase = Supabase.instance.client;

 
  bool isPressed = false;
  bool isPremiumUser = false;
bool _isLoading = true;
bool _hasError = false;



  int refreshCount = 0;

  List<Map<String, dynamic>> skills = [];
  Color currentButtonColor = Colors.pinkAccent;

  @override
void initState() {
  super.initState();
  currentButtonColor = getMonthColor(widget.month);
  _checkPremiumStatus();
  _initializePage();
}

Future<void> _initializePage() async {
  try {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    await _loadData();
  } catch (e) {
    
    if (mounted) {
      setState(() => _hasError = true);
    }
  } finally {
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }
}


/// 🔄 RÓTULO DO BOTÃO DE REFRESH
  String get refreshButtonLabel {
  if (!isPremiumUser) {
    return "tips.refresh_premium_button".tr();
  }

  if (refreshCount >= maxRefresh) {
    return "tips.refresh_come_back_tomorrow".tr();
  }

  return "tips.refresh_see_more".tr();
}


  /// 🔑 CHECA PREMIUM / ADMIN
  Future<void> _checkPremiumStatus() async {
    final user = supabase.auth.currentUser;

    if (user == null || user.isAnonymous) {
      setState(() => isPremiumUser = false);
      return;
    }

    final premium = await AccessControl.isPremium();
    final admin = AppConfig.isAdmin(user.email);

    setState(() => isPremiumUser = premium || admin);
  }

  /// 🔐 GUARD PREMIUM + LIMITE
  Future<bool> canExecutePremiumAction(BuildContext context) async {
    final user = supabase.auth.currentUser;

    if (user == null || user.isAnonymous) {
      showLoginPrompt(context);
      return false;
    }

    if (!isPremiumUser) {
      showLoginPrompt(context);
      return false;
    }

    if (refreshCount >= maxRefresh) {
      return false; // silêncio elegante ✨
    }

    return true;
  }

  /// 📥 CARREGA DICAS
  Future<void> _loadData() async {
  final response = await supabase.from('skills_tips').select();
  final allTips = List<Map<String, dynamic>>.from(response)..shuffle();

  final Map<String, List<Map<String, dynamic>>> grouped = {};

  for (var tip in allTips) {
    final localized = getLocalizedTipText(context, tip);
    final dbCategory =
        (tip["category_mapped"] as String?)?.toLowerCase().trim();

    final category = dbCategory?.isNotEmpty == true
        ? dbCategory!
        : fallbackCategory(localized);

    grouped.putIfAbsent(category, () => []);
    grouped[category]!.add(tip);
  }

  final selected = grouped.values
      .where((list) => list.isNotEmpty)
      .map((list) => list.first)
      .toList()
    ..shuffle();

  // ⚠️ único setState permitido aqui
  if (mounted) {
    setState(() {
      skills = selected.take(5).toList();
    });
  }
}


  /// 🔄 EXECUTA REFRESH (SEM VALIDAÇÃO)
  Future<void> _handleRefresh() async {
    final prefs = await SharedPreferences.getInstance();
    final key =
        "refresh_${widget.year}_${widget.month}_${DateTime.now().day}";
    final count = prefs.getInt(key) ?? 0;

    await _loadData();
    await prefs.setInt(key, count + 1);

    if (!mounted) return;
    setState(() => refreshCount = count + 1);
  }

  @override
Widget build(BuildContext context) {
  super.build(context);

  return MonthPageTemplate(
    month: widget.month,
    year: widget.year,
    title: '',
    pageLabel: "tips.page_label".tr(),
    labelColor: const Color(0xFFb539bc),
    description: "tips.description".tr(),
    child: RemoteDataWrapper(
      isLoading: _isLoading,
      hasError: _hasError,
      onRetry: _initializePage,
      child: ResponsiveLayout(
        builder: (context, constraints, isTablet) {
          return Column(
            children: [
              const SizedBox(height: 32),

              // 🔹 LISTA DE DICAS
              ...skills.map((tip) {
                final text = getLocalizedTipText(context, tip);
                final category =
                    (tip["category_mapped"] as String?)?.toLowerCase() ??
                        fallbackCategory(text);

                final color =
                    skillCategoryColors[category] ??
                        Colors.purple.shade100;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        "♡ ${'tips_categories.$category'.tr()} ♡",
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(text),
                    const Divider(),
                    const SizedBox(height: 28),
                  ],
                );
              }).toList(),

              // 🔹 BOTÃO REFRESH
              GestureDetector(
                onTapDown: (_) => setState(() => isPressed = true),
                onTapUp: (_) async {
                  setState(() => isPressed = false);
                  await Future.delayed(
                    const Duration(milliseconds: 120),
                  );

                  final canExecute =
                      await canExecutePremiumAction(context);
                  if (!canExecute) return;

                  _handleRefresh();
                },
                onTapCancel: () =>
                    setState(() => isPressed = false),
                child: Transform.scale(
                  scale: isPressed ? 0.93 : 1.0,
                  child: AnimatedContainer(
                    duration:
                        const Duration(milliseconds: 250),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: currentButtonColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      refreshButtonLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 40),
            ],
          );
        },
      ),
    ),
  );
}

}