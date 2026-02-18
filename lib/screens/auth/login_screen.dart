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

class LoginScreen extends StatefulWidget {
  final VoidCallback onCreateAccountTap;

  const LoginScreen({
    super.key,
    required this.onCreateAccountTap,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}


class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _rememberMe = false;
  bool _isLoginSelected = true; // 🔁 toggle restaurado

  @override
void initState() {
  super.initState();
  _loadRememberedEmail();

  Supabase.instance.client.auth.onAuthStateChange.listen((data) {
    final session = data.session;

    if (session != null) {
      print('🔐 Usuário autenticado');

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/dashboard');

    }
  });
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

    final response = await UserService.signIn(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );

    if (!mounted) return;

    if (response['success'] == true) {
      await _saveRememberedEmail();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('auth.login.success'.tr()),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 1),
        ),
      );
      // ❌ não navega — AuthListener assume
    } else {
      AppSession.flow = AppAuthFlow.splash;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response['message'].toString().tr()),
          backgroundColor: Colors.red,
        ),
      );
    }

    if (mounted) setState(() => _isLoading = false);
  }

  // =============================================================
  // GOOGLE LOGIN
  // =============================================================
  Future<void> _signInWithGoogle() async {
  // 🔔 Marca fluxo
  AppSession.flow = AppAuthFlow.authenticating;

  // ⚠️ NÃO usa loading aqui
  // OAuth mobile não retorna normalmente
  await GoogleAuthService.signInWithGoogle();

  // ❌ NÃO setState
  // ❌ NÃO navega
  // ❌ NÃO faz nada depois disso
  //
  // 👉 AuthListener vai receber signedIn
}



// =============================================================
// APPLE LOGIN
// =============================================================
Future<void> _signInWithApple() async {
  print('🟡 Apple login iniciado');

  try {
    AppSession.flow = AppAuthFlow.authenticating;

    final response =
        await Supabase.instance.client.auth.signInWithOAuth(
  OAuthProvider.apple,
  redirectTo: 'com.myyear.myyearmystory://login-callback',
);


    print('🟢 signInWithApple chamado com sucesso');
    print('🟢 Response: $response');

  } catch (e, stackTrace) {
    print('🔴 ERRO no signInWithApple: $e');
    print(stackTrace);
  }
}


  // =============================================================
  // UI
  // =============================================================
  @override
Widget build(BuildContext context) {
  // ✅ BLOQUEIO VISUAL DURANTE LOGIN COM GOOGLE
  if (AppSession.isAuthenticating) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
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
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
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

const SizedBox(height: 20),

_buildGoogleButton(isTablet),

const SizedBox(height: 14),

_buildAppleButton(isTablet),

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
                alignment: _isLoginSelected
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
                            color: _isLoginSelected
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
                            color: !_isLoginSelected
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
          onTap: () => Navigator.push(
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
  // GOOGLE BUTTON
  // =============================================================
  Widget _buildGoogleButton(bool isTablet) {
    return OutlinedButton(
      onPressed: _signInWithGoogle,
      style: OutlinedButton.styleFrom(
        backgroundColor: Colors.white,
        padding: EdgeInsets.symmetric(vertical: isTablet ? 20 : 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      child: _isGoogleLoading
          ? const SizedBox(
              height: 22,
              width: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  "assets/icons/google_icon.png",
                  height: isTablet ? 32 : 22,
                ),
                const SizedBox(width: 12),
                const Text(
                  "Continue with Google",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
    );
    
  }


// =============================================================
// APPLE BUTTON
// =============================================================
Widget _buildAppleButton(bool isTablet) {
  return OutlinedButton(
    onPressed: _signInWithApple,
    style: OutlinedButton.styleFrom(
      backgroundColor: Colors.black,
      padding: EdgeInsets.symmetric(vertical: isTablet ? 20 : 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.apple, color: Colors.white),
        const SizedBox(width: 12),
        const Text(
          "Continue with Apple",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ],
    ),
  );
}




}
