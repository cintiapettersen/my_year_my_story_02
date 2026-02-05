import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:myyearmystory/supabase/supabase_config.dart';
import 'package:myyearmystory/services/profile_service.dart';
import 'package:google_fonts/google_fonts.dart';

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

      planType = (response["is_premium"] == true)
          ? "profile.premium_plan".tr()
          : "profile.free_plan".tr();

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

    // Converte data
    if (birthDateController.text.isNotEmpty) {
      final p = birthDateController.text.split('/');
      selectedBirthDate = DateTime(
        int.parse(p[2]),
        int.parse(p[1]),
        int.parse(p[0]),
      );
    }

    await SupabaseConfig.client.from('profiles').update({
      "full_name": nameController.text.trim(),
      "email": emailController.text.trim(),
      if (selectedBirthDate != null)
        "birth_date": selectedBirthDate!.toIso8601String().split("T")[0],
    }).eq('id', user.id);

    profileService.updateLocal({
      "full_name": nameController.text.trim(),
      "email": emailController.text.trim(),
      "birth_date": selectedBirthDate?.toIso8601String(),
    });

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("profile.updated".tr()),
        backgroundColor: Colors.pinkAccent.withOpacity(0.8),
      ),
    );

    if (!mounted) return;

   // 🔥 avisa o Dashboard que algo mudou
   Navigator.pop(context, true);   
  }


// DELETAR CONTA-------------------------------------------------------

void _confirmDeleteAccount() {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(tr("profile.delete_account_title")),
      content: Text(tr("profile.delete_account_description")),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(tr("common.cancel")),
        ),
       TextButton(
  onPressed: () async {
    Navigator.pop(context);
    await _deleteAccount();
  },
  style: TextButton.styleFrom(
    foregroundColor: Colors.red,
  ),
  child: Text(tr("profile.delete_account_confirm")),
),

      ],
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

    if ((mes == 3 && dia >= 21) || (mes == 4 && dia <= 19)) return "sign.aries";
    if ((mes == 4 && dia >= 20) || (mes == 5 && dia <= 20)) return "sign.taurus";
    if ((mes == 5 && dia >= 21) || (mes == 6 && dia <= 20)) return "sign.gemini";
    if ((mes == 6 && dia >= 21) || (mes == 7 && dia <= 22)) return "sign.cancer";
    if ((mes == 7 && dia >= 23) || (mes == 8 && dia <= 22)) return "sign.leo";
    if ((mes == 8 && dia >= 23) || (mes == 9 && dia <= 22)) return "sign.virgo";
    if ((mes == 9 && dia >= 23) || (mes == 10 && dia <= 22)) return "sign.libra";
    if ((mes == 10 && dia >= 23) || (mes == 11 && dia <= 21)) return "sign.scorpio";
    if ((mes == 11 && dia >= 22) || (mes == 12 && dia <= 21)) return "sign.sagittarius";
    if ((mes == 12 && dia >= 22) || (mes == 1 && dia <= 19)) return "sign.capricorn";
    if ((mes == 1 && dia >= 20) || (mes == 2 && dia <= 18)) return "sign.aquarius";

    return "sign.pisces";
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
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFE15C8C),
              onPrimary: Colors.white,
              onSurface: Color(0xFF4A266A),
            ),
            dialogBackgroundColor: Color(0xFFF9E9FF),
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
  // DELETE ACCOUNT
  // -------------------------------------------------------
