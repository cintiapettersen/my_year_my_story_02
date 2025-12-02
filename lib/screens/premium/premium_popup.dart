import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:myyearmystory/screens/premium/premium_page.dart';

Future<void> showPremiumPopup(BuildContext context) async {
  showDialog(
    context: context,
    builder: (context) {
      return Stack(
        children: [
          AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
            ),
            contentPadding: const EdgeInsets.fromLTRB(24, 32, 24, 20),
            backgroundColor: const Color(0xFFFFF1F6),

            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.favorite,
                  size: 42,
                  color: Color(0xFFB03062),
                ),

                const SizedBox(height: 12),

                Text(
                  "premium_popup.title".tr(),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFB03062),
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 14),

                Text(
                  "premium_popup.message".tr(),
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.4,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 26),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                     Navigator.pop(context); // fecha o popup

                      // evita abrir a PremiumPage se já estivermos nela
                      if (context.widget is PremiumPage) return;

                       Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PremiumPage()),
                      );
                      },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFCD4B78),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      "premium_popup.upgrade_button".tr(),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          Positioned(
            right: 6,
            top: 6,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.grey),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      );
    },
  );
}
