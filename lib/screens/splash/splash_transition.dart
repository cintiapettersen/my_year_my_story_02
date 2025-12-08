import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:easy_localization/easy_localization.dart'; // 👈 Import necessário para usar .tr()
import 'package:myyearmystory/screens/dashboard/dashboard_screen.dart';
import 'package:myyearmystory/screens/auth/auth_page_view.dart';
import 'package:myyearmystory/screens/splash/fade_page_transition.dart';
import 'package:myyearmystory/supabase/supabase_config.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:myyearmystory/widgets/auth/biometric_login_page.dart';

import 'package:myyearmystory/services/secure_storage_service.dart';



class SplashTransitionScreen extends StatefulWidget {
  const SplashTransitionScreen({super.key});

  @override
  State<SplashTransitionScreen> createState() => _SplashTransitionScreenState();
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
      duration: const Duration(seconds: 4),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    );

    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.03).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOutCubic,
      ),
    );

    _controller.forward();
    _checkSession();
  }

  Future<void> _checkSession() async {
  await Future.delayed(const Duration(seconds: 2));

  try {
    print('🔎 Verificando sessão persistida...');

    // 1️⃣ Lê sessão salva no SecureStorage
    final persisted = await SecureStorageService.readSessionJson();

    if (persisted != null && persisted.isNotEmpty) {
      print('🔐 Sessão encontrada → iniciar biometria');
      _goToBiometricLogin();
      return;
    }

    // 2️⃣ Se não houver sessão → mostrar botões
    print('🚫 Nenhuma sessão. Mostrar opções.');
    if (!mounted) return;
    setState(() => _showButtons = true);

  } catch (e) {
    print('⚠️ Erro ao verificar sessão: $e');
    if (!mounted) return;
    setState(() => _showButtons = true);
  }
}

void _goToBiometricLogin() {
  Navigator.of(context).pushReplacement(
    fadePageTransition(const BiometricLoginPage()),
  );
}

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _enterAsGuest() {
    Navigator.of(context).pushReplacement(
      fadePageTransition(
        DashboardScreen(
          month: DateTime.now().month,
          year: DateTime.now().year,
        ),
      ),
    );
  }

  void _goToLogin() {
    Navigator.of(context).pushReplacement(
      fadePageTransition(const AuthPageView()),
    );
  }

  void _goToDashboard() {
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 700),
        child: !_showButtons
            ? FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/imagens/logo.png',
                    height: 120,
                  ),
                  const SizedBox(height: 24),

                  // 🔹 Frase principal traduzida
                  Text(
  'splash.new_chapter'.tr(),
  style: GoogleFonts.satisfy(
    fontSize: 22,
    fontWeight: FontWeight.w400,
    color: const Color(0xFFC03B66),
  ),
),

                  const SizedBox(height: 20),
                  const CircularProgressIndicator(
                    valueColor:
                    AlwaysStoppedAnimation<Color>(Color(0xFFC03B66)),
                    strokeWidth: 2.5,
                  ),
                ],
              ),
            ),
          ),
        )
            : _buildChoiceScreen(),
      ),
    );
  }

  Widget _buildChoiceScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/imagens/logo.png',
              height: 120,
            ),
            const SizedBox(height: 30),

            // 🔹 Subtítulo traduzido
            Text(
  'splash.subtitle'.tr(),
  textAlign: TextAlign.center,
  style: GoogleFonts.satisfy(
    fontSize: 17,
    fontWeight: FontWeight.w500,
    color: Colors.black87,
  ),
),

            const SizedBox(height: 60),

            // 🔸 Botão de Login / Criar Conta
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _goToLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFe2377d),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  'splash.login_button'.tr(),
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 15),

            // 🔸 Botão de Explorar sem login
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _enterAsGuest,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFC03B66), width: 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  'splash.guest_button'.tr(),
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFFC03B66),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
