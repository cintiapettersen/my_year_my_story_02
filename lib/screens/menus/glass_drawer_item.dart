import 'package:flutter/material.dart';

class GlassDrawerItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;
  final VoidCallback onTap;

  const GlassDrawerItem({
    super.key,
    required this.icon,
    required this.color,
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        icon,
        color: color,
        size: 26,
      ),
      title: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 17,
          fontWeight: FontWeight.w400,
        ),
      ),
      onTap: onTap,
      minLeadingWidth: 34,
      dense: true,
    );
  }
}
