import 'package:flutter/material.dart';
import 'package:my_year_my_story/screens/auth/login_screen.dart';
import 'package:my_year_my_story/screens/splash/fade_page_transition.dart';

/// 🌸 Mostra um aviso gentil pedindo login ao tentar usar recursos do banco.
/// Pode ser chamado em qualquer lugar:
/// `showLoginPrompt(context);`
Future<void> showLoginPrompt(BuildContext context) async {
  // 🔒 Garante que o contexto usado tenha um MaterialApp acima
  BuildContext safeContext = context;
  try {
    safeContext = Navigator.of(context, rootNavigator: true).context;
  } catch (_) {
    // fallback, se o contexto não tiver Navigator ainda
  }

  await showDialog(
    context: safeContext,
    barrierDismissible: true,
    builder: (context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Faça login 💫',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            color: Color(0xFF665C8E),
          ),
        ),
        content: const Text(
          'Para salvar suas metas e continuar acompanhando suas conquistas, entre ou crie uma conta.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 15,
          ),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Agora não',
              style: TextStyle(
                color: Colors.grey,
                fontFamily: 'Poppins',
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(); // fecha o diálogo
              Navigator.of(context).pushReplacement(
                fadePageTransition(const LoginScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFC03B66),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text(
              'Fazer login',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins',
              ),
            ),
          ),
        ],
      );
    },
  );
}
