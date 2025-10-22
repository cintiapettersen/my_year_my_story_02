import 'package:flutter/material.dart';

/// 🌸 Template base Sonho de Papel — Páginas globais
/// Usado para telas gerais (Início, Diário, Fotos, Humor, etc)
class GlobalPageTemplate extends StatelessWidget {
  final String title; // 🌷 Título no AppBar
  final Widget child; // 💫 Conteúdo principal
  final bool showAppBar; // permite esconder AppBar se quiser
  final bool centerTitle;

  const GlobalPageTemplate({
    super.key,
    required this.title,
    required this.child,
    this.showAppBar = true,
    this.centerTitle = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF7FD),

      // 🌈 AppBar global
      appBar: showAppBar
          ? AppBar(
        backgroundColor: const Color(0xFFD8B4FE), // lilás suave
        elevation: 0,
        centerTitle: centerTitle,
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      )
          : null,

      // 🌸 Conteúdo principal
      body: SafeArea(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Color(0x11000000),
                blurRadius: 6,
                offset: Offset(0, -2),
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: child,
          ),
        ),
      ),

      // 🌷 Menu fixo global
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFFE91E63), // rosa Sonho de Papel
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        elevation: 10,
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.pushReplacementNamed(context, '/dashboard');
              break;
            case 1:
              Navigator.pushReplacementNamed(context, '/month');
              break;
            case 2:
              Navigator.pushReplacementNamed(context, '/photos');
              break;
            case 3:
              Navigator.pushReplacementNamed(context, '/diary');
              break;
            case 4:
              Navigator.pushReplacementNamed(context, '/mood');
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'Início',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month),
            label: 'Mês Atual',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.photo_library_outlined),
            label: 'Fotos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book_outlined),
            label: 'Diário',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.mood_outlined),
            label: 'Humor',
          ),
        ],
      ),
    );
  }
}
