// lib/screens/auth/complete_profile_screen.dart
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:myyearmystory/widgets/auth/custom_text_field.dart';
import 'package:myyearmystory/widgets/auth/auth_button.dart';
import 'package:myyearmystory/screens/splash/fade_page_transition.dart';
import 'package:myyearmystory/screens/dashboard/dashboard_screen.dart';

class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _birthDateController = TextEditingController();

  DateTime? _selectedDate;
  bool _isLoading = false;

  final supabase = Supabase.instance.client;

  @override
  void dispose() {
    _nameController.dispose();
    _birthDateController.dispose();
    super.dispose();
  }

  // 📅 Seleção da data
  Future<void> _pickDate() async {
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

  // 💾 Salvar informações no Supabase
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final user = supabase.auth.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      await supabase.from("profiles").update({
        "full_name": _nameController.text.trim(),
        "birth_date": _selectedDate != null
            ? DateFormat("yyyy-MM-dd").format(_selectedDate!)
            : null,
      }).eq("id", user.id);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("profile.completed".tr()),
          backgroundColor: Colors.green,
        ),
      );

      await Future.delayed(const Duration(milliseconds: 500));

      Navigator.pushAndRemoveUntil(
        context,
        fadePageTransition(
          DashboardScreen(
            month: DateTime.now().month,
            year: DateTime.now().year,
          ),
        ),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("profile.error".tr(args: [e.toString()])),
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
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFFDE7EA), Color(0xFFF8DCE0)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const SizedBox(height: 40),

                    // Título
                    Text(
                      'MY YEAR',
                      style: GoogleFonts.cinzel(
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFA66ABD),
                        height: 1.1,
                        letterSpacing: 1.5,
                      ),
                      textAlign: TextAlign.center,
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
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 20),

                    Text(
                      "complete_profile.subtitle".tr(),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: 16,
                        height: 1.4,
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Nome
                    CustomTextField(
                      controller: _nameController,
                      labelText: "signup.full_name".tr(),
                      prefixIcon: Icons.person_outline,
                      validator: (v) =>
                          v == null || v.trim().isEmpty
                              ? "signup.error_name".tr()
                              : null,
                    ),

                    const SizedBox(height: 16),

                    // Data de nascimento
                    TextFormField(
                      controller: _birthDateController,
                      readOnly: true,
                      onTap: _pickDate,
                      decoration: InputDecoration(
                        labelText: "signup.birth_date".tr(),
                        prefixIcon: const Icon(Icons.cake, color: Color(0xFFA66ABD)),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      validator: (_) => _selectedDate == null
                          ? "signup.error_birth".tr()
                          : null,
                    ),

                    const SizedBox(height: 32),

                    AuthButton(
                      text: "complete_profile.button".tr(),
                      isLoading: _isLoading,
                      onPressed: _saveProfile,
                      backgroundColor: const Color(0xFFA66ABD),
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
