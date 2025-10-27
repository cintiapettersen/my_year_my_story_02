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

  /// Vai para a tela de login
  void _goToLogin() {
    FocusScope.of(context).unfocus();
    _pageController.animateToPage(
      0,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  /// Vai para a tela de cadastro
  void _goToSignup() {
    FocusScope.of(context).unfocus();
    _pageController.animateToPage(
      1,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  /// Entra como convidado
  void _enterAsGuest() {
    Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (route) => false);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            /// 👇 Tela antiga de login direto
            const LoginScreen(),

            /// Tela de cadastro
            SignupScreen(onLoginTap: _goToLogin),

            /// (Tela nova de boas-vindas — mantida, mas não mostrada agora)
            // _buildWelcomeScreen(),
          ],
        ),
      ),
    );
  }

  /// 🩵 Tela de boas-vindas (guardada para uso futuro)
  Widget _buildWelcomeScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            const Icon(
              Icons.auto_stories_rounded,
              size: 80,
              color: Colors.pinkAccent,
            ),
            const SizedBox(height: 20),
            Text(
              'Bem-vindo(a) ao My Year, My Story!',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Escolha como deseja começar:',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: _goToLogin,
              icon: const Icon(Icons.login),
              label: const Text('Entrar com Google ou E-mail'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _enterAsGuest,
              icon: const Icon(Icons.person_outline),
              label: const Text('Entrar como convidado'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: _goToSignup,
              child: const Text('Criar uma conta'),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
