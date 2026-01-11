import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:myyearmystory/widgets/shared/app_bottom_menu.dart';
import 'package:myyearmystory/utils/app_theme.dart';

class MainScaffold extends StatelessWidget {
  const MainScaffold({
    super.key,
    this.currentIndex,
    required this.body,
    this.title,
  });

  final int? currentIndex;
  final Widget body;
  final String? title;

  @override
  Widget build(BuildContext context) {
    final bool showBottomMenu = currentIndex != null;

    return ValueListenableBuilder<Color>(
      valueListenable: appThemeColor,
      builder: (_, color, __) {
        return Scaffold(
          backgroundColor: const Color(0xFFFCE9EF),

          appBar: AppBar(
            centerTitle: true,
            backgroundColor: color,
            elevation: 0,
            title: Text(
              title ?? 'My Year, My Story',
              style: GoogleFonts.cinzel(
                textStyle: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            leading: Navigator.of(context).canPop()
                ? IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  )
                : null,
          ),

          body: SafeArea(child: body),

          bottomNavigationBar: showBottomMenu
              ? AppBottomMenu(
                  currentIndex: currentIndex,
                  themeColor: color,
                )
              : null,
        );
      },
    );
  }
}