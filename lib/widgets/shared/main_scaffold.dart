import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:myyearmystory/widgets/shared/app_bottom_menu.dart';

class MainScaffold extends StatelessWidget {
  final int? currentIndex; // AGORA OPCIONAL 💕
  final Widget body;
  final String? title;

  const MainScaffold({
    super.key,
    this.currentIndex, // opcional
    required this.body,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    final bool showBottomMenu = currentIndex != null;

    return Scaffold(
      backgroundColor: const Color(0xFFFCE9EF),
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: const Color(0xFFE91E63),
        elevation: 0,
        title: Text(
          title ?? 'My Year, My Story',
          style: GoogleFonts.cinzel(
            textStyle: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20,
              letterSpacing: 0.5,
            ),
          ),
        ),
        leading: Navigator.of(context).canPop()
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              )
            : null,
      ),

      // conteúdo principal
      body: SafeArea(child: body),

      // 🔥 MOSTRA O MENU APENAS SE currentIndex NÃO FOR nulo
      bottomNavigationBar: currentIndex != null 
    ? AppBottomMenu(currentIndex: currentIndex)
    : null,

    );
  }
}
