import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:myyearmystory/screens/auth/login_screen.dart';
import 'package:myyearmystory/screens/dashboard/dashboard_screen.dart';
import 'package:myyearmystory/screens/splash/fade_page_transition.dart';
import 'package:myyearmystory/services/secure_storage_service.dart';
import 'package:myyearmystory/supabase/supabase_config.dart';
import 'package:easy_localization/easy_localization.dart';

class BiometricLoginPage extends StatefulWidget {
  const BiometricLoginPage({super.key});

  @override
  State<BiometricLoginPage> createState() => _BiometricLoginPageState();
}

class _BiometricLoginPageState extends State<BiometricLoginPage> {
  final LocalAuthentication _auth = LocalAuthentication();
  bool _isLoading = true;
  bool _failedOnce = false;

  @override
  void initState() {
    super.initState();
    _authenticate();
  }

  Future<void> _authenticate() async {
    try {
      final persistedSession = await SecureStorageService.readSessionJson();

      // ❌ Nenhuma sessão persistida → Volta para Login
      if (persistedSession == null || persistedSession.isEmpty) {
        _goToLogin();
        return;
      }

      // 🔍 Verifica se dispositivo permite biometria / PIN
      final canCheck =
          await _auth.canCheckBiometrics || await _auth.isDeviceSupported();

      if (!canCheck) {
        _goToLogin();
        return;
      }

      // 🔑 Inicia autenticação
      final ok = await _auth.authenticate(
        localizedReason: 'auth.biometric.reason'.tr(),
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );

      if (!ok) {
        setState(() => _failedOnce = true);
        return;
      }

      // 🔄 Recupera sessão a partir do JSON salvo
      final response =
          await SupabaseConfig.client.auth.recoverSession(persistedSession);

      final session = response.session;

      if (session == null) {
        await SecureStorageService.clearSession();
        _goToLogin();
        return;
      }

      // 💾 Salva sessão atualizada
      await SecureStorageService.saveSession(session);

      // 🎉 Entra no dashboard
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        fadePageTransition(
          DashboardScreen(
            month: DateTime.now().month,
            year: DateTime.now().year,
          ),
        ),
      );
    } catch (e) {
      setState(() => _failedOnce = true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _goToLogin() {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      fadePageTransition(const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _failedOnce ? _authenticate : null,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8DCE0),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_isLoading)
                const CircularProgressIndicator(color: Colors.purple)
              else
                Icon(
                  _failedOnce ? Icons.error_outline : Icons.fingerprint,
                  size: 90,
                  color: Colors.purple.shade300,
                ),
              const SizedBox(height: 20),
              Text(
                _isLoading
                    ? 'auth.biometric.loading'.tr()
                    : (_failedOnce
                        ? 'auth.biometric.try_again'.tr()
                        : 'auth.biometric.reason'.tr()),
                style: const TextStyle(fontSize: 18, color: Colors.black87),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
