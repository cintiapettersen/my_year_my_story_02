// lib/screens/auth/signup_screen.dart
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:myyearmystory/theme.dart';
import 'package:myyearmystory/widgets/auth/custom_text_field.dart';
import 'package:myyearmystory/widgets/auth/auth_button.dart';
import 'package:myyearmystory/widgets/auth/divider_with_text.dart';
import 'package:myyearmystory/services/user_service.dart';
import 'package:myyearmystory/screens/auth/auth_page_view.dart';
import 'package:myyearmystory/screens/splash/fade_page_transition.dart';

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
  final TextEditingController _confirmPasswordController = TextEditingController();
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

  // 📅 Seleção da data de nascimento
  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000, 1, 1),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      locale: context.locale,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFA66ABD),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            dialogBackgroundColor: Color(0xFFF8EAF6),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _birthDateController.text = DateFormat('dd/MM/yyyy').format(picked);
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

      if (response['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('signup.success'.tr()),
            backgroundColor: Colors.green,
          ),
        );

        await Future.delayed(const Duration(milliseconds: 600));

        Navigator.of(context).pushReplacement(
          fadePageTransition(const AuthPageView()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'].tr()),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('signup.error'.tr(args: [e.toString()])),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
    body: GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isTablet = constraints.maxWidth >= 600;
          final maxWidth = isTablet ? 520.0 : double.infinity;

          return Container(
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

                          // -----------------------------------------------------
                          // BOTÃO VOLTAR
                          // -----------------------------------------------------
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
                                    Navigator.pushReplacement(
                                      context,
                                      fadePageTransition(
                                          const AuthPageView()),
                                    );
                                  },
                            ),
                          ),

                          SizedBox(height: isTablet ? 30 : 16),

                          // -----------------------------------------------------
                          // LOGO
                          // -----------------------------------------------------
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

                          // -----------------------------------------------------
                          // CAMPOS
                          // -----------------------------------------------------
                          CustomTextField(
                            controller: _nameController,
                            labelText: 'signup.full_name'.tr(),
                            prefixIcon: Icons.person_outline,
                          ),

                          SizedBox(height: isTablet ? 24 : 16),

                          TextFormField(
                            controller: _birthDateController,
                            readOnly: true,
                            onTap: () => _pickDate(context),
                            style: TextStyle(
                              fontSize: isTablet ? 20 : 16,
                            ),
                            decoration: InputDecoration(
                              labelText: 'signup.birth_date'.tr(),
                              labelStyle:
                                  TextStyle(fontSize: isTablet ? 20 : 16),
                              prefixIcon: Icon(
                                Icons.cake,
                                color: Color(0xFFA66ABD),
                                size: isTablet ? 28 : 22,
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

                          CustomTextField(
                            controller: _emailController,
                            labelText: 'signup.email'.tr(),
                            prefixIcon: Icons.email_outlined,
                          ),

                          SizedBox(height: isTablet ? 24 : 16),

                          CustomTextField(
                            controller: _passwordController,
                            labelText: 'signup.password'.tr(),
                            prefixIcon: Icons.lock_outline,
                            obscureText: true,
                          ),

                          SizedBox(height: isTablet ? 24 : 16),

                          CustomTextField(
                            controller: _confirmPasswordController,
                            labelText: 'signup.confirm_password'.tr(),
                            prefixIcon: Icons.lock_outline,
                            obscureText: true,
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
                                  Navigator.pushReplacement(
                                    context,
                                    fadePageTransition(
                                        const AuthPageView()),
                                  );
                                },
                            child: Text(
                              'signup.have_account'.tr(),
                              style: TextStyle(
                                color: Color(0xFFA66ABD),
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
          );
        },
      ),
    ),
  );
}
}