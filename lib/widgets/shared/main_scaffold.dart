import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_year_my_story/widgets/shared/app_bottom_menu.dart';

class MainScaffold extends StatelessWidget {
  final int currentIndex;
  final Widget body;
  final String? title; // ← título opcional 💕

  const MainScaffold({
    super.key, // simplifica a passagem da key
    required this.currentIndex,
    required this.body,
    this.title, // ← adiciona aqui também pra inicializar
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCE9EF), // 💕 rosa clarinho padrão
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: const Color(0xFFE91E63), // rosa forte do logo
        elevation: 0,
        title: Text(
          title ?? 'My Year, My Story', // usa o título recebido ou o padrão
          style: GoogleFonts.cinzel(
            textStyle: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
      body: SafeArea(child: body),
      bottomNavigationBar: AppBottomMenu(currentIndex: currentIndex),
    );
  }
}
