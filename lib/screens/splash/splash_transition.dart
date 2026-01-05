import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:myyearmystory/screens/auth/auth_page_view.dart';
import 'package:myyearmystory/screens/dashboard/dashboard_screen.dart';
import 'package:myyearmystory/screens/splash/fade_page_transition.dart';
import 'package:myyearmystory/services/app_session.dart';

// 🎨 CORES FIXAS DA SPLASH
const Color splashPrimary = Color(0xFFC03B66);
const Color splashAccent  = Color(0xFFE2377D);

// ======================================================
//  SPLASH TRANSITION SCREEN
// ======================================================
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
    _checkSession();
  }

  Future<void> _checkSession() async {
    await Future.delayed(const Duration(seconds: 3));

    final session = Supabase.instance.client.auth.currentSession;

    if (!mounted) return;

    if (session != null) {
      AppSession.flow = AppAuthFlow.authenticated;

      Navigator.of(context).pushReplacement(
        fadePageTransition(
          DashboardScreen(
            month: DateTime.now().month,
            year: DateTime.now().year,
          ),
        ),
      );
    } else {
      setState(() => _showButtons = true);
    }
  }

  void _goToLogin() {
    AppSession.reset();

    Navigator.of(context).pushReplacement(
      fadePageTransition(const AuthPageView()),
    );
  }

  void _enterAsGuest() {
  AppSession.flow = AppAuthFlow.guest;

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

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: AnimatedSwitcher(
  duration: const Duration(milliseconds: 600),
  child: !_showButtons
      ? _buildAnimatedSplash(isTablet)
      : _buildButtons(isTablet),
),
      ),
    );
  }
Widget _buildAnimatedSplash(bool isTablet, {Key? key}) {
  return Column(
    key: key,
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      FadeTransition(
        opacity: _fadeAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Image.asset(
            'assets/imagens/logo.png',
            height: isTablet ? 180 : 120,
          ),
        ),
      ),

      const SizedBox(height: 20),

      // 🟣 TEXTO DA TRANSIÇÃO (APENAS ESTE)
      ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: isTablet ? 500 : 300,
        ),
        child: Text(
          context.tr('splash.new_chapter'),
          textAlign: TextAlign.center,
          maxLines: 2,
          style: GoogleFonts.cedarvilleCursive(
            fontSize: isTablet ? 30 : 26,
            height: 1.2,
            color: splashPrimary,
          ),
        ),
      ),

      const SizedBox(height: 30),

      FadeTransition(
        opacity: _fadeAnimation,
        child: const CircularProgressIndicator(
          strokeWidth: 2.5,
          valueColor: AlwaysStoppedAnimation(splashPrimary),
        ),
      ),
    ],
  );
}



 Widget _buildButtons(bool isTablet, {Key? key}) {
  return Padding(
    key: key,
    padding: EdgeInsets.symmetric(horizontal: isTablet ? 80 : 40),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // LOGO
        Image.asset(
          'assets/imagens/logo.png',
          height: isTablet ? 180 : 120,
        ),

        const SizedBox(height: 5),

        // 🟣 TEXTO FIXO DA TELA DE AÇÃO
        // "Sua história. Do seu jeito."
        Text(
          context.tr('splash.subtitle'),
          textAlign: TextAlign.center,
          softWrap: true,
          maxLines: 2,
          style: GoogleFonts.cedarvilleCursive(
            fontSize: isTablet ? 40 : 22,
            height: 1.25,
            color: Colors.black87,
          ),
        ),

        const SizedBox(height: 60),

        // BOTÃO LOGIN / CRIAR CONTA
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

        // BOTÃO ENTRAR COMO CONVIDADO
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: _enterAsGuest,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(
                color: Color(0xFFC03B66),
                width: 2,
              ),
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
