import 'package:flutter/material.dart';

class AppPillButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;

  final Color backgroundColor;
  final Color foregroundColor;
  final BorderSide? side;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final double elevation;
  final bool expand;
  final TextStyle? textStyle;
  final Color? shadowColor;

  const AppPillButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.backgroundColor = const Color(0xFFE25BA6),
    this.foregroundColor = Colors.white,
    this.side,
    this.padding = const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
    this.borderRadius = 28,
    this.elevation = 4,
    this.expand = false,
    this.textStyle,
    this.shadowColor,
  });

  @override
  Widget build(BuildContext context) {
    final button = ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        padding: padding,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          side: side ?? BorderSide.none,
        ),
        elevation: elevation,
        shadowColor: shadowColor ?? backgroundColor.withValues(alpha: 0.35),
      ),
      child: Text(
        text,
        style: textStyle,
      ),
    );

    if (!expand) return button;
    return SizedBox(width: double.infinity, child: button);
  }
}
