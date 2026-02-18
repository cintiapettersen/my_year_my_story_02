import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:myyearmystory/widgets/auth/custom_text_field.dart';
import 'package:myyearmystory/widgets/auth/auth_button.dart';
import 'package:myyearmystory/services/app_session.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

 Future<void> _updatePassword() async {
  if (!_formKey.currentState!.validate()) return;

  setState(() => _isLoading = true);

  try {
    // 🔑 Atualiza a senha
    await Supabase.instance.client.auth.updateUser(
      UserAttributes(
        password: _passwordController.text,
      ),
    );

    if (!mounted) return;

    // 🔴 MUITO IMPORTANTE:
    // encerra a sessão de recovery
    await Supabase.instance.client.auth.signOut();

    // 🔁 reseta o estado global da app
    AppSession.flow = AppAuthFlow.splash;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
      content: Text('auth.reset.success'.tr()),
        backgroundColor: Colors.green,
      ),
    );

    // ⏳ delay curto só pra UX
    await Future.delayed(const Duration(milliseconds: 600));

    // ✅ força login REAL
    context.go('/login');
  } catch (e) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('auth.reset.error'.tr()),
        backgroundColor: Colors.red,
      ),
    );
  } finally {
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }
}



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8DCE0),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8DCE0),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.lock_reset,
                      size: 64,
                      color: Color(0xFFE2377D),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'auth.reset.title'.tr(),
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall!
                          .copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'auth.reset.subtitle'.tr(),
                      textAlign: TextAlign.center,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium!
                          .copyWith(color: Colors.black54),
                    ),
                    const SizedBox(height: 32),

                    // 🔑 Nova senha
                    CustomTextField(
                      controller: _passwordController,
                      labelText: 'auth.reset.password'.tr(),
                      prefixIcon: Icons.lock_outline,
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'auth.reset.validate_required'.tr();
                        }
                        if (value.length < 6) {
                          return 'auth.reset.validate_short'.tr();
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // 🔁 Confirmar senha
                    CustomTextField(
                      controller: _confirmController,
                      labelText: 'auth.reset.confirm'.tr(),
                      prefixIcon: Icons.lock_outline,
                      obscureText: true,
                      validator: (value) {
                        if (value != _passwordController.text) {
                          return 'auth.reset.validate_mismatch'.tr();
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 32),

                    AuthButton(
                      text: 'auth.reset.button'.tr(),
                      isLoading: _isLoading,
                      backgroundColor: const Color(0xFFE2377D),
                      onPressed: _updatePassword,
                    ),
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
