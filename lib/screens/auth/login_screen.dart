import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:myyearmystory/widgets/auth/custom_text_field.dart';
import 'package:myyearmystory/widgets/auth/auth_button.dart';
import 'package:myyearmystory/screens/auth/forgot_password_screen.dart';

import 'package:myyearmystory/services/user_service.dart';
import 'package:myyearmystory/services/google_auth_service.dart';
import 'package:myyearmystory/services/app_session.dart';
import 'package:myyearmystory/services/analytics_service.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback onCreateAccountTap;

  const LoginScreen({super.key, required this.onCreateAccountTap});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  final bool _isGoogleLoading = false;
  bool _rememberMe = false;
  bool _isLoginSelected = true; // 🔁 toggle restaurado

  @override
  void initState() {
    super.initState();
    _loadRememberedEmail();
  }

  // =============================================================
  // REMEMBER ME
  // =============================================================
  Future<void> _loadRememberedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('remembered_email');
    final remember = prefs.getBool('remember_me') ?? false;

    if (email != null) {
      _emailController.text = email;
      setState(() => _rememberMe = remember);
    }
  }

  Future<void> _saveRememberedEmail() async {
    final prefs = await SharedPreferences.getInstance();

    if (_rememberMe) {
      await prefs.setString('remembered_email', _emailController.text.trim());
      await prefs.setBool('remember_me', true);
    } else {
      await prefs.remove('remembered_email');
      await prefs.setBool('remember_me', false);
    }
  }

  // =============================================================
  // EMAIL LOGIN
  // =============================================================
  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    FocusScope.of(context).unfocus();

    AppSession.flow = AppAuthFlow.authenticating;
    try {
      final response = await UserService.signIn(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      final success = response['success'] == true;

      if (success) {
        await _saveRememberedEmail();
        unawaited(AnalyticsService.instance.logOnce('login_completed'));

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('auth.login.success'.tr()),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 1),
          ),
        );
        // ❌ não navega — AuthListener assume
      } else {
        // Importante: em caso de erro (ex: senha errada), sai do estado
        // "authenticating" para não ficar preso na tela branca de loading.
        AppSession.reset();

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'].toString()),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (_) {
      AppSession.reset();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('auth.login.error_general'.tr()),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // =============================================================
  // GOOGLE LOGIN
  // =============================================================
  Future<void> _signInWithGoogle() async {
    AppSession.flow = AppAuthFlow.authenticating;

    try {
      final result = await GoogleAuthService.signInWithGoogle();

      if (result['success'] != true) {
        AppSession.flow = AppAuthFlow.splash;
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro no login Google: ${result['message']}'),
            backgroundColor: Colors.red.shade600,
          ),
        );
      }
    } catch (e) {
      AppSession.flow = AppAuthFlow.splash;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro no login Google: $e'),
          backgroundColor: Colors.red.shade600,
        ),
      );
    }

    setState(() {});
  }

  //LOGIN COM APPLE
  // =============================================================
  Future<void> _signInWithApple() async {
    AppSession.flow = AppAuthFlow.authenticating;

    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      if (credential.identityToken == null) {
        throw Exception('Apple identity token is null');
      }

      final response = await Supabase.instance.client.auth.signInWithIdToken(
        provider: OAuthProvider.apple,
        idToken: credential.identityToken!,
        accessToken: credential.authorizationCode,
      );

      final user = response.user;

      if (user != null) {
        final fullName =
            [
              credential.givenName,
              credential.familyName,
            ].whereType<String>().where((e) => e.isNotEmpty).join(' ').trim();

        // ⚡ Só salva o nome se ele existir (primeiro login)
        if (fullName.isNotEmpty) {
          await Supabase.instance.client.from('profiles').upsert({
            'id': user.id,
            'email': user.email,
            'full_name': fullName,
            'profile_type': 'standard',
            'created_at': DateTime.now().toIso8601String(),
          });
        }
      }
    } catch (e) {
      AppSession.flow = AppAuthFlow.splash;
      if (kDebugMode) {
        debugPrint('Apple login error: $e');
      }
    }

    setState(() {});
  }

  // =============================================================
  // UI
  // =============================================================
  @override
  Widget build(BuildContext context) {
    // ✅ BLOQUEIO VISUAL DURANTE LOGIN COM GOOGLE
    if (AppSession.isAuthenticating) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final isTablet = MediaQuery.of(context).size.shortestSide >= 600;
    final maxWidth = isTablet ? 520.0 : double.infinity;

    return Scaffold(
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Container(
          width: double.infinity,
          height: double.infinity,
          color: const Color(0xFFF8DCE0),
          child: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 20,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(height: isTablet ? 80 : 60),

                        // LOGO
                        Column(
                          children: [
                            Text(
                              'MY YEAR',
                              style: GoogleFonts.cinzel(
                                fontSize: isTablet ? 60 : 42,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFFA66ABD),
                              ),
                            ),
                            Text(
                              'MY STORY',
                              style: GoogleFonts.cinzel(
                                fontSize: isTablet ? 60 : 42,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFFA66ABD),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 32),

                        // 🔁 TOGGLE RESTAURADO (SEM OVERFLOW)
                        _buildToggle(isTablet),

                        const SizedBox(height: 40),

                        CustomTextField(
                          controller: _emailController,
                          labelText: 'auth.login.email'.tr(),
                          prefixIcon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                        ),

                        const SizedBox(height: 20),

                        CustomTextField(
                          controller: _passwordController,
                          labelText: 'auth.login.password'.tr(),
                          prefixIcon: Icons.lock_outline,
                          obscureText: true,
                        ),

                        const SizedBox(height: 20),

                        _buildRememberAndForgot(),

                        const SizedBox(height: 24),

                        AuthButton(
                          text: 'auth.login.button'.tr(),
                          isLoading: _isLoading,
                          onPressed: _signIn,
                          backgroundColor: const Color(0xFFE2377D),
                        ),

                        const SizedBox(height: 28),

                        _buildOAuthButtons(isTablet),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // =============================================================
  // TOGGLE (CORRIGIDO)
  // =============================================================
  Widget _buildToggle(bool isTablet) {
    return Container(
      height: isTablet ? 70 : 55,
      decoration: BoxDecoration(
        color: const Color(0xFFF3E6F7),
        borderRadius: BorderRadius.circular(40),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final itemWidth = constraints.maxWidth / 2;

          return Stack(
            children: [
              AnimatedAlign(
                alignment:
                    _isLoginSelected
                        ? Alignment.centerLeft
                        : Alignment.centerRight,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: Container(
                  width: itemWidth,
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2377D),
                    borderRadius: BorderRadius.circular(40),
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _isLoginSelected = true),
                      child: Center(
                        child: Text(
                          'auth.login.sign_in'.tr(),
                          style: TextStyle(
                            fontSize: isTablet ? 22 : 18,
                            fontWeight: FontWeight.w600,
                            color:
                                _isLoginSelected
                                    ? Colors.white
                                    : Colors.black87,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        // 🔥 Sai explicitamente do modo guest
                        AppSession.flow = AppAuthFlow.splash;

                        setState(() => _isLoginSelected = false);
                        widget.onCreateAccountTap();
                      },

                      child: Center(
                        child: Text(
                          'auth.login.create_account'.tr(),
                          style: TextStyle(
                            fontSize: isTablet ? 22 : 18,
                            fontWeight: FontWeight.w600,
                            color:
                                !_isLoginSelected
                                    ? Colors.white
                                    : Colors.black87,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  // =============================================================
  // REMEMBER + FORGOT
  // =============================================================
  Widget _buildRememberAndForgot() {
    return Row(
      children: [
        Checkbox(
          value: _rememberMe,
          onChanged: (v) => setState(() => _rememberMe = v ?? false),
          activeColor: const Color(0xFFE2377D),
        ),
        Text('auth.login.remember_me'.tr()),
        const Spacer(),
        GestureDetector(
          onTap:
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
              ),
          child: Text(
            'auth.login.forgot_password'.tr(),
            style: const TextStyle(decoration: TextDecoration.underline),
          ),
        ),
      ],
    );
  }

  // =============================================================
  // =============================================================
  // OAUTH SECTION
  // =============================================================
  Widget _buildOAuthButtons(bool isTablet) {
    return Column(
      children: [
        Row(
          children: [
            const Expanded(
              child: Divider(thickness: 1, color: Color(0xFFE4D8EB)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                'ou',
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: isTablet ? 16 : 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Expanded(
              child: Divider(thickness: 1, color: Color(0xFFE4D8EB)),
            ),
          ],
        ),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, constraints) {
            final gap = constraints.maxWidth < 360 ? 8.0 : 12.0;
            return Row(
              children: [
                Expanded(child: _buildGoogleButton(isTablet)),
                SizedBox(width: gap),
                Expanded(child: _buildAppleButton(isTablet)),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildGoogleButton(bool isTablet) {
    return OutlinedButton(
      onPressed: _signInWithGoogle,
      style: OutlinedButton.styleFrom(
        backgroundColor: Colors.white,
        padding: EdgeInsets.symmetric(vertical: isTablet ? 16 : 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: const BorderSide(color: Color(0xFFE4D8EB)),
      ),
      child:
          _isGoogleLoading
              ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
              : FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      "assets/icons/google_icon.png",
                      height: isTablet ? 26 : 20,
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      "Google",
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
    );
  }

  Widget _buildAppleButton(bool isTablet) {
    return OutlinedButton(
      onPressed: _signInWithApple,
      style: OutlinedButton.styleFrom(
        backgroundColor: Colors.black,
        padding: EdgeInsets.symmetric(vertical: isTablet ? 16 : 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.apple, color: Colors.white),
            const SizedBox(width: 10),
            const Text(
              "Apple",
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
