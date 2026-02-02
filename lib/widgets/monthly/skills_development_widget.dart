import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:easy_localization/easy_localization.dart';

import 'package:myyearmystory/widgets/shared/month_page_template.dart';
import 'package:myyearmystory/screens/premium/premium_popup.dart';
import 'package:myyearmystory/utils/month_colors.dart';
import 'package:myyearmystory/utils/responsive.dart';
import 'package:myyearmystory/utils/localized_tip.dart';
import 'package:myyearmystory/utils/access_control.dart';
import 'package:myyearmystory/utils/app_config.dart';
import 'package:myyearmystory/screens/popups/popup_login.dart';
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

  /// 🔑 CHECA PREMIUM / ADMIN
  Future<void> _checkPremiumStatus() async {
    final user = supabase.auth.currentUser;

    if (user == null || user.isAnonymous == true) {
      setState(() => isPremiumUser = false);
      return;
    }

    final premium = await AccessControl.isPremium();
    final admin = AppConfig.isAdmin(user.email);

    setState(() => isPremiumUser = premium || admin);
  }

  /// 📥 CARREGA DICAS
  Future<void> _loadData() async {
    setState(() => isLoading = true);

    try {
      final response = await supabase.from('skills_tips').select();

      final allTips = List<Map<String, dynamic>>.from(response);
      allTips.shuffle();

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

      final List<Map<String, dynamic>> selected = [];
      grouped.forEach((_, list) {
        if (list.isNotEmpty) selected.add(list.first);
      });

      selected.shuffle();

      setState(() {
        skills = selected.take(5).toList();
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  /// 🔄 REFRESH (COM BLOQUEIO PREMIUM)
  Future<void> _handleRefresh() async {
  if (!mounted) return;

  final prefs = await SharedPreferences.getInstance();
  if (!mounted) return;

  final key =
      "refresh_${widget.year}_${widget.month}_${DateTime.now().day}";
  final count = prefs.getInt(key) ?? 0;

  final user = supabase.auth.currentUser;

  // 👤 convidado → login
  if (user == null) {
    showLoginPrompt(context);
    return;
  }

  // 💎 logado mas não premium → popup premium
  if (!isPremiumUser) {
    showLoginPrompt(context);
    return;
  }

  // ⛔ limite diário
  if (count >= 3) {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          "tips.refresh_title".tr(),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text("tips.refresh_message".tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("tips.refresh_ok".tr()),
          ),
        ],
      ),
    );
    return;
  }

  // 🔄 refresh permitido
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
      child: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ResponsiveLayout(
              builder: (context, constraints, isTablet) {
                return Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: isTablet ? 600 : constraints.maxWidth,
                    ),
                    child: Column(
                      children: [
                        ...skills.asMap().entries.map((entry) {
                          final index = entry.key;
                          final tip = entry.value;
                          final text =
                              getLocalizedTipText(context, tip);

                          final category =
                              (tip["category_mapped"] as String?)
                                      ?.toLowerCase()
                                      .trim() ??
                                  fallbackCategory(text);

                          final color =
                              skillCategoryColors[category] ??
                                  Colors.purple.shade100;

                          return Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: isTablet ? 20 : 14),
                              Container(
                                padding:
                                    const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6),
                                decoration: BoxDecoration(
                                  color: color,
                                  borderRadius:
                                      BorderRadius.circular(8),
                                ),
                                child: Text(
                                  "♡ ${'tips_categories.$category'.tr()} ♡",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              SizedBox(height: isTablet ? 24 : 20),
                              Text(
  text,
  textAlign: TextAlign.left,
  style: TextStyle(
    fontSize: isTablet ? 17 : 16,
    height: isTablet ? 1.6 : 1.5,
  ),
),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(
                                        vertical: 13),
                                child: Divider(
                                  color: index <
                                          skills.length - 1
                                      ? Colors.black26
                                      : Colors.transparent,
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                        const SizedBox(height: 60),
                        
                                                GestureDetector(
                          onTapDown: (_) =>
                              setState(() => isPressed = true),
                          onTapUp: (_) async {
                            setState(() => isPressed = false);
                            await Future.delayed(
                                const Duration(milliseconds: 120));
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
                                borderRadius:
                                    BorderRadius.circular(10),
                              ),
                              child: Text(
                                !isPremiumUser
                                    ? "tips.refresh_premium_button"
                                        .tr()
                                    : "tips.refresh_see_more".tr(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  } // build
} // _Skills