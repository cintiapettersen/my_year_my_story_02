import 'dart:async';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'login_screen.dart';
import 'signup_screen.dart';

import 'package:myyearmystory/services/app_session.dart';

class AuthPageView extends StatefulWidget {
  const AuthPageView({super.key});

  @override
  State<AuthPageView> createState() => _AuthPageViewState();
}

class _AuthPageViewState extends State<AuthPageView> {
  late final PageController _pageController;
  StreamSubscription<AuthState>? _authSub;

  @override
  void initState() {
    super.initState();

    _pageController = PageController(initialPage: 0);

    // 🔑 Escuta auth para sair da tela quando logar
    _authSub = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (!mounted) return;

      if (data.event == AuthChangeEvent.signedIn &&
          !AppSession.isGuest) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/dashboard',
          (_) => false,
        );
      }
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _goToLogin() {
    FocusScope.of(context).unfocus();
    _pageController.animateToPage(
      0,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  void _goToSignup() {
    FocusScope.of(context).unfocus();
    _pageController.animateToPage(
      1,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  void _enterAsGuest() async {
    // 1️⃣ Marca guest
    AppSession.flow = AppAuthFlow.guest;

    // 2️⃣ Garante Supabase limpo
    await Supabase.instance.client.auth.signOut();

    if (!mounted) return;

    // 3️⃣ Vai direto pro dashboard
    Navigator.of(context).pushNamedAndRemoveUntil(
      '/dashboard',
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isTablet = constraints.maxWidth > 600;

        return Scaffold(
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isTablet ? 600 : constraints.maxWidth,
                ),
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    LoginScreen(
                      onCreateAccountTap: _goToSignup,
                    
                    ),
                    SignupScreen(
                      onLoginTap: _goToLogin,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
