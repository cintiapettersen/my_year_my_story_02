import 'package:flutter/material.dart';

class AuthButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isOutlined;
  final Color? backgroundColor;
  final IconData? icon;

  const AuthButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.backgroundColor,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final bool isEnabled = onPressed != null && !isLoading;
    
    return Container(
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        gradient: !isOutlined && isEnabled
            ? LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: backgroundColor != null
                    ? [backgroundColor!, backgroundColor!]
                    : [
                        Color(0xFFE2377D), // secondary
                        Color(0xFFC03B66), // primary
                      ],
              )
            : null,
        border: isOutlined
    ? Border.all(
        color: isEnabled
            ? const Color(0xFFC03B66).withOpacity(0.5)
            : Colors.grey.withOpacity(0.3),
        width: 1.5,
      )
    : null,
        boxShadow: !isOutlined && isEnabled
            ? [
                BoxShadow(
                 color: (backgroundColor ?? const Color(0xFFE2377D))
    .withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isEnabled ? onPressed : null,
          borderRadius: BorderRadius.circular(15),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isLoading)
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
  isOutlined
      ? const Color(0xFFC03B66)
      : Colors.white,
),

                    ),
                  )
                else ...[
                  if (icon != null) ...[
                    Icon(
                      icon,
                      color: isOutlined
    ? const Color(0xFFC03B66)
    : Colors.white,

                      size: 20,
                    ),
                    const SizedBox(width: 12),
                  ],
                  Text(
                    text,
                    style: Theme.of(context).textTheme.labelLarge!.copyWith(
                      color: isEnabled
    ? (isOutlined
        ? Colors.black
        : Colors.white)
    : Colors.grey,

                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}