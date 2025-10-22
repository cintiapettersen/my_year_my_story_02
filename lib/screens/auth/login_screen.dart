import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_year_my_story/theme.dart';
import 'package:my_year_my_story/widgets/auth/custom_text_field.dart';
import 'package:my_year_my_story/widgets/auth/auth_button.dart';
import 'package:my_year_my_story/widgets/auth/divider_with_text.dart';
import 'package:my_year_my_story/services/user_service.dart';
import 'package:my_year_my_story/screens/auth/forgot_password_screen.dart';
import 'package:my_year_my_story/screens/dashboard/dashboard_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_year_my_story/screens/splash/fade_page_transition.dart';
import 'package:my_year_my_story/screens/auth/signup_screen.dart';

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
  bool _isGoogleLoading = false;
  bool _isLoginSelected = true; // 👈 novo: controla o botão ativo

  @override
  void initState() {
    super.initState();
    _loadRememberedEmail();

    // Preenche automaticamente em modo debug
    if (!kReleaseMode) {
      _emailController.text = 'teste@myyear.com';
      _passwordController.text = '123456';
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadRememberedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    final rememberedEmail = prefs.getString('remembered_email');
    final rememberedPassword = prefs.getString('remembered_password');
    final shouldRemember = prefs.getBool('remember_me') ?? false;

    if (rememberedEmail != null) {
      _emailController.text = rememberedEmail;
      setState(() => _rememberMe = shouldRemember);

      if (shouldRemember &&
          rememberedPassword != null &&
          rememberedPassword.isNotEmpty) {
        _passwordController.text = rememberedPassword;
        await Future.delayed(const Duration(milliseconds: 300));
        _performAutoLogin();
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

  Future<void> _signIn() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      FocusScope.of(context).unfocus();

      try {
        final response = await UserService.signIn(
          _emailController.text.trim(),
          _passwordController.text,
        );

        if (!mounted) return;

        if (response['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Login realizado com sucesso!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 1),
            ),
          );
          await _saveRememberedCredentials();

          await Future.delayed(const Duration(milliseconds: 500));
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
              content: Text(response['message']),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao fazer login: $e')),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _performAutoLogin() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final response = await UserService.signIn(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (mounted && response['success']) {
        await Future.delayed(const Duration(milliseconds: 500));
        Navigator.of(context).pushReplacement(
          fadePageTransition(
            DashboardScreen(
              month: DateTime.now().month,
              year: DateTime.now().year,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('remembered_password');
        await prefs.setBool('remember_me', false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro no auto-login: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isGoogleLoading = true);

    try {
      final response = await UserService.signInWithGoogle();

      if (mounted) {
        if (response['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Login com Google realizado com sucesso!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 1),
            ),
          );

          await Future.delayed(const Duration(milliseconds: 500));
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
              content: Text(response['message'] ?? 'Erro ao entrar com Google.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao fazer login com Google: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(color: Color(0xFFF8DCE0)),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 60),

                    // LOGO
                    Column(
                      children: [
                        Text(
                          'MY YEAR',
                          style: GoogleFonts.cinzel(
                            fontSize: 42,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFA66ABD),
                            height: 1.1,
                            letterSpacing: 1.5,
                          ),
                        ),
                        Text(
                          'MY STORY',
                          style: GoogleFonts.cinzel(
                            fontSize: 42,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFA66ABD),
                            height: 1.1,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'Capture suas memórias, acompanhe seus humores e conte sua história única através dos meses.',
                        style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                          color: Colors.black87,
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                    const SizedBox(height: 48),

                    // 🌸 Toggle animado entre Entrar / Criar Conta
                    Container(
                      height: 55,
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
                              width: MediaQuery.of(context).size.width * 0.4,
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              decoration: BoxDecoration(
                                color: LightModeColors.lightSecondary,
                                borderRadius: BorderRadius.circular(40),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.15),
                                    blurRadius: 5,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() => _isLoginSelected = true);
                                  },
                                  child: Center(
                                    child: Text(
                                      'Entrar',
                                      style: TextStyle(
                                        fontSize: 18,
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
                                    setState(() => _isLoginSelected = false);
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) =>
                                        const SignupScreen(),
                                      ),
                                    );
                                  },
                                  child: Center(
                                    child: Text(
                                      'Criar Conta',
                                      style: TextStyle(
                                        fontSize: 18,
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
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Campos de login
                    CustomTextField(
                      controller: _emailController,
                      labelText: 'Email',
                      prefixIcon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor, insira seu email';
                        }
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                            .hasMatch(value)) {
                          return 'Por favor, insira um email válido';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 20),

                    CustomTextField(
                      controller: _passwordController,
                      labelText: 'Senha',
                      prefixIcon: Icons.lock_outline,
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor, insira sua senha';
                        }
                        if (value.length < 6) {
                          return 'A senha deve ter pelo menos 6 caracteres';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 20),

                    Row(
                      children: [
                        Checkbox(
                          value: _rememberMe,
                          onChanged: (value) =>
                              setState(() => _rememberMe = value ?? false),
                          activeColor: LightModeColors.lightSecondary,
                          visualDensity: VisualDensity.compact,
                        ),
                        Text(
                          'Lembrar de mim',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium!
                              .copyWith(
                            color: LightModeColors.lightOnSurface
                                .withValues(alpha: 0.7),
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                              const ForgotPasswordScreen(),
                            ),
                          ),
                          child: Text(
                            'Esqueci a senha?',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium!
                                .copyWith(
                              color: LightModeColors.lightSecondary,
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    AuthButton(
                      text: 'Entrar',
                      isLoading: _isLoading,
                      onPressed: _signIn,
                      backgroundColor: LightModeColors.lightSecondary,
                    ),

                    const SizedBox(height: 24),

                    const DividerWithText(text: 'OU'),

                    const SizedBox(height: 24),

                    AuthButton(
                      text: 'Entrar com Google',
                      icon: Icons.account_circle,
                      isOutlined: true,
                      isLoading: _isGoogleLoading,
                      onPressed: _signInWithGoogle,
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
