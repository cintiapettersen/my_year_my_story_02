import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:myyearmystory/widgets/shared/month_page_template.dart';
import 'package:myyearmystory/screens/premium/premium_popup.dart';
import 'package:myyearmystory/services/did_you_know_service.dart';
import 'package:myyearmystory/utils/month_colors.dart';
import 'package:myyearmystory/utils/access_control.dart';
import 'package:myyearmystory/screens/popups/popup_login.dart';


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

  bool get isGuest {
  return Supabase.instance.client.auth.currentUser == null;
}

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

  @override
  void initState() {
    super.initState();
    _initPage();
  }

  Future<void> _initPage() async {
    await _checkPremiumStatus();
    await _loadRefreshCount();
    await _loadCuriosities();
  }

  // 🔐 Premium
  Future<void> _checkPremiumStatus() async {
    final user = Supabase.instance.client.auth.currentUser;

    if (user == null) {
      if (!mounted) return;
      setState(() => isPremiumUser = false);
      return;
    }

    final isPrem = await AccessControl.isPremium();
    if (!mounted) return;

    setState(() => isPremiumUser = isPrem);
  }

  // 🔢 Limite por usuário / guest
  Future<void> _loadRefreshCount() async {
    final prefs = await SharedPreferences.getInstance();
    final user = Supabase.instance.client.auth.currentUser;
    final userKey = user?.id ?? 'guest';

    final now = DateTime.now();
    final key =
        "refresh_did_you_know_${userKey}_${now.year}_${now.month}_${now.day}";

    if (!mounted) return;
    setState(() {
      refreshCount = prefs.getInt(key) ?? 0;
    });
  }

  // 📦 Dados
  Future<void> _loadCuriosities() async {
    if (!mounted) return;
    setState(() => isLoading = true);

    try {
      final result = await _service.fetchDailyCuriosities();
      if (!mounted) return;

      setState(() {
        curiosities = result;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ Erro ao carregar curiosidades: $e');
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  // 🔄 Refresh
  Future<void> _handleRefresh() async {
  await Future.delayed(const Duration(milliseconds: 120));
  if (!mounted) return;

  // 🔐 FREE / GUEST → bloqueia sempre
  if (isGuest) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!mounted) return;
    showLoginPrompt(context);
  });
  return;
}

if (!isPremiumUser) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!mounted) return;
    showPremiumPopup(context);
  });
  return;
}

  // 💎 PREMIUM → limite diário
  if (refreshCount >= maxRefresh) {
    return;
  }

  final prefs = await SharedPreferences.getInstance();
  final user = Supabase.instance.client.auth.currentUser;
  final userKey = user?.id ?? 'guest';

  final now = DateTime.now();
  final key =
      "refresh_did_you_know_${userKey}_${now.year}_${now.month}_${now.day}";

  await _loadCuriosities();
  if (!mounted) return;

  final newCount = refreshCount + 1;
  await prefs.setInt(key, newCount);

  if (!mounted) return;
  setState(() {
    refreshCount = newCount;
  });
}


  @override
  Widget build(BuildContext context) {
    super.build(context);

    final locale = context.locale.languageCode;
    final currentButtonColor = getMonthColor(widget.month);

    return MonthPageTemplate(
      month: widget.month,
      year: widget.year,
      title: "",
      pageLabel: "did_you_know.title".tr(),
      labelColor: const Color(0xFFdbaf35),
      description: "did_you_know.desc.fixed".tr(),
      child: isLoading
          ? const Center(child: CircularProgressIndicator())
          : curiosities.isEmpty
              ? Center(
                  child: Text(
                    "did_you_know.empty".tr(),
                    textAlign: TextAlign.center,
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ...curiosities.asMap().entries.map((entry) {
                      final index = entry.key;
                      final item = entry.value;

                      final color =
                          categoryColors[index % categoryColors.length];

                      final rawCategory =
                          item['category']?.toString().toLowerCase() ??
                              'general';

                      final normalizedKey = rawCategory
                          .replaceAll(' ', '_')
                          .replaceAll('ç', 'c')
                          .replaceAll('ã', 'a')
                          .replaceAll('á', 'a')
                          .replaceAll('é', 'e')
                          .replaceAll('í', 'i')
                          .replaceAll('ó', 'o')
                          .replaceAll('ú', 'u');

                      final categoryTr =
                          "did_you_know.categories.$normalizedKey".tr();

                      final contentPt = item['content'];
                      final contentEn = item['text_en'];

                      final curiosityText = locale == 'pt'
                          ? (contentPt ?? '')
                          : (contentEn ?? contentPt ?? '');

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFFF2D7E0),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 4, horizontal: 8),
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                categoryTr,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              curiosityText,
                              style: const TextStyle(height: 1.5),
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 24),
                    Center(
                      child: GestureDetector(
                        onTapDown: (_) {
                          if (!mounted) return;
                          setState(() => isPressed = true);
                        },
                        onTapUp: (_) async {
  if (!mounted) return;

  if (isGuest) {
  showLoginPrompt(context);
  return;
}

if (!isPremiumUser) {
   showLoginPrompt(context);
  return;
}

  setState(() => isPressed = false);
  await _handleRefresh();
},
                        onTapCancel: () {
                          if (!mounted) return;
                          setState(() => isPressed = false);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 28, vertical: 14),
                          decoration: BoxDecoration(
                            color: currentButtonColor,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            isPremiumUser && refreshCount < maxRefresh
                                ? "did_you_know.button.discover_more".tr()
                                : "did_you_know.button.come_back_tomorrow".tr(),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
    );
  }
}
