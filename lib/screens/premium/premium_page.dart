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

  final Color lightPink = const Color(0xFFFFF6F9);
  final Color rose = const Color(0xFFF8C7D8);
  final Color hotPink = const Color(0xFFE15C8C);
  final Color accent = const Color(0xFFC03B66);

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightPink,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          child: Column(
            children: [
              // 🌸 Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.only(top: 80, bottom: 40),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [rose, accent.withOpacity(0.9)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(40),
                    bottomRight: Radius.circular(40),
                  ),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.star_rounded,
                        color: Colors.white, size: 60),
                    const SizedBox(height: 10),
                    Text(
                      'premium.title'.tr(),
                      style: const TextStyle(
                        fontFamily: 'Barriecito',
                        fontSize: 36,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'premium.subtitle'.tr(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // 🌸 Cards
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: [
                    _buildPlanCard(
                      title: 'premium.monthly_title'.tr(),
                      price: 'premium.monthly_price'.tr(),
                      details: [
                        'premium.monthly_detail1'.tr(),
                        'premium.monthly_detail2'.tr(),
                        'premium.monthly_detail3'.tr(),
                      ],
                      accentColor: rose,
                    ),
                    _buildPlanCard(
                      title: 'premium.annual_title'.tr(),
                      price: 'premium.annual_price'.tr(),
                      details: [
                        'premium.annual_detail1'.tr(),
                        'premium.annual_detail2'.tr(),
                        'premium.annual_detail3'.tr(),
                      ],
                      accentColor: hotPink,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // 🌟 Botão assinar
              ScaleTransition(
                scale: _scaleAnimation,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.lock_open_rounded,
                          color: Colors.white),
                      label: Text(
                        'premium.subscribe_button'.tr(),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 4,
                      ),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            title: Text('premium.dialog_title'.tr()),
                            content: Text(
                              'premium.dialog_message'.tr(),
                              textAlign: TextAlign.center,
                            ),
                            actionsAlignment: MainAxisAlignment.center,
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text('premium.dialog_button'.tr()),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Voltar
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'premium.back_button'.tr(),
                  style: const TextStyle(
                    color: Colors.black54,
                    fontSize: 16,
                  ),
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // 🌸 Card de plano
  Widget _buildPlanCard({
    required String title,
    required String price,
    required List<String> details,
    required Color accentColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(
          color: accentColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: accentColor,
            ),
          ),
          const SizedBox(height: 10),

          ...details.map(
            (d) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Icon(Icons.favorite_rounded,
                      color: accentColor, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      d,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          Center(
            child: Text(
              price,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: accentColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
