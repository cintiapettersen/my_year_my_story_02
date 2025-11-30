import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class PremiumPage extends StatefulWidget {
  const PremiumPage({super.key});

  @override
  State<PremiumPage> createState() => _PremiumPageState();
}

class _PremiumPageState extends State<PremiumPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  // Paleta BabyKangoo
  final Color blue = const Color(0xFFA8C5DB);
  final Color orange = const Color(0xFFE18B50);
  final Color yellow = const Color(0xFFDDC872);
  final Color green = const Color(0xFF9CBC68);
  final Color brown = const Color(0xFFA07756);
  final Color pink = const Color(0xFFFF4FA3);

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // === GLASS CONTAINER ===
  Widget _glass({
    required Widget child,
    double opacity = 0.10,
    double borderOpacity = 0.25,
    EdgeInsetsGeometry padding = const EdgeInsets.all(20),
    double radius = 26,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(opacity),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: Colors.white.withOpacity(borderOpacity),
              width: 1.3,
            ),
          ),
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 🌌 Fundo dark premium
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF2C2F66),
              Color(0xFF1B1C3A),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 70),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // ⭐ Hero Card
                _glass(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 22, vertical: 32),
                  child: Column(
                    children: [
                      // Ícone premium dentro de círculo glass
                      _glass(
                        padding: const EdgeInsets.all(20),
                        radius: 60,
                        opacity: 0.12,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          child: Icon(
                            Icons.workspace_premium_rounded,
                            size: 52,
                            color: pink,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      Text(
                        "Premium",
                        style: const TextStyle(
                          fontFamily: "Barriecito",
                          color: Colors.white,
                          fontSize: 38,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      const SizedBox(height: 10),

                      Text(
                        'premium.subtitle'.tr(),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.75),
                          fontSize: 16,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 35),

                // 🎁 Benefícios
                _buildBenefitsCard(),

                const SizedBox(height: 35),

                // 🔒 Botão Assinar
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: _glass(
                    opacity: 0.12,
                    borderOpacity: 0.35,
                    padding: EdgeInsets.zero,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(26),
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (_) => AlertDialog(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            title: Text(
                              "premium.dialog_title".tr(),
                              textAlign: TextAlign.center,
                            ),
                            content: Text(
                              "premium.dialog_message".tr(),
                              textAlign: TextAlign.center,
                            ),
                            actionsAlignment: MainAxisAlignment.center,
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text("premium.dialog_button".tr()),
                              ),
                            ],
                          ),
                        );
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            vertical: 18, horizontal: 10),
                        alignment: Alignment.center,
                        child: Text(
                          "premium.subscribe_button".tr(),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(
                                color: pink.withOpacity(0.5),
                                blurRadius: 12,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 25),

                // 🔙 Botão Voltar
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'premium.back_button'.tr(),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 15,
                    ),
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 🌈 Benefícios em cards glass
  Widget _buildBenefitsCard() {
    final items = [
      {
        "icon": Icons.favorite_rounded,
        "color": pink,
        "text": "premium.monthly_detail1".tr(),
      },
      {
        "icon": Icons.auto_awesome,
        "color": blue,
        "text": "premium.monthly_detail2".tr(),
      },
      {
        "icon": Icons.lock_open_rounded,
        "color": orange,
        "text": "premium.monthly_detail3".tr(),
      },
      {
        "icon": Icons.star_rounded,
        "color": yellow,
        "text": "premium.annual_detail1".tr(),
      },
      {
        "icon": Icons.extension_rounded,
        "color": green,
        "text": "premium.annual_detail2".tr(),
      },
      {
        "icon": Icons.bubble_chart_rounded,
        "color": brown,
        "text": "premium.annual_detail3".tr(),
      },
    ];

    return _glass(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "premium.title".tr(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 18),

          ...items.map((i) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Icon(i["icon"] as IconData,
                      color: i["color"] as Color, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      i["text"] as String,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
