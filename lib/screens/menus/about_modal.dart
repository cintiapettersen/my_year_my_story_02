import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:google_fonts/google_fonts.dart';

class AboutAppScreen extends StatelessWidget {
  const AboutAppScreen({super.key});

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
          // Fundo rosa premium
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

          // CONTEÚDO
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 140),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(34),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 34,
                    horizontal: 28,
                  ),
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
                      // Ícone fofo
                      Container(
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.55),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withOpacity(0.8),
                            width: 1,
                          ),
                        ),
                        child: const Icon(
                          Icons.auto_awesome_rounded,
                          color: Color.fromARGB(255, 232, 100, 190),
                          size: 46,
                        ),
                      ),

                      const SizedBox(height: 26),

                      // Nome
                      Text(
                        "My Year, My Story",
                        style: TextStyle(
                          fontSize: 22,
                          color: const Color(0xFF4A266A),
                          fontWeight: FontWeight.w700,
                        ),
                      ),

                      const SizedBox(height: 18),

                      // Descrição
                      Text(
                        "about.description".tr(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 15.5,
                          height: 1.38,
                        ),
                      ),

                      const SizedBox(height: 30),

                      // Versão
                      Text(
                        "about.version".tr(),
                        style: TextStyle(
                          color: const Color(0xFF4A266A).withOpacity(0.7),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),

                      const SizedBox(height: 26),

                      // Contato
                      Text(
                        "about.contact".tr(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFF4A266A),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
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
}
