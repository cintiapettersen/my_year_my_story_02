import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:easy_localization/easy_localization.dart';

import 'package:myyearmystory/widgets/shared/month_page_template.dart';
import 'package:myyearmystory/screens/premium/premium_popup.dart';
import 'package:myyearmystory/services/did_you_know_service.dart';
import 'package:myyearmystory/utils/month_colors.dart';
import 'package:myyearmystory/utils/access_control.dart';

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
    debugPrint(
        '🔥 DidYouKnowWidget INIT — month=${widget.month} year=${widget.year}');
    _initPage();
  }

  /// 🔹 inicialização organizada (PONTO ÚNICO)
  Future<void> _initPage() async {
    await _checkPremiumStatus();
    await _loadRefreshCount();
    await _loadCuriosities();
  }

  Future<void> _checkPremiumStatus() async {
    final isPrem = await AccessControl.isPremium();
    if (!mounted) return;
    setState(() => isPremiumUser = isPrem);
  }

  /// 🔹 carrega contador salvo
  Future<void> _loadRefreshCount() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final key = "refresh_did_you_know_${now.year}_${now.month}_${now.day}";
    if (!mounted) return;
    setState(() => refreshCount = prefs.getInt(key) ?? 0);
  }

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

  Future<void> _handleRefresh() async {
    if (!isPremiumUser) {
      showPremiumPopup(context);
      return;
    }

    if (refreshCount >= maxRefresh) return;

    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final key = "refresh_did_you_know_${now.year}_${now.month}_${now.day}";

    await _loadCuriosities();
    await prefs.setInt(key, refreshCount + 1);

    if (!mounted) return;
    setState(() => refreshCount++);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final locale = context.locale.languageCode;
    final currentButtonColor = getMonthColor(widget.month);
    final translatedMonth = "months.${widget.month}".tr();

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
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF444444),
                    ),
                    textAlign: TextAlign.center,
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),

                    


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
                            width: 1,
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
                              style: const TextStyle(
                                fontSize: 15,
                                color: Colors.black87,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),

                    const SizedBox(height: 24),

                    Center(
                      child: GestureDetector(
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
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 28, vertical: 14),
                          decoration: BoxDecoration(
                            color: currentButtonColor,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    currentButtonColor.withOpacity(0.4),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Text(
                            isPremiumUser && refreshCount < maxRefresh
                                ? "did_you_know.button.discover_more".tr()
                                : "did_you_know.button.come_back_tomorrow".tr(),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
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
