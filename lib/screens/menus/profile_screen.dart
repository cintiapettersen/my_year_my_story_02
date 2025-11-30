import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:myyearmystory/supabase/supabase_config.dart';
import 'package:myyearmystory/services/profile_service.dart';


class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController birthDateController = TextEditingController();

  final birthMask = MaskTextInputFormatter(
    mask: '##/##/####',
    filter: {"#": RegExp(r'[0-9]')},
  );

  DateTime? selectedBirthDate;
  String selectedEmoji = "🌸";
  String planType = "Free Plan";
  final profileService = ProfileService();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  // -------------------------------------------------------
  // LOAD PROFILE
  // -------------------------------------------------------
  Future<void> _loadProfile() async {
    final user = SupabaseConfig.client.auth.currentUser;
    if (user == null) return;

    final response = await SupabaseConfig.client
        .from('profiles')
        .select('full_name, email, birth_date, avatar_emoji, is_premium')
        .eq('id', user.id)
        .maybeSingle();

    if (response != null) {
      nameController.text = response['full_name'] ?? '';
      emailController.text = response['email'] ?? '';
      selectedEmoji = response['avatar_emoji'] ?? "🌸";

      planType =
          (response["is_premium"] == true) ? "Premium Plan" : "Free Plan";

      if (response['birth_date'] != null) {
        selectedBirthDate = DateTime.parse(response['birth_date']);
        birthDateController.text = formatDisplayDate(selectedBirthDate!);
      }

      setState(() {});
    }
  }

  // -------------------------------------------------------
  // SAVE PROFILE
  // -------------------------------------------------------
  Future<void> _saveProfile() async {
    final user = SupabaseConfig.client.auth.currentUser;

    if (user == null) return;

    // Converter data
    if (birthDateController.text.isNotEmpty) {
      try {
        final p = birthDateController.text.split('/');
        selectedBirthDate = DateTime(
          int.parse(p[2]),
          int.parse(p[1]),
          int.parse(p[0]),
        );
      } catch (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Data inválida."),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    // Atualizar perfil no banco
    await SupabaseConfig.client.from('profiles').update({
      "full_name": nameController.text.trim(),
      "email": emailController.text.trim(),
      if (selectedBirthDate != null)
        "birth_date": selectedBirthDate!.toIso8601String().split("T")[0],
    }).eq('id', user.id);

    // Atualizar Local
    profileService.updateLocal({
      "full_name": nameController.text.trim(),
      "email": emailController.text.trim(),
      "birth_date": selectedBirthDate?.toIso8601String(),
    });

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Perfil atualizado!"),
        backgroundColor: Colors.green,
      ),
    );
  }

  // -------------------------------------------------------
  // FORMAT DATE
  // -------------------------------------------------------
  String formatDisplayDate(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}/"
        "${date.month.toString().padLeft(2, '0')}/"
        "${date.year}";
  }

  // -------------------------------------------------------
  // SIGNO & IDADE
  // -------------------------------------------------------
  String calcularIdade(DateTime birth) {
    final now = DateTime.now();
    int idade = now.year - birth.year;

    if (now.month < birth.month ||
        (now.month == birth.month && now.day < birth.day)) {
      idade--;
    }
    return idade.toString();
  }

  String descobrirSigno(DateTime d) {
    final dia = d.day, mes = d.month;

    if ((mes == 3 && dia >= 21) || (mes == 4 && dia <= 19)) return "Áries";
    if ((mes == 4 && dia >= 20) || (mes == 5 && dia <= 20)) return "Touro";
    if ((mes == 5 && dia >= 21) || (mes == 6 && dia <= 20)) return "Gêmeos";
    if ((mes == 6 && dia >= 21) || (mes == 7 && dia <= 22)) return "Câncer";
    if ((mes == 7 && dia >= 23) || (mes == 8 && dia <= 22)) return "Leão";
    if ((mes == 8 && dia >= 23) || (mes == 9 && dia <= 22)) return "Virgem";
    if ((mes == 9 && dia >= 23) || (mes == 10 && dia <= 22)) return "Libra";
    if ((mes == 10 && dia >= 23) || (mes == 11 && dia <= 21)) return "Escorpião";
    if ((mes == 11 && dia >= 22) || (mes == 12 && dia <= 21)) return "Sagitário";
    if ((mes == 12 && dia >= 22) || (mes == 1 && dia <= 19)) return "Capricórnio";
    if ((mes == 1 && dia >= 20) || (mes == 2 && dia <= 18)) return "Aquário";
    return "Peixes";
  }

  // -------------------------------------------------------
  // DATE PICKER
  // -------------------------------------------------------
  Future<void> _pickDate() async {
    FocusScope.of(context).unfocus();

    final now = DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: selectedBirthDate ?? DateTime(1990, 1, 1),
      firstDate: DateTime(1900),
      lastDate: now,
      initialEntryMode: DatePickerEntryMode.calendarOnly,
      builder: (_, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Colors.pinkAccent,
              onPrimary: Colors.white,
              surface: Color(0xFF1F1F40),
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: const Color(0xFF1F1F40),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        selectedBirthDate = picked;
        birthDateController.text = formatDisplayDate(picked);
      });
    }
  }

  // -------------------------------------------------------
  // UI
  // -------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "Meu Perfil",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),

      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF2C2F66), Color(0xFF1B1C3A)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 120),
            child: Column(
              children: [
                _buildHeader(),
                const SizedBox(height: 40),

                _glassInput(
                  icon: Icons.person_outline,
                  controller: nameController,
                  label: "Nome completo",
                ),

                const SizedBox(height: 22),

                _glassInput(
                  icon: Icons.cake_outlined,
                  controller: birthDateController,
                  label: tr("profile.birth_date"),
                  readOnly: true,
                  keyboardType: TextInputType.none,
                  inputFormatters: [birthMask],
                  onTap: _pickDate,
                ),

                const SizedBox(height: 22),

                _glassInput(
  icon: Icons.email_outlined,
  controller: emailController,
  label: tr("profile.email"),
  readOnly: true,
  onTap: () {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.pinkAccent.withOpacity(0.9),
        content: Text(
          tr("profile.email_change_alert"),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
          ),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  },
),


                const SizedBox(height: 40),

                _saveButton(),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------
  // HEADER CARD
  // -------------------------------------------------------
  Widget _buildHeader() {
    final idade =
        selectedBirthDate != null ? calcularIdade(selectedBirthDate!) : "-";

    final signo =
        selectedBirthDate != null ? descobrirSigno(selectedBirthDate!) : "-";

    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 22),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.10),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withOpacity(0.25)),
          ),
          child: Column(
            children: [
              /// avatar escolhido no drawer (supabase)
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.15),
                  border: Border.all(color: Colors.white.withOpacity(0.35)),
                ),
                child: Text(
                  selectedEmoji,
                  style: const TextStyle(fontSize: 44),
                ),
              ),

              const SizedBox(height: 16),

              Text(
                nameController.text.isEmpty
                    ? "Seu nome"
                    : nameController.text,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                planType,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),

              const SizedBox(height: 14),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.auto_awesome,
                      color: Colors.white, size: 16),
                  const SizedBox(width: 6),
                  Text(signo,
                      style:
                          const TextStyle(fontSize: 16, color: Colors.white)),
                  const SizedBox(width: 18),
                  const Icon(Icons.cake_outlined,
                      color: Colors.white, size: 14),
                  const SizedBox(width: 6),
                  Text("$idade anos",
                      style:
                          const TextStyle(fontSize: 16, color: Colors.white)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------
  // SAVE BUTTON
  // -------------------------------------------------------
  Widget _saveButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: LinearGradient(
          colors: [
            Colors.pinkAccent.withOpacity(0.6),
            Colors.pink.shade300.withOpacity(0.6),
          ],
        ),
      ),
      child: TextButton(
        onPressed: _saveProfile,
        child: const Text(
          "Salvar",
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------
  // GLASS INPUT
  // -------------------------------------------------------
  Widget _glassInput({
    required IconData icon,
    required TextEditingController controller,
    required String label,
    bool readOnly = false,
    VoidCallback? onTap,
    List<TextInputFormatter>? inputFormatters,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      readOnly: readOnly,
      onTap: onTap,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      cursorColor: Colors.white,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 16,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: Colors.white.withOpacity(0.55),
          fontSize: 15,
        ),
        prefixIcon: Icon(icon, color: Colors.white.withOpacity(0.85)),
        filled: true,
        fillColor: Colors.white.withOpacity(0.10),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide:
              BorderSide(color: Colors.white.withOpacity(0.25), width: 1.3),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: const BorderSide(color: Colors.white, width: 1.5),
        ),
      ),
    );
  }
}
