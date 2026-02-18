import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';

void showLoginPrompt(BuildContext context) {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Login Prompt',
    transitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (_, __, ___) => const SizedBox.shrink(),
    transitionBuilder: (context, animation1, animation2, child) {
      final curvedValue =
          Curves.easeInOut.transform(animation1.value) - 1.0;

      return Transform(
        transform: Matrix4.translationValues(0.0, curvedValue * -50, 0.0),
        child: Opacity(
          opacity: animation1.value,
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            backgroundColor: const Color(0xFFFFEEF1), // 💕 fundo rosinha
            insetPadding: const EdgeInsets.symmetric(horizontal: 24),
            contentPadding:
                const EdgeInsets.fromLTRB(24, 24, 24, 28),
            content: Stack(
              children: [
                // ❌ Botão fechar no canto
                Positioned(
                  top: -8,
                  right: -8,
                  child: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),

                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 🔐 ÍCONE
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFFFFE6EF),
                      ),
                      child: const Icon(
                        Icons.lock_outline,
                        color: Color(0xFFC03B66),
                        size: 36,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // 🏷️ TÍTULO
                    Text(
                      tr('popup_login.required_title'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFC03B66),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // 💬 MENSAGEM
                    Text(
                      tr('popup_login.required_description'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 15,
                        height: 1.4,
                        color: Color(0xFF4F4F4F),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // ✅ BOTÃO PRINCIPAL (FULL WIDTH)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFC03B66),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 3,
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          context.push('/login');
                        },
                        child: Text(
                          tr('popup_login.login_button'),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
