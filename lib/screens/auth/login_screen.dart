import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:myyearmystory/theme.dart';
import 'package:myyearmystory/widgets/auth/custom_text_field.dart';
import 'package:myyearmystory/widgets/auth/auth_button.dart';
import 'package:myyearmystory/services/user_service.dart';
import 'package:myyearmystory/screens/auth/forgot_password_screen.dart';
import 'package:myyearmystory/screens/dashboard/dashboard_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:myyearmystory/screens/splash/fade_page_transition.dart';
import 'package:myyearmystory/screens/auth/signup_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:myyearmystory/services/google_auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _rememberMe = false;
  bool _isLoginSelected = true;
  bool _isGoogleLoading = false;

  @override
  void initState() {
    super.initState();
    _loadRememberedEmail();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // =============================================================
  // REMEMBER ME
  // =============================================================
  Future<void> _loadRememberedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('remembered_email');
    final pass = prefs.getString('remembered_password');
    final remember = prefs.getBool('remember_me') ?? false;

    if (email != null) {
      _emailController.text = email;
      setState(() => _rememberMe = remember);

      if (remember && pass != null) {
        _passwordController.text = pass;
      }
    }
  }

  Future<void> _saveRememberedCredentials() async {
    final prefs = await SharedPreferences.getInstance();

    if (_rememberMe) {
      await prefs.setString('remembered_email', _emailController.text.trim());
      await prefs.setString('remembered_password', _passwordController.text);
      await prefs.setBool('remember_me', true);
    } else {
      await prefs.remove('remembered_email');
      await prefs.remove('remembered_password');
      await prefs.setBool('remember_me', false);
    }
  }

  // =============================================================
  // SYNC LANGUAGE
  // =============================================================
  Future<void> syncUserLanguage() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final currentLang = context.locale.languageCode;

    try {
      await Supabase.instance.client
          .from('profiles')
          .update({'language': currentLang})
          .eq('id', user.id);
    } catch (_) {}
  }

  // =============================================================
  // EMAIL LOGIN
  // =============================================================
  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    FocusScope.of(context).unfocus();

    final response = await UserService.signIn(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );

    if (!mounted) return;

    if (response['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("auth.login.success".tr()),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 1),
        ),
      );

      await _saveRememberedCredentials();
      await syncUserLanguage();

      Navigator.of(context).pushReplacement(
        fadePageTransition(
          DashboardScreen(
            month: DateTime.now().month,
            year: DateTime.now().year,
          ),
        ),
      );
    } else {
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
    setState(() => _isGoogleLoading = true);

    final result = await GoogleAuthService.signInWithGoogle();

    if (!mounted) return;
    setState(() => _isGoogleLoading = false);

    if (result['success'] == true) {
      await syncUserLanguage();

      Navigator.of(context).pushReplacement(
        fadePageTransition(
          DashboardScreen(
            month: DateTime.now().month,
            year: DateTime.now().year,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // =============================================================
  // UI
  // =============================================================
  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.shortestSide >= 600;
    final maxWidth = isTablet ? 520.0 : double.infinity;

    return Scaffold(
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(color: Color(0xFFF8DCE0)),
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
                                height: 1.05,
                                letterSpacing: 1.5,
                              ),
                            ),
                            Text(
                              'MY STORY',
                              style: GoogleFonts.cinzel(
                                fontSize: isTablet ? 60 : 42,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFFA66ABD),
                                height: 1.05,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // SUBTITLE
                        Text(
                          'auth.login.description'.tr(),
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                                color: Colors.black87,
                                height: 1.4,
                                fontSize: isTablet ? 20 : 16,
                              ),
                        ),

                        const SizedBox(height: 48),

                        // Toggle Entrar / Criar Conta
                        _buildToggle(isTablet),

                        const SizedBox(height: 40),

                        // FIELDS
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

                        // LOGIN BUTTON
                        AuthButton(
                          text: 'auth.login.button'.tr(),
                          isLoading: _isLoading,
                          onPressed: _signIn,
                          backgroundColor: LightModeColors.lightSecondary,
                        ),

                        const SizedBox(height: 20),

                        // GOOGLE BUTTON
                        _buildGoogleButton(isTablet),

                        SizedBox(height: isTablet ? 80 : 40),
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
  // TOGGLE
  // =============================================================
  Widget _buildToggle(bool isTablet) {
    return Container(
      height: isTablet ? 70 : 55,
      decoration: BoxDecoration(
        color: const Color(0xFFF3E6F7),
        borderRadius: BorderRadius.circular(40),
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            alignment: _isLoginSelected
                ? Alignment.centerLeft
                : Alignment.centerRight,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: Container(
              width: 200,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: LightModeColors.lightSecondary,
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
                        color: _isLoginSelected ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() => _isLoginSelected = false);
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const SignupScreen(),
                      ),
                    );
                  },
                  child: Center(
                    child: Text(
                      'auth.login.create_account'.tr(),
                      style: TextStyle(
                        fontSize: isTablet ? 22 : 18,
                        fontWeight: FontWeight.w600,
                        color: !_isLoginSelected ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // =============================================================
  // REMEMBER + FORGOT PASSWORD
  // =============================================================
  Widget _buildRememberAndForgot() {
    return Row(
      children: [
        Checkbox(
          value: _rememberMe,
          onChanged: (v) => setState(() => _rememberMe = v ?? false),
          activeColor: LightModeColors.lightSecondary,
        ),
        Text(
          'auth.login.remember_me'.tr(),
          style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                color: LightModeColors.lightOnSurface.withValues(alpha: 0.7),
              ),
        ),
        const Spacer(),
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
          ),
          child: Text(
            'auth.login.forgot_password'.tr(),
            style: TextStyle(
              color: LightModeColors.lightSecondary,
              fontWeight: FontWeight.w600,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }

  // =============================================================
  // GOOGLE BUTTON
  // =============================================================
  Widget _buildGoogleButton(bool isTablet) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: _isGoogleLoading ? null : _signInWithGoogle,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          side: const BorderSide(color: Colors.black12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: EdgeInsets.symmetric(
            vertical: isTablet ? 20 : 12,
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
                  SizedBox(width: isTablet ? 20 : 12),
                  Text(
                    "Continue with Google",
                    style: TextStyle(
                      fontSize: isTablet ? 20 : 16,
                      color: Colors.black87,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
