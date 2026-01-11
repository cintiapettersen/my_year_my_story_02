import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

import 'package:myyearmystory/screens/auth/login_screen.dart';
import 'package:myyearmystory/screens/splash/fade_page_transition.dart';
import 'package:myyearmystory/screens/auth/auth_page_view.dart';
import 'package:myyearmystory/services/app_session.dart';


/// 🌸 Mostra um aviso pedindo login ao tentar usar recursos protegidos.

Future<void> showLoginPrompt(BuildContext context) async {
  await showDialog(
    context: context,
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
              // 1️⃣ Fecha o diálogo
              Navigator.of(dialogContext).pop();

              // 2️⃣ Sai do modo guest
              AppSession.reset();

              // 3️⃣ Vai para o login
              Navigator.of(context, rootNavigator: true).pushReplacement(
                fadePageTransition(
                  const AuthPageView(),
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
