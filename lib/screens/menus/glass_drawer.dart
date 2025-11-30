import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:myyearmystory/screens/menus/app_drawer.dart';


class GlassDrawer extends StatelessWidget {
  final List<Widget> children;

  const GlassDrawer({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      elevation: 0,
      backgroundColor: Colors.transparent,
      width: 280,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(
          right: Radius.circular(32),
        ),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.horizontal(right: Radius.circular(32)),
        child: Stack(
          children: [
            // Fundo borrado (blur)
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.25),
                    width: 1.2,
                  ),
                ),
              ),
            ),

            // Conteúdo colocado por você
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ],
        ),
      ),
    );
  }
}
