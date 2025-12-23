import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:myyearmystory/screens/auth/auth_page_view.dart';
import 'package:myyearmystory/screens/dashboard/dashboard_screen.dart';
import 'package:myyearmystory/screens/splash/fade_page_transition.dart';
import 'package:myyearmystory/services/app_session.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


class SplashTransitionScreen extends StatefulWidget {
  const SplashTransitionScreen({super.key});

  @override
  State<SplashTransitionScreen> createState() =>
      _SplashTransitionScreenState();
}

class _SplashTransitionScreenState extends State<SplashTransitionScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  bool _showButtons = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    );

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.03).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOutCubic,
      ),
    );

    _controller.forward();

    // ⏳ apenas tempo visual do splash
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() => _showButtons = true);
    });
  }

  void _goToLogin() {
    AppSession.reset();

    Navigator.of(context).pushReplacement(
      fadePageTransition(const AuthPageView()),
    );
  }

 void _enterAsGuest() async {
  // 1️⃣ Primeiro marca como guest
  AppSession.flow = AppAuthFlow.guest;

  // 2️⃣ Depois limpa a sessão real do Supabase
  await Supabase.instance.client.auth.signOut();

  if (!mounted) return;

  Navigator.of(context).pushReplacement(
    fadePageTransition(
      DashboardScreen(
        month: DateTime.now().month,
        year: DateTime.now().year,
      ),
    ),
  );
}



  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // --------------------------------------------------
  // 🎨 UI
  // --------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 600),
          child: !_showButtons
              ? FadeTransition(
                  opacity: _fadeAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/imagens/logo.png',
                          height: isTablet ? 180 : 120,
                        ),
                        ConstrainedBox(
  constraints: BoxConstraints(
    maxWidth: isTablet ? 500 : double.infinity,
  ),
  child: Text(
    'splash.new_chapter'.tr(),
    textAlign: TextAlign.center,
    style: GoogleFonts.satisfy(
      fontSize: isTablet ? 40 : 24,
      height: isTablet ? 1.2 : 1.1,
      color: const Color(0xFFC03B66),
    ),
  ),
),
                        const SizedBox(height: 30),
                        const CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation(
                            Color(0xFFC03B66),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : _buildButtons(context, isTablet),
        ),
      ),
    );
  }

  Widget _buildButtons(BuildContext context, bool isTablet) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isTablet ? 80 : 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/imagens/logo.png',
            height: isTablet ? 180 : 120,
          ),
          const SizedBox(height: 30),
          Text(
            'splash.subtitle'.tr(),
            textAlign: TextAlign.center,
            style: GoogleFonts.satisfy(
  fontSize: isTablet ? 32 : 17,
  height: isTablet ? 1.3 : 1.1,
  color: Colors.black87,
),
          ),
          const SizedBox(height: 60),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _goToLogin,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFe2377d),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                'splash.login_button'.tr(),
                style: TextStyle(
                  fontSize: isTablet ? 22 : 16,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _enterAsGuest,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFC03B66), width: 2),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                'splash.guest_button'.tr(),
                style: TextStyle(
                  fontSize: isTablet ? 22 : 16,
                  color: const Color(0xFFC03B66),
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
