import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:myyearmystory/screens/auth/auth_page_view.dart';
import 'package:myyearmystory/screens/dashboard/dashboard_screen.dart';
import 'package:myyearmystory/screens/splash/fade_page_transition.dart';

import 'package:myyearmystory/services/app_session.dart';
import 'package:myyearmystory/services/secure_storage_service.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:myyearmystory/widgets/auth/biometric_login_page.dart';

// ======================================================
//  SPLASH TRANSITION SCREEN — FINAL VERSION
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

    // Agora chamamos o checkSession REAL
    _checkSession();
  }

  // ======================================================
  // CHECK SESSION (versão final, sem piscadas)
  // ======================================================
  Future<void> _checkSession() async {
    await Future.delayed(const Duration(milliseconds: 700));

    try {
      final storedSession = await SecureStorageService.readSessionJson();
      final supabaseSession =
          Supabase.instance.client.auth.currentSession;

      // 1️⃣ SE TEM SESSÃO NO SECURE STORAGE → LOGIN BIOMÉTRICO
if (storedSession != null && storedSession.isNotEmpty) {
  if (!mounted) return;
  Navigator.of(context).pushReplacement(
    fadePageTransition(const BiometricLoginPage()),
  );
  return;
}

// 2️⃣ SE SUPABASE ACHA SESSÃO ATIVA → VAI DIRETO PARA DASHBOARD
if (supabaseSession != null) {
  AppSession.flow = AppAuthFlow.authenticated;

  if (!mounted) return;
  Navigator.of(context).pushReplacement(
    fadePageTransition(
      DashboardScreen(
        month: DateTime.now().month,
        year: DateTime.now().year,
      ),
    ),
  );
  return;
}


      // 3️⃣ SE NADA DISSO → MOSTRA OS BOTÕES
      if (!mounted) return;
      setState(() => _showButtons = true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _showButtons = true);
    }
  }

  // ======================================================
  // NAVIGATION
  // ======================================================
  void _goToLogin() {
    AppSession.reset();

    Navigator.of(context).pushReplacement(
      fadePageTransition(const AuthPageView()),
    );
  }

  void _enterAsGuest() async {
    AppSession.flow = AppAuthFlow.guest;

    // Limpa sessão real
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

  // ======================================================
  // UI
  // ======================================================
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

  // ======================================================
  // SPLASH ANIMATION
  // ======================================================
  Widget _buildAnimatedSplash(bool isTablet) {
    return FadeTransition(
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
            const SizedBox(height: 20),

            // Texto principal — agora mais bonito, grande e responsivo
            ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: isTablet ? 500 : 300,
              ),
              child: Text(
                'splash.new_chapter'.tr(),
                textAlign: TextAlign.center,
                softWrap: true,
                maxLines: 2,
                style: GoogleFonts.satisfy(
                  fontSize: isTablet ? 30 : 28,
                  height: 1.2,
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
    );
  }

  // ======================================================
  // BUTTONS SCREEN
  // ======================================================
  Widget _buildButtons(bool isTablet) {
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

          // ✨ Subtítulo agora mais forte, mais alinhado e responsivo
          Text(
            'splash.subtitle'.tr(),
            textAlign: TextAlign.center,
            softWrap: true,
            maxLines: 2,
            style: GoogleFonts.satisfy(
              fontSize: isTablet ? 40 : 22,
              height: 1.25,
              color: Colors.black87,
            ),
          ),

          const SizedBox(height: 60),

          // LOGIN BUTTON
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

          // GUEST BUTTON
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
