import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

void showComingSoonPrompt(BuildContext context) {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Coming Soon Prompt',
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
            backgroundColor: const Color(0xFFFFEEF1), // 💕 fundo rosinha suave
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.access_time,
                  color: Color(0xFFC03B66),
                  size: 48,
                ),
                const SizedBox(height: 12),
                Text(
                  tr('coming_soon_popup.title'), // "Feature coming soon"
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
                  tr('coming_soon_popup.message'), // "This feature will be available soon! Stay tuned 💕"
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF4F4F4F),
                    height: 1.6,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFC03B66),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 36, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    shadowColor: Colors.pinkAccent.withOpacity(0.3),
                    elevation: 3,
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    tr('coming_soon_popup.button'), // "Got it"
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
