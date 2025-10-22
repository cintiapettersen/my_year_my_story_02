import 'package:flutter/material.dart';
import 'package:my_year_my_story/theme.dart';
import 'package:my_year_my_story/widgets/auth/custom_text_field.dart';
import 'package:my_year_my_story/widgets/auth/auth_button.dart';
import 'package:my_year_my_story/services/user_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  /// Traduz mensagens do Supabase para português amigável
  String _translateError(String message) {
    if (message.contains('Invalid login credentials') ||
        message.contains('User not found')) {
      return 'E-mail não encontrado. Verifique e tente novamente.';
    } else if (message.contains('email')) {
      return 'Formato de e-mail inválido.';
    } else if (message.contains('rate limit')) {
      return 'Muitos pedidos seguidos. Tente novamente em alguns minutos.';
    } else {
      return 'Ocorreu um erro. Tente novamente mais tarde.';
    }
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    try {
      final response = await UserService.resetPassword(_emailController.text.trim());

      if (!mounted) return;

      if (response['success']) {
        setState(() => _emailSent = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Email de recuperação enviado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_translateError(response['message'] ?? 'Erro desconhecido')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao enviar email: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: LightModeColors.lightOnSurface),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                LightModeColors.gradientStart,
                LightModeColors.gradientEnd,
              ],
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 40),

                    // 🔐 Ícone
                    Icon(
                      Icons.lock_reset,
                      size: 80,
                      color: LightModeColors.lightSecondary.withValues(alpha: 0.8),
                    ),

                    const SizedBox(height: 24),

                    Text(
                      'Esqueceu sua senha?',
                      style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                        color: LightModeColors.lightOnSurface,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 16),

                    if (!_emailSent) ...[
                      Text(
                        'Digite seu email e enviaremos um link para redefinir sua senha.',
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          color: LightModeColors.lightOnSurface.withValues(alpha: 0.7),
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 48),

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

                      const SizedBox(height: 32),

                      AuthButton(
                        text: 'Enviar Link de Recuperação',
                        isLoading: _isLoading,
                        onPressed: _isLoading ? null : _resetPassword,
                        backgroundColor: LightModeColors.lightSecondary,
                      ),
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.green.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.check_circle,
                              size: 48,
                              color: Colors.green,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Email enviado!',
                              style: Theme.of(context).textTheme.titleMedium!.copyWith(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Verifique sua caixa de entrada e siga as instruções para redefinir sua senha.',
                              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                                color: LightModeColors.lightOnSurface
                                    .withValues(alpha: 0.8),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      AuthButton(
                        text: 'Voltar ao Login',
                        isOutlined: true,
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],

                    const SizedBox(height: 48),
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
