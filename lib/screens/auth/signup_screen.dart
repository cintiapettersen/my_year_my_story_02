// lib/screens/auth/signup_screen.dart
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:myyearmystory/widgets/auth/custom_text_field.dart';
import 'package:myyearmystory/widgets/auth/auth_button.dart';
import 'package:myyearmystory/widgets/auth/divider_with_text.dart';
import 'package:myyearmystory/services/user_service.dart';
import 'package:go_router/go_router.dart';

class SignupScreen extends StatefulWidget {
  final VoidCallback? onLoginTap;

  const SignupScreen({super.key, this.onLoginTap});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _birthDateController = TextEditingController();

  DateTime? _selectedDate;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _birthDateController.dispose();
    super.dispose();
  }

  // 📅 Seleção da data
  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000, 1, 1),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      locale: context.locale,
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _birthDateController.text =
            DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  // 📝 Cadastro
  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final response = await UserService.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        name: _nameController.text.trim(),
        birthDate: _selectedDate != null
            ? DateFormat('yyyy-MM-dd').format(_selectedDate!)
            : null,
      );

      if (!mounted) return;

      // ❌ ERRO
      if (response['success'] != true) {
        final message = response['message'];

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              // 👇 só traduz se for chave
              message is String && message.contains('.')
                  ? message.tr()
                  : message.toString(),
            ),
            backgroundColor: Colors.red,
          ),
        );

        setState(() => _isLoading = false);
        return;
      }

      // ✅ SUCESSO
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('signup.success'.tr()),
          backgroundColor: Colors.green,
        ),
      );

      await Future.delayed(const Duration(milliseconds: 600));

      context.go('/login');
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('signup.error'.tr()),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width >= 600;
    final maxWidth = isTablet ? 520.0 : double.infinity;

    return Scaffold(
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFFDE7EA), Color(0xFFF8DCE0)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? 40 : 24,
                  vertical: 20,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(height: isTablet ? 60 : 40),

                        // 🔙 Voltar
                        Align(
                          alignment: Alignment.centerLeft,
                          child: IconButton(
                            icon: Icon(
                              Icons.arrow_back_ios,
                              color: const Color(0xFFA66ABD),
                              size: isTablet ? 30 : 22,
                            ),
                            onPressed: widget.onLoginTap ??
                                () {
                                  context.go('/login');
                                },
                          ),
                        ),

                        SizedBox(height: isTablet ? 30 : 16),

                        // LOGO
                        Text(
                          'MY YEAR',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.cinzel(
                            fontSize: isTablet ? 70 : 42,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFA66ABD),
                            height: 1.05,
                            letterSpacing: 1.5,
                          ),
                        ),
                        Text(
                          'MY STORY',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.cinzel(
                            fontSize: isTablet ? 70 : 42,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFA66ABD),
                            height: 1.05,
                            letterSpacing: 1.5,
                          ),
                        ),

                        SizedBox(height: isTablet ? 30 : 16),

                        Text(
                          'signup.subtitle'.tr(),
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge!
                              .copyWith(
                                color: Colors.black87,
                                height: 1.4,
                                fontSize: isTablet ? 20 : 16,
                              ),
                        ),

                        SizedBox(height: isTablet ? 60 : 40),

                        // 👤 Nome
                        CustomTextField(
                          controller: _nameController,
                          labelText: context.tr('signup.full_name'),
                          prefixIcon: Icons.person_outline,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'signup.error_name_required'.tr();
                            }
                            if (value.trim().length < 2) {
                              return 'signup.error_name_short'.tr();
                            }
                            return null;
                          },
                        ),

                        SizedBox(height: isTablet ? 24 : 16),

                        // 🎂 Data
                        TextFormField(
                          controller: _birthDateController,
                          readOnly: true,
                          onTap: () => _pickDate(context),
                          decoration: InputDecoration(
                            hintText: 'signup.birth_date'.tr(),
                            prefixIcon: const Icon(
                              Icons.cake,
                              color: Color(0xFFA66ABD),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          validator: (_) => _selectedDate == null
                              ? 'signup.error_birth'.tr()
                              : null,
                        ),

                        SizedBox(height: isTablet ? 24 : 16),

                        // 📧 Email
                        CustomTextField(
                          controller: _emailController,
                          labelText: 'signup.email'.tr(),
                          prefixIcon: Icons.email_outlined,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'signup.error_email_required'.tr();
                            }
                            final emailRegex =
                                RegExp(r'^[^@]+@[^@]+\.[^@]+');
                            if (!emailRegex.hasMatch(value.trim())) {
                              return 'signup.error_email_invalid'.tr();
                            }
                            return null;
                          },
                        ),

                        SizedBox(height: isTablet ? 24 : 16),

                        // 🔒 Senha
                        CustomTextField(
                          controller: _passwordController,
                          labelText: 'signup.password'.tr(),
                          prefixIcon: Icons.lock_outline,
                          obscureText: true,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'signup.error_password_required'.tr();
                            }
                            if (value.length < 6) {
                              return 'signup.error_password_short'.tr();
                            }
                            return null;
                          },
                        ),

                        SizedBox(height: isTablet ? 24 : 16),

                        // 🔁 Confirmar senha
                        CustomTextField(
                          controller: _confirmPasswordController,
                          labelText: 'signup.confirm_password'.tr(),
                          prefixIcon: Icons.lock_outline,
                          obscureText: true,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'signup.error_confirm_password_required'
                                  .tr();
                            }
                            if (value != _passwordController.text) {
                              return 'signup.error_password_mismatch'.tr();
                            }
                            return null;
                          },
                        ),

                        SizedBox(height: isTablet ? 36 : 24),

                        AuthButton(
                          text: 'signup.button_create'.tr(),
                          isLoading: _isLoading,
                          onPressed: _signUp,
                          backgroundColor: const Color(0xFFA66ABD),
                        ),

                        SizedBox(height: isTablet ? 36 : 24),

                        DividerWithText(text: 'signup.or'.tr()),

                        SizedBox(height: isTablet ? 36 : 24),

                        Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'signup.bio_info'.tr(),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.black54,
                              height: 1.5,
                              fontSize: isTablet ? 18 : 14,
                            ),
                          ),
                        ),

                        SizedBox(height: isTablet ? 40 : 32),

                        TextButton(
                          onPressed: widget.onLoginTap ??
                              () {
                                context.go('/login');
                              },
                          child: Text(
                            'signup.have_account'.tr(),
                            style: TextStyle(
                              color: const Color(0xFFA66ABD),
                              fontWeight: FontWeight.w600,
                              fontSize: isTablet ? 20 : 16,
                            ),
                          ),
                        ),

                        SizedBox(height: isTablet ? 60 : 32),
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
}
