import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:google_fonts/google_fonts.dart';



class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key});

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  String currentLang = "";

  // ✔️ Método correto para acessar inherited widgets como o EasyLocalization
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    currentLang = context.locale.languageCode; // "pt" ou "en"
  }

  // 🚨 ESTE MÉTODO PRECISA FICAR AQUI — DENTRO DA CLASSE, MAS FORA DO initState/didChangeDependencies
  void changeLang(String langCode) async {
    await context.setLocale(Locale(langCode));
    setState(() => currentLang = langCode);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,

      // 🔹 TOPO PADRONIZADO (igual Sobre o App)
    
appBar: AppBar(
  backgroundColor: const Color(0xFFE3B1FC),
  elevation: 0,
  centerTitle: true,
  iconTheme: const IconThemeData(
    color: Color(0xFF4B3768),
  ),
  title: Text(
    "language.app_name".tr(),
    textAlign: TextAlign.center,
    style: GoogleFonts.montserrat(
      fontWeight: FontWeight.w700,
      fontSize: 18,
      color: const Color(0xFF4B3768),
    ),
  ),
),


      body: Stack(
        children: [
          // Fundo Premium
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFFF9E9FF),
                  Color(0xFFFFF4F8),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // Conteúdo
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 140),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(34),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),

                child: Container(
                  padding: const EdgeInsets.symmetric(
                      vertical: 34, horizontal: 28),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.45),
                    borderRadius: BorderRadius.circular(34),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.85),
                      width: 1.4,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF9B59B6).withOpacity(0.12),
                        blurRadius: 30,
                        offset: const Offset(0, 14),
                      ),
                    ],
                  ),

                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Ícone
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.55),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withOpacity(0.8),
                            width: 1,
                          ),
                        ),
                        child: const Icon(
                           Icons.translate,
                          size: 42,
                          color: Color(0xFF4A266A),
                        ),
                      ),

                      const SizedBox(height: 22),

                      Text(
                        "language.title".tr(),
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF4A266A),
                        ),
                      ),

                      const SizedBox(height: 10),

                      Text(
                        "language.subtitle".tr(),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.black.withOpacity(0.70),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // 🔹 Separador
                      Container(
                        height: 1.2,
                        width: double.infinity,
                        color: Colors.white.withOpacity(0.8),
                      ),

                      const SizedBox(height: 28),

                      // opções de idioma
                      _langOption("language.portuguese".tr(), "pt"),
                      const SizedBox(height: 16),
                      _langOption("language.english".tr(), "en"),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _langOption(String label, String langCode) {
    final selected = currentLang == langCode;

    return GestureDetector(
      onTap: () => changeLang(langCode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(selected ? 0.55 : 0.30),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? const Color(0xFF4A266A)
                : Colors.white.withOpacity(0.5),
            width: selected ? 2.2 : 1.3,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected ? const Color(0xFF4A266A) : Colors.black54,
              size: 22,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: selected
                    ? const Color(0xFF4A266A)
                    : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
