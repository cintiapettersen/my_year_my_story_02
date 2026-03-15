import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
import 'package:myyearmystory/widgets/shared/app_pill_button.dart';

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

  bool isPremiumUser = false;
  bool _isLoading = true;
  bool _hasError = false;
  bool _isRefreshing = false;

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

  String get _userKey => supabase.auth.currentUser?.id ?? 'guest';

  int get _cooldownBucket {
    final windowMs = const Duration(hours: 12).inMilliseconds;
    return DateTime.now().millisecondsSinceEpoch ~/ windowMs;
  }

  String get _refreshPrefsKey => "refresh_tips_${_userKey}_b$_cooldownBucket";

  String get _seenPrefsKey => "skills_seen_${_userKey}_b$_cooldownBucket";

  String? _tipStorageId(Map<String, dynamic> tip) {
    final dynamic id = tip["id"] ??
        tip["uuid"] ??
        tip["tip_id"] ??
        tip["text"] ??
        tip["text_en"];
    final value = id?.toString().trim();
    if (value == null || value.isEmpty) return null;
    return value;
  }

  int _dailySeed() {
    final now = DateTime.now();
    final userId = supabase.auth.currentUser?.id ?? '';
    return (now.year * 10000 + now.month * 100 + now.day) ^ userId.hashCode;
  }

  Future<void> _initializePage() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });

      await _loadRefreshCount();
      await _loadData();
    } catch (_) {
      if (mounted) {
        setState(() => _hasError = true);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadRefreshCount() async {
    final prefs = await SharedPreferences.getInstance();
    final count = prefs.getInt(_refreshPrefsKey) ?? 0;
    if (!mounted) return;
    setState(() => refreshCount = count);
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
    final prefs = await SharedPreferences.getInstance();
    final storedSeen = prefs.getStringList(_seenPrefsKey) ?? const <String>[];

    final response = await supabase.from('skills_tips').select();
    final allTips = List<Map<String, dynamic>>.from(response);

    if (allTips.isEmpty) {
      if (!mounted) return;
      setState(() => skills = []);
      return;
    }

    final tipsById = <String, Map<String, dynamic>>{};
    for (final tip in allTips) {
      final id = _tipStorageId(tip);
      if (id != null) {
        tipsById[id] = tip;
      }
    }

    final seenTips = <Map<String, dynamic>>[];
    for (final id in storedSeen) {
      final tip = tipsById[id];
      if (tip != null) {
        seenTips.add(tip);
      }
    }

    if (seenTips.isEmpty) {
      // Determinístico (diário) para evitar trocar a dica do dia sem refresh.
      final seeded = List<Map<String, dynamic>>.from(allTips)
        ..shuffle(Random(_dailySeed()));
      final dailyTip = seeded.first;
      seenTips.add(dailyTip);

      final dailyId = _tipStorageId(dailyTip);
      if (dailyId != null) {
        await prefs.setStringList(_seenPrefsKey, [dailyId]);
      }
    }

    // ⚠️ único setState permitido aqui
    if (mounted) {
      setState(() {
        skills = seenTips;
      });
    }
  }


  /// 🔄 EXECUTA REFRESH (SEM VALIDAÇÃO)
  Future<void> _handleRefresh() async {
    final prefs = await SharedPreferences.getInstance();
    final count = prefs.getInt(_refreshPrefsKey) ?? 0;
    final seenIds = (prefs.getStringList(_seenPrefsKey) ?? const <String>[])
        .toList(growable: true);
    final seenSet = seenIds.toSet();

    final response = await supabase.from('skills_tips').select();
    final allTips = List<Map<String, dynamic>>.from(response)..shuffle();

    Map<String, dynamic>? newTip;
    for (final tip in allTips) {
      final id = _tipStorageId(tip);
      if (id == null) continue;
      if (!seenSet.contains(id)) {
        newTip = tip;
        seenIds.add(id);
        break;
      }
    }

    if (newTip == null) {
      // fallback: caso a lista seja pequena, reaproveita uma dica existente
      newTip = allTips.isNotEmpty ? allTips.first : null;
      final id = newTip == null ? null : _tipStorageId(newTip);
      if (id != null && !seenSet.contains(id)) {
        seenIds.add(id);
      }
    }

    if (newTip == null) return;

    await prefs.setStringList(_seenPrefsKey, seenIds);
    await prefs.setInt(_refreshPrefsKey, count + 1);

    if (!mounted) return;
    setState(() {
      refreshCount = count + 1;
      final newId = _tipStorageId(newTip!);
      final existing = skills
          .map(_tipStorageId)
          .whereType<String>()
          .toSet();
      if (newId == null || !existing.contains(newId)) {
        skills = [...skills, newTip!];
      }
    });
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

                // 🔹 DICA DO DIA (1 POR VEZ)
                if (skills.isNotEmpty)
                  _SkillTipCard(
                    monthAccent: currentButtonColor,
                    tip: skills.last,
                  ),
                const SizedBox(height: 22),

                // 🔹 BOTÃO REFRESH
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 320),
                    child: AppPillButton(
                      expand: true,
                      text: refreshButtonLabel,
                      backgroundColor: currentButtonColor,
                      onPressed: _isRefreshing
                          ? null
                          : () async {
                              final canExecute =
                                  await canExecutePremiumAction(context);
                              if (!canExecute) return;

                              setState(() => _isRefreshing = true);
                              try {
                                await _handleRefresh();
                              } finally {
                                if (mounted) {
                                  setState(() => _isRefreshing = false);
                                }
                              }
                            },
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
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

class _SkillTipCard extends StatelessWidget {
  final Color monthAccent;
  final Map<String, dynamic> tip;

  const _SkillTipCard({
    required this.monthAccent,
    required this.tip,
  });

  @override
  Widget build(BuildContext context) {
    final text = getLocalizedTipText(context, tip);
    final category = (tip["category_mapped"] as String?)?.toLowerCase().trim();
    final resolvedCategory = (category != null && category.isNotEmpty)
        ? category
        : fallbackCategory(text);

    final categoryColor =
        skillCategoryColors[resolvedCategory] ?? Colors.purple.shade100;

    final isTablet = MediaQuery.sizeOf(context).width > 600;
    final maxWidth = isTablet ? 520.0 : 420.0;
    final cardHeight = isTablet ? 420.0 : 360.0;
    final fontSize = isTablet ? 38.0 : 32.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: maxWidth,
          ),
          child: SizedBox(
            height: cardHeight,
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    categoryColor.withValues(alpha: 0.95),
                    monthAccent.withValues(alpha: 0.30),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(34),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.10),
                    blurRadius: 28,
                    offset: const Offset(0, 14),
                  ),
                ],
              ),
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8EDF2),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: -14,
                      left: -2,
                      child: Text(
                        "“",
                        style: TextStyle(
                          fontSize: isTablet ? 78 : 66,
                          fontWeight: FontWeight.w900,
                          color: Colors.black.withValues(alpha: 0.22),
                          height: 0.9,
                        ),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Align(
                          alignment: Alignment.topCenter,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: categoryColor.withValues(alpha: 0.85),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              'tips_categories.$resolvedCategory'.tr(),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ),
                        const Spacer(),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            text,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.monteCarlo(
                              fontSize: fontSize,
                              height: 1.25,
                              color: Colors.black.withValues(alpha: 0.85),
                            ),
                          ),
                        ),
                        const Spacer(),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
