import 'package:flutter/material.dart';

/// 🌸 Transição personalizada com fade + zoom suave.
/// Mantém o estilo delicado e poético do app My Year, My Story.
Route fadePageTransition(Widget page) {
  return PageRouteBuilder(
    transitionDuration: const Duration(milliseconds: 900),
    reverseTransitionDuration: const Duration(milliseconds: 700),
    pageBuilder: (_, __, ___) => page,
    transitionsBuilder: (_, animation, __, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve:Curves.easeInOut,
      );

      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.98, end: 1.0).animate(curved),
          child: child,
        ),
      );
    },
  );
}
