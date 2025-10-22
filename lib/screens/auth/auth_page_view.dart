import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'signup_screen.dart';

class AuthPageView extends StatefulWidget {
  const AuthPageView({super.key});

  @override
  State<AuthPageView> createState() => _AuthPageViewState();
}

class _AuthPageViewState extends State<AuthPageView> {
  final PageController _pageController = PageController(initialPage: 0);

  /// Vai para a tela de cadastro
  void _goToSignup() {
    FocusScope.of(context).unfocus(); // fecha o teclado, se aberto
    _pageController.animateToPage(
      1,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  /// Volta para a tela de login
  void _goToLogin() {
    FocusScope.of(context).unfocus();
    _pageController.animateToPage(
      0,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _pageController.dispose(); // limpa o controller ao sair
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(), // evita swipe manual
          children: [
            const LoginScreen(), // 👈 remove o onSignUpTap
            SignupScreen(onLoginTap: _goToLogin),
          ],
        ),
      ),
    );
  }
}
