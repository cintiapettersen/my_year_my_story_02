import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:myyearmystory/utils/access_control.dart';




class PremiumPage extends StatelessWidget {
  const PremiumPage({super.key});

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
                        // 🌟 ÍCONE PREMIUM
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

                        const SizedBox(height: 28),
// 🌟 TÍTULO
                        Text(
                          "premium.app_name".tr(),
                          textAlign: TextAlign.center,
                          style: GoogleFonts.montserrat(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: const Color.fromARGB(255, 158, 119, 205),
                          ),
                        ),

                        const SizedBox(height: 10),
                        
                        // 🌟 TÍTULO
                        Text(
                          "premium.title".tr(),
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: const Color.fromARGB(255, 89, 58, 127),
                          ),
                        ),

                        const SizedBox(height: 10),

                        // ✨ FRASE PRINCIPAL
                        Text(
                          "premium.main_phrase".tr(),
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 17,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),

                        const SizedBox(height: 8),

                        Text(
                          "premium.sub_phrase".tr(),
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                            color: Colors.black54,
                          ),
                        ),

                        const SizedBox(height: 28),

                        // DIVISOR PREMIUM
                        Container(
                          height: 1.2,
                          width: double.infinity,
                          color: Colors.white.withOpacity(0.8),
                        ),

                        const SizedBox(height: 28),

                        // 🌟 BENEFÍCIOS
                        _benefit(Icons.favorite_rounded, "premium.benefit1".tr(), Color(0xFFFF4FA3)),
_benefit(Icons.favorite_rounded, "premium.benefit2".tr(), Color.fromARGB(255, 227, 176, 202)),
_benefit(Icons.favorite_rounded, "premium.benefit3".tr(), Color.fromARGB(255, 214, 218, 86)),
_benefit(Icons.favorite_rounded, "premium.benefit4".tr(), Color.fromARGB(255, 124, 151, 224)),
_benefit(Icons.favorite_rounded, "premium.benefit5".tr(), Color.fromARGB(255, 196, 139, 227)),
_benefit(Icons.favorite_rounded, "premium.benefit6".tr(), Color.fromARGB(255, 224, 129, 175)),
_benefit(Icons.favorite_rounded, "premium.benefit7".tr(), Color.fromARGB(255, 209, 86, 183)),
_benefit(Icons.favorite_rounded, "premium.benefit8".tr(), Color.fromARGB(255, 162, 139, 226)),
_benefit(Icons.favorite_rounded, "premium.benefit9".tr(), Color.fromARGB(255, 234, 90, 138)),
                        const SizedBox(height: 36),

                        // 🌟 BOTÃO PREMIUM
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color.fromARGB(255, 223, 97, 164),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 4,
                            ),
                            onPressed: () => Navigator.pop(context),
                            child: Text(
                              "premium.button".tr(),
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 14),

                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            "premium.later".tr(),
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

  // Widget benefício
  Widget _benefit(IconData icon, String text, Color color) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 15.5,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
              height: 1.3,
            ),
          ),
        ),
      ],
    ),
  );
}

}