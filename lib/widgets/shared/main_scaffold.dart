import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:myyearmystory/widgets/shared/app_bottom_menu.dart';
import 'package:myyearmystory/utils/app_theme.dart';

class MainScaffold extends StatefulWidget {
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
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  bool _backBusy = false;

  void _requestBackPop(BuildContext context) {
    if (_backBusy) return;
    setState(() => _backBusy = true);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        if (!mounted) return;
        final navigator = Navigator.of(context);
        if (!navigator.canPop()) return;
        await navigator.maybePop();
      } on AssertionError catch (e) {
        if (kDebugMode) {
          debugPrint('MainScaffold back pop blocked (navigator locked): $e');
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('MainScaffold back pop failed: $e');
        }
      } finally {
        if (mounted) setState(() => _backBusy = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool showBottomMenu = widget.currentIndex != null;

    return ValueListenableBuilder<Color>(
      valueListenable: appThemeColor,
      builder: (context, color, child) {
        return Scaffold(
          backgroundColor: const Color(0xFFFCE9EF),

          appBar: AppBar(
            centerTitle: true,
            backgroundColor: color,
            elevation: 0,
            title: Text(
              widget.title ?? 'My Year, My Story',
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
                    onPressed: _backBusy ? null : () => _requestBackPop(context),
                  )
                : null,
          ),

          body: SafeArea(child: widget.body),

          bottomNavigationBar: showBottomMenu
              ? AppBottomMenu(
                  currentIndex: widget.currentIndex,
                  themeColor: color,
                )
              : null,
        );
      },
    );
  }
}
