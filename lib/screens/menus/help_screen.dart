import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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

      body: Container(
        width: double.infinity,
        height: double.infinity,

        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF9E9FF),
              Color(0xFFFFF4F8),
            ],
          ),
        ),

        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 40),

              child: ClipRRect(
                borderRadius: BorderRadius.circular(34),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),

                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 34, horizontal: 28),

                    width: double.infinity,
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
                      mainAxisSize: MainAxisSize.min,
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
                            Icons.help_outline_rounded,
                            color: Color.fromARGB(255, 158, 119, 205),
                            size: 44,
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Título
                        Text(
                          "help.title".tr(),
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            color: const Color.fromARGB(255, 89, 58, 127),
                          ),
                        ),

                        const SizedBox(height: 10),

                        // Sub
                        Text(
                          "help.subtitle".tr(),
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),

                        const SizedBox(height: 28),

                        Container(
                          height: 1.2,
                          width: double.infinity,
                          color: Colors.white.withOpacity(0.8),
                        ),

                        const SizedBox(height: 28),

                        // Itens
                        _helpItem(Icons.star_outline_rounded, "help.faq".tr()),
                        _helpItem(Icons.mail_outline_rounded, "help.contact".tr()),

                        const SizedBox(height: 34),

                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            "help.button".tr(),
                            style: GoogleFonts.inter(
                              color: Colors.black54,
                              fontSize: 15,
                            ),
                          ),
                        ),
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

  Widget _helpItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 22, color: Color.fromARGB(255, 158, 119, 205)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 15.5,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
