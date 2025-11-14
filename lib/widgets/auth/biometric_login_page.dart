import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:myyearmystory/screens/dashboard/dashboard_screen.dart';
import 'package:myyearmystory/screens/splash/fade_page_transition.dart';
import 'package:myyearmystory/widgets/auth/auth_button.dart';
import 'package:myyearmystory/services/secure_storage_service.dart';
import 'package:myyearmystory/supabase/supabase_config.dart';

class BiometricLoginPage extends StatefulWidget {
  const BiometricLoginPage({super.key});

  @override
  State<BiometricLoginPage> createState() => _BiometricLoginPageState();
}

class _BiometricLoginPageState extends State<BiometricLoginPage> {
  final LocalAuthentication _auth = LocalAuthentication();
  bool _isLoading = false;

  Future<void> _authenticate() async {
    try {
      setState(() => _isLoading = true);

      final persistedSession = await SecureStorageService.readSessionJson();
      if (persistedSession == null || persistedSession.isEmpty) {
        _show('Faça login com e-mail e senha primeiro.');
        return;
      }

      // 🔍 Verifica suporte à biometria / PIN
      final canCheck = await _auth.canCheckBiometrics ||
          await _auth.isDeviceSupported();

      if (!canCheck) {
        _show('Biometria ou PIN não disponível neste dispositivo.');
        return;
      }

      // 🔑 Autenticação local
      final ok = await _auth.authenticate(
        localizedReason: 'Confirme sua identidade para entrar',
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
        ),
      );

      if (!ok) {
        _show('Autenticação cancelada.');
        return;
      }

      final response =
          await SupabaseConfig.client.auth.recoverSession(persistedSession);
      final session = response.session;

      if (session == null) {
        await SecureStorageService.clearSession();
        _show('Sessão expirada. Faça login novamente.');
        return;
      }

      await SecureStorageService.saveSession(session);

      // 🎉 Entra no app
      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        fadePageTransition(
          DashboardScreen(
            month: DateTime.now().month,
            year: DateTime.now().year,
          ),
        ),
      );
    } catch (e) {
      _show('Erro na autenticação: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _show(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return AuthButton(
      text: _isLoading ? 'Verificando...' : 'Entrar com biometria ou PIN',
      icon: Icons.fingerprint,
      isOutlined: true,
      isLoading: _isLoading,
      onPressed: _authenticate,
    );
  }
}
