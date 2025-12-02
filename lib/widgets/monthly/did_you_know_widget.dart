import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';

import 'package:easy_localization/easy_localization.dart';
import 'package:myyearmystory/widgets/shared/month_page_template.dart';
import 'package:myyearmystory/screens/premium/premium_popup.dart';
import 'package:myyearmystory/services/did_you_know_service.dart';
import 'package:myyearmystory/utils/month_colors.dart';
import 'package:intl/intl.dart';
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

  @override
  void initState() {
    super.initState();
    _checkPremiumStatus();
    _loadCuriositiesForToday();
  }

  Future<void> _checkPremiumStatus() async {
  final isPrem = await AccessControl.isPremium(); // ✓ consulta unificada
  setState(() => isPremiumUser = isPrem);
}

  /// 🔎 CARREGA AS CURIOSIDADES DO DIA
  Future<void> _loadCuriositiesForToday() async {
    setState(() => isLoading = true);

    try {
      final result = await _service.fetchDailyCuriosities();

      if (result.isEmpty) {
        setState(() => isLoading = false);
        return;
      }

      setState(() {
        curiosities = result.take(5).toList();
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  /// 🔄 REFRESH – somente para premium
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

    await _loadCuriositiesForToday();
    await prefs.setInt(todayKey, count + 1);

    setState(() => refreshCount = count + 1);
  }

  /// ============================================================
  ///                        W I D G E T
  /// ============================================================
  @override
  Widget build(BuildContext context) {
    super.build(context);

    final currentButtonColor = getMonthColor(widget.month);

    final todayFormatted =
        DateFormat("dd MMMM", "pt_BR").format(DateTime.now());

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

                    /// 🌟 MENSAGEM DO DIA
                    Center(
                      child: Text(
                        "did_you_know.daily_message".tr(),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFB84E79),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 6),

                    /// 📅 DATA
                    Center(
                      child: Text(
                        "${"did_you_know.updated_at".tr()} $todayFormatted",
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[700],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 18),

                    /// LISTA DE CURIOSIDADES
                    ...curiosities.asMap().entries.map((entry) {
                      final index = entry.key;
                      final item = entry.value;

                      final color =
                          categoryColors[index % categoryColors.length];

                      /// Pegando categoria normalizada
                      final rawCategory =
                          item["category_en"] ?? item["category"] ?? "general";

                      final normalizedKey = rawCategory
                          .toString()
                          .trim()
                          .toLowerCase()
                          .replaceAll(" ", "_")
                          .replaceAll("ç", "c")
                          .replaceAll("ã", "a")
                          .replaceAll("á", "a")
                          .replaceAll("é", "e")
                          .replaceAll("í", "i")
                          .replaceAll("ó", "o")
                          .replaceAll("ú", "u");

                      final categoryTr =
                          "did_you_know.categories.$normalizedKey".tr();

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
                              color: const Color(0xFFF2D7E0),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              /// Categoria Traduzida
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4,
                                  horizontal: 8,
                                ),
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

                              /// Conteúdo da curiosidade
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

                    /// BOTÃO DE REFRESH
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTapDown: (_) => setState(() => isPressed = true),
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
                            transform: Matrix4.identity()
                              ..scale(isPressed ? 0.93 : 1.0),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 28, vertical: 14),
                            decoration: BoxDecoration(
                              color: currentButtonColor,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: currentButtonColor.withOpacity(0.4),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Text(
                              isPremiumUser
                                  ? (refreshCount >= maxRefresh
                                      ? "did_you_know.button.come_back_tomorrow"
                                          .tr()
                                      : "did_you_know.button.discover_more".tr())
                                  : "did_you_know.button.discover_more".tr(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
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
