import 'dart:ui';
import 'package:flutter/material.dart';

void showAboutAppModal(BuildContext context) {
  showDialog(
    context: context,
    barrierColor: Colors.black38,
    builder: (context) {
      return Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
            child: Container(
              width: 300,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                border: Border.all(
                  color: Colors.white.withOpacity(0.4),
                  width: 1.3,
                ),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "My Year, My Story",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    "Um diário interativo para você registrar memórias, sentimentos e momentos especiais ao longo do ano.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "Versão 1.0.0",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 25),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.25),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text("Fechar"),
                    onPressed: () => Navigator.pop(context),
                  )
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}
