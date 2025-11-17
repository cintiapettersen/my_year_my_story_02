import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:myyearmystory/screens/auth/login_screen.dart';
import 'package:myyearmystory/screens/premium/premium_page.dart';

void showPremiumPrompt(BuildContext context, {int? month, int? year}) {
  final user = Supabase.instance.client.auth.currentUser;
  final bool isGuest = user == null;

  // 🧁 Textos traduzidos
  final String title = tr('premium_popup.title');
  final String message = tr('premium_popup.message');
  final String primaryButtonText =
      isGuest ? tr('actions.login') : tr('premium_popup.upgrade_button');

  // 🧁 Ação do botão principal
  void primaryButtonAction() {
    Navigator.pop(context);
    if (isGuest) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => PremiumPage()),
      );
    }
  }

  // ✨ Popup animado
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Premium Prompt',
    transitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (context, animation1, animation2) {
      return const SizedBox.shrink();
    },

    transitionBuilder: (context, animation1, animation2, child) {
      final curvedValue = Curves.easeInOut.transform(animation1.value) - 1.0;

      return Transform(
        transform: Matrix4.translationValues(0.0, curvedValue * -50, 0.0),
        child: Opacity(
          opacity: animation1.value,

          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            backgroundColor: const Color(0xFFFFEEF1),

            contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 24),

            content: ConstrainedBox(
              constraints: const BoxConstraints(
                maxHeight: 400,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.favorite,
                      color: Color(0xFFC03B66),
                      size: 48,
                    ),
                    const SizedBox(height: 12),

                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFC03B66),
                        letterSpacing: 0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 16),

                    Text(
                      message,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFF4F4F4F),
                        height: 1.6,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 26),

                    // ⭐ Botões — SEM OVERFLOW
                    Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(
                              tr('premium_popup.cancel'),
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 8),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFC03B66),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              shadowColor:
                                  const Color(0xFFC03B66).withOpacity(0.3),
                              elevation: 3,
                            ),
                            onPressed: primaryButtonAction,
                            child: Text(
                              primaryButtonText,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
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
          ),
        ),
      );
    },
  );
}
