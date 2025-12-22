import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

import 'package:myyearmystory/screens/auth/login_screen.dart';
import 'package:myyearmystory/screens/splash/fade_page_transition.dart';

/// 🌸 Mostra um aviso pedindo login ao tentar usar recursos protegidos.
/// Pode ser chamado em qualquer lugar:
/// `showLoginPrompt(context);`
Future<void> showLoginPrompt(BuildContext context) async {
  // 🔒 Garante um contexto seguro com Navigator
  BuildContext safeContext = context;
  try {
    safeContext = Navigator.of(context, rootNavigator: true).context;
  } catch (_) {}

  await showDialog(
    context: safeContext,
    barrierDismissible: true,
    builder: (dialogContext) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'auth.login_prompt.title'.tr(),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            color: Color(0xFF665C8E),
          ),
        ),
        content: Text(
          'auth.login_prompt.description'.tr(),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 15,
          ),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              'auth.login_prompt.not_now'.tr(),
              style: const TextStyle(
                color: Colors.grey,
                fontFamily: 'Poppins',
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop(); // fecha o diálogo

              Navigator.of(context).pushReplacement(
                fadePageTransition(
                  LoginScreen(
                    onCreateAccountTap: () {
                      Navigator.of(context).pushNamed('/signup');
                    },
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFC03B66),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 12,
              ),
            ),
            child: Text(
              'auth.login_prompt.login_button'.tr(),
              style: const TextStyle(
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
