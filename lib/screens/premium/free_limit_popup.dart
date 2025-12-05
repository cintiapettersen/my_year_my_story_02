import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:myyearmystory/screens/premium/premium_popup.dart';
import 'package:easy_localization/easy_localization.dart';


void showFreeLimitPopup(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (_) {
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 254, 231, 231),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.favorite,
                size: 42,
                color: Color(0xFFA84ABF),
              ),
              const SizedBox(height: 14),

              Text(
                "dailyLuck.freeLimitTitle".tr(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 14),
              Text(
               "dailyLuck.freeLimitText".tr(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 22),

              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  showPremiumPopup(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFA84ABF),
                  padding: const EdgeInsets.symmetric(
                      vertical: 12, horizontal: 28),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  "dailyLuck.freeLimitButtonPremium".tr(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ),

              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  "dailyLuck.freeLimitButtonCancel".tr(),
                  style: GoogleFonts.robotoMono(
                    fontSize: 13,
                    color: Colors.black54,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
