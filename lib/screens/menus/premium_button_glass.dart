import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class PremiumButtonGlass extends StatefulWidget {
  final VoidCallback onTap;
  final bool isPremium;

  const PremiumButtonGlass({
    super.key,
    required this.onTap,
    required this.isPremium,
  });

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
    );

    _pulse = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    if (!widget.isPremium) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant PremiumButtonGlass oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isPremium && _controller.isAnimating) {
      _controller.stop();
    } else if (!widget.isPremium && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
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
      child: GestureDetector(
        onTap: widget.isPremium ? null : widget.onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.symmetric(
  vertical: 10,
  horizontal: 18,
),
          decoration: BoxDecoration(
  borderRadius: BorderRadius.circular(30),

  // efeito glass
  color: widget.isPremium
      ? Colors.white.withOpacity(0.18)
      : Colors.white.withOpacity(0.12),

  border: Border.all(
    color: Colors.white.withOpacity(0.25),
  ),

  boxShadow: [
    BoxShadow(
      color: Colors.black.withOpacity(0.08),
      blurRadius: 18,
      offset: const Offset(0, 10),
    ),
  ],
),

alignment: Alignment.center,

child: Row(
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
    if (widget.isPremium) ...[
      const Icon(
        Icons.workspace_premium,
        color: Colors.white,
        size: 18,
      ),
      const SizedBox(width: 8),
    ],
    Text(
      widget.isPremium
          ? tr("drawer.premium_active")
          : tr("drawer.premium_cta"),
      style: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w700,
        fontSize: 16,
      ),
    ),
  ],
),
         
        ),
      ),
    );
  }
}