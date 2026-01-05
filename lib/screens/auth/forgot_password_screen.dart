import 'package:flutter/material.dart';
import 'package:myyearmystory/theme.dart';
import 'package:myyearmystory/widgets/auth/custom_text_field.dart';
import 'package:myyearmystory/widgets/auth/auth_button.dart';
import 'package:myyearmystory/services/user_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:easy_localization/easy_localization.dart';

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

  // -------------------------------------------------------------------------
  // 🔍 VERIFICA SE O EMAIL EXISTE NA TABELA PROFILES
  // -------------------------------------------------------------------------
  Future<bool> _emailExists(String email) async {
    try {
      final result = await Supabase.instance.client
          .from('profiles')
          .select('id')
          .eq('email', email.trim())
          .maybeSingle();

      return result != null;
    } catch (_) {
      return false;
    }
  }

  // -------------------------------------------------------------------------
  // 🔄 RESET PASSWORD
  // -------------------------------------------------------------------------
  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    FocusScope.of(context).unfocus();

    final email = _emailController.text.trim();

    try {
      final exists = await _emailExists(email);

      if (!exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('auth.forgot.not_found'.tr()),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final response = await UserService.resetPassword(email);

      if (response['success']) {
        setState(() => _emailSent = true);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('auth.forgot.sent'.tr()),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('auth.forgot.error'.tr()),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${'auth.forgot.error_general'.tr()}: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // -------------------------------------------------------------------------
  // 🌈 UI (SEM FUNDO PRETO!)
  // -------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8DCE0),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8DCE0),
        elevation: 0,
        leading: IconButton(
  icon: const Icon(
    Icons.arrow_back_ios,
    color: Colors.black,
  ),
  onPressed: () => Navigator.pop(context),
),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 40),

                  Icon(
                    Icons.lock_reset,
                    size: 80,
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.8),
                  ),

                  

                  const SizedBox(height: 24),

                  Text(
                    'auth.forgot.title'.tr(),
                    style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                          color: Colors.black,

                          fontWeight: FontWeight.bold,
                        ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 16),

                  if (!_emailSent) ...[
                    Text(
                      'auth.forgot.subtitle'.tr(),
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium!
                          .copyWith(
  color: Colors.black.withOpacity(0.7),
),

                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 40),

                    CustomTextField(
                      controller: _emailController,
                      labelText: 'auth.forgot.email'.tr(),
                      prefixIcon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'auth.forgot.validate_empty'.tr();
                        }
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                            .hasMatch(value)) {
                          return 'auth.forgot.validate_invalid'.tr();
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 32),

                    AuthButton(
                      text: 'auth.forgot.button'.tr(),
                      isLoading: _isLoading,
                      onPressed: _resetPassword,
                      backgroundColor: const Color(0xFFE2377D),
                    ),
                  ],

                  if (_emailSent) ...[
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: Colors.green.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.check_circle,
                              size: 48, color: Colors.green),
                          const SizedBox(height: 16),
                          Text(
                            'auth.forgot.success_title'.tr(),
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium!
                                .copyWith(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'auth.forgot.success_desc'.tr(),
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium!
                                .copyWith(
                                  color: Colors.black87,
                                ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    AuthButton(
                      text: 'auth.forgot.back'.tr(),
                      isOutlined: true,
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