Future<void> _deleteAccount() async {
  // 1️⃣ Mostrar feedback visual
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(tr("profile.delete_account_coming_soon")),
      backgroundColor: Colors.redAccent.withOpacity(0.9),
    ),
  );

  // 🚧 A exclusão real será implementada depois
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
  backgroundColor: const Color(0xFFE3B1FC),
  elevation: 0,
  centerTitle: true,

  iconTheme: const IconThemeData(
    color: Color(0xFF4B3768), // cor da seta!
  ),

  title: Text(
   "language.app_name".tr(),
      style: GoogleFonts.montserrat(
      fontWeight: FontWeight.w700,
      fontSize: 18,
      color: const Color(0xFF4B3768),
    ),
  ),
),

      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFF9E9FF), Color(0xFFFFF4F8)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 140),
            child: Column(
              children: [
                _buildHeader(),
                const SizedBox(height: 40),

                _glassInput(
                  icon: Icons.person_outline,
                  controller: nameController,
                  label: "profile.full_name".tr(),
                ),

                const SizedBox(height: 22),

                _glassInput(
                  icon: Icons.cake_outlined,
                  controller: birthDateController,
                  label: "profile.birth_date".tr(),
                  readOnly: true,
                  keyboardType: TextInputType.none,
                  inputFormatters: [birthMask],
                  onTap: _pickDate,
                ),

                const SizedBox(height: 22),

                _glassInput(
                  icon: Icons.email_outlined,
                  controller: emailController,
                  label: "profile.email".tr(),
                  readOnly: true,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: Colors.purple.shade300,
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

const SizedBox(height: 40),
Divider(
  color: Colors.purple.withOpacity(0.2),
),

const SizedBox(height: 20),

GestureDetector(
  onTap: _confirmDeleteAccount,
  child: Text(
    tr("profile.delete_account"),
    style: TextStyle(
      color: Colors.redAccent.withOpacity(0.85),
      fontSize: 14,
      fontWeight: FontWeight.w500,
      decoration: TextDecoration.underline,
    ),
  ),
),

const SizedBox(height: 80),

              ],
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------
  // HEADER — estilo Premium Page
  // -------------------------------------------------------
  Widget _buildHeader() {
    final idade =
        selectedBirthDate != null ? calcularIdade(selectedBirthDate!) : "-";

    final signo =
        selectedBirthDate != null ? descobrirSigno(selectedBirthDate!) : "-";

    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 22),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.45),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withOpacity(0.85)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF9B59B6).withOpacity(0.12),
                blurRadius: 28,
                offset: const Offset(0, 12),
              )
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.55),
                  border: Border.all(color: Colors.white.withOpacity(0.8)),
                ),
                child: Text(
                  selectedEmoji,
                  style: const TextStyle(fontSize: 46),
                ),
              ),

              const SizedBox(height: 16),

              Text(
                nameController.text.isEmpty
                    ? "profile.full_name".tr()
                    : nameController.text,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4A266A),
                ),
              ),

              const SizedBox(height: 4),

              Text(
                planType,
                style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFF7A5BBC),
                ),
              ),

              const SizedBox(height: 14),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.auto_awesome,
                      color: Color(0xFF4A266A), size: 16),
                  const SizedBox(width: 6),
                  Text(
                    signo.tr(),
                    style: const TextStyle(
                        fontSize: 16, color: Color(0xFF4A266A)),
                  ),
                  const SizedBox(width: 18),
                  const Icon(Icons.cake_outlined,
                      color: Color(0xFF4A266A), size: 14),
                  const SizedBox(width: 6),
                  Text(
                    "$idade ${tr("profile.years")}",
                    style: const TextStyle(
                        fontSize: 16, color: Color(0xFF4A266A)),
                  ),
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
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [
            Color(0xFFE066A6),
            Color(0xFFDA82C2),
          ],
        ),
      ),
      child: TextButton(
        onPressed: _saveProfile,
        child: Text(
          "profile.save_button".tr(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 17,
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
      cursorColor: const Color(0xFF4A266A),
      style: const TextStyle(
        color: Color(0xFF4A266A),
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: const Color(0xFF4A266A).withOpacity(0.55),
          fontSize: 15,
        ),
        prefixIcon: Icon(icon, color: const Color(0xFF4A266A)),
        filled: true,
        fillColor: Colors.white.withOpacity(0.45),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide:
              BorderSide(color: Colors.white.withOpacity(0.65), width: 1.3),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: const BorderSide(color: Color(0xFF4A266A), width: 1.5),
        ),
      ),
    );
  }
}
