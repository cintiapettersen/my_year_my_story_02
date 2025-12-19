import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:myyearmystory/screens/dashboard/dashboard_screen.dart';
import 'package:myyearmystory/screens/auth/auth_page_view.dart';
import 'package:myyearmystory/screens/splash/fade_page_transition.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:myyearmystory/widgets/auth/biometric_login_page.dart';
import 'package:myyearmystory/services/secure_storage_service.dart';

class SplashTransitionScreen extends StatefulWidget {
  const SplashTransitionScreen({super.key});

  @override
  State<SplashTransitionScreen> createState() => _SplashTransitionScreenState();
}

class _SplashTransitionScreenState extends State<SplashTransitionScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  bool _showButtons = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    );

    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.03).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOutCubic,
      ),
    );

    _controller.forward();
    _checkSession();
  }

  Future<void> _checkSession() async {
    await Future.delayed(const Duration(seconds: 2));

    try {
      final persisted = await SecureStorageService.readSessionJson();

      if (persisted != null && persisted.isNotEmpty) {
        _goToBiometricLogin();
        return;
      }

      if (!mounted) return;
      setState(() => _showButtons = true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _showButtons = true);
    }
  }

  void _goToBiometricLogin() {
    Navigator.of(context).pushReplacement(
      fadePageTransition(const BiometricLoginPage()),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _enterAsGuest() {
    Navigator.of(context).pushReplacement(
      fadePageTransition(
        DashboardScreen(
          month: DateTime.now().month,
          year: DateTime.now().year,
        ),
      ),
    );
  }

  void _goToLogin() {
    Navigator.of(context).pushReplacement(
      fadePageTransition(const AuthPageView()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: LayoutBuilder(
        builder: (context, constraints) {
          // RESPONSIVIDADE
          final isTablet = constraints.maxWidth > 600;
          final logoSize = isTablet ? 180.0 : 120.0;
          final mainTextSize = isTablet ? 32.0 : 22.0;
          final subtitleSize = isTablet ? 24.0 : 17.0;
          final buttonPadding = isTablet ? 22.0 : 16.0;
          final horizontalPadding = isTablet ? 80.0 : 40.0;

          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 700),
            child: !_showButtons
                ? FadeTransition(
                    opacity: _fadeAnimation,
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              'assets/imagens/logo.png',
                              height: logoSize,
                            ),
                            const SizedBox(height: 24),

                            Text(
                              'splash.new_chapter'.tr(),
                              textAlign: TextAlign.center,
                              style: GoogleFonts.satisfy(
                                fontSize: mainTextSize,
                                fontWeight: FontWeight.w400,
                                color: const Color(0xFFC03B66),
                                height: 1.3,
                              ),
                            ),

                            const SizedBox(height: 25),

                            const CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFFC03B66),
                              ),
                              strokeWidth: 2.5,
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                : _buildChoiceScreen(
                    isTablet: isTablet,
                    logoSize: logoSize,
                    subtitleSize: subtitleSize,
                    buttonPadding: buttonPadding,
                    horizontalPadding: horizontalPadding,
                  ),
          );
        },
      ),
    );
  }

  Widget _buildChoiceScreen({
    required bool isTablet,
    required double logoSize,
    required double subtitleSize,
    required double buttonPadding,
    required double horizontalPadding,
  }) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/imagens/logo.png',
                height: logoSize,
              ),

              const SizedBox(height: 30),

              Text(
                'splash.subtitle'.tr(),
                textAlign: TextAlign.center,
                style: GoogleFonts.satisfy(
                  fontSize: subtitleSize,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                  height: 1.4,
                ),
              ),

              SizedBox(height: isTablet ? 80 : 60),

              // LOGIN BUTTON
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _goToLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFe2377d),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: EdgeInsets.symmetric(vertical: buttonPadding),
                  ),
                  child: Text(
                    'splash.login_button'.tr(),
                    style: TextStyle(
                      fontSize: isTablet ? 22 : 16,
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 15),

              // GUEST BUTTON
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _enterAsGuest,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFC03B66), width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: EdgeInsets.symmetric(vertical: buttonPadding),
                  ),
                  child: Text(
                    'splash.guest_button'.tr(),
                    style: TextStyle(
                      fontSize: isTablet ? 22 : 16,
                      color: const Color(0xFFC03B66),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
