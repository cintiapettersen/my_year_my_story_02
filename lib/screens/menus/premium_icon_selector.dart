import 'dart:ui';
import 'package:flutter/material.dart';

Future<String?> showPremiumIconSelector(BuildContext context) async {
  final icons = ["🌸", "⭐", "💎", "👑"];

  return showDialog<String>(
    context: context,
    barrierColor: Colors.black38,
    builder: (context) {
      return Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
            child: Container(
              width: 260,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18),
                border: Border.all(
                  color: Colors.white.withOpacity(0.4),
                  width: 1.2,
                ),
                borderRadius: BorderRadius.circular(26),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Escolha seu ícone",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 17,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: icons.map((e) {
                      return GestureDetector(
                        onTap: () => Navigator.pop(context, e),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            e,
                            style: const TextStyle(fontSize: 28),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}
