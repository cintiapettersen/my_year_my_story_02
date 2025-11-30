import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class PremiumButtonGlass extends StatefulWidget {
  final VoidCallback onTap;

  const PremiumButtonGlass({super.key, required this.onTap});

  @override
  State<PremiumButtonGlass> createState() => _PremiumButtonGlassState();
}

class _PremiumButtonGlassState extends State<PremiumButtonGlass>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulse = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _pulse,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: const Color.fromARGB(255, 228, 181, 197).withOpacity(0.5),
              width: 1.8,
            ),
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.30),
                Colors.pink.shade50.withOpacity(0.40),
                Colors.white.withOpacity(0.12),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: widget.onTap,
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("", style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 6),
                  Text(
                    "drawer.go_premium".tr(),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: const Color.fromARGB(255, 185, 18, 152),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
