import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:my_year_my_story/screens/dashboard/dashboard_screen.dart';
import 'package:my_year_my_story/supabase/supabase_config.dart';
import 'package:my_year_my_story/screens/splash/fade_page_transition.dart';

class GoogleSignInService {
  /// 🚀 Login com Google (Web + Mobile)
  static Future<void> signInWithGoogle(BuildContext context) async {
    try {
      await SupabaseConfig.ensureInitialized();
      final client = SupabaseConfig.client;

      print('🌍 Iniciando login com Google...');
      final redirectUrl = _getRedirectUrl();
      print('🔗 Redirect URL detectado: $redirectUrl');

      await client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: redirectUrl,
        authScreenLaunchMode: LaunchMode.externalApplication,
      );

      print('✅ Fluxo OAuth iniciado com sucesso!');

      // Aguarda sincronização da sessão (leve aumento para estabilidade)
      await Future.delayed(const Duration(seconds: 4));

      final user = SupabaseConfig.getCurrentUser();

      if (user != null) {
        print('🎉 Login bem-sucedido: ${user.email}');
        _goToDashboard(context);
      } else {
        print('⚠️ Usuário não detectado após login. Tentando novamente...');
        await Future.delayed(const Duration(seconds: 2));
        final retryUser = SupabaseConfig.getCurrentUser();

        if (retryUser != null) {
          print('✅ Sessão confirmada na segunda tentativa: ${retryUser.email}');
          _goToDashboard(context);
        } else {
          print('❌ Falha ao autenticar usuário.');
          _showErrorDialog(context, 'Falha ao autenticar com o Google. Tente novamente.');
        }
      }
    } catch (e) {
      print('❌ Erro durante o login com Google: $e');
      _showErrorDialog(context, 'Ocorreu um erro durante o login com o Google.');
    }
  }

  /// ✨ Define URL de redirecionamento conforme ambiente
  static String _getRedirectUrl() {
    if (kIsWeb) {
      // 👇 Evita erro "Platform._operatingSystem" e mantém compatibilidade local
      return 'http://localhost:55078/';
    } else if (Platform.isAndroid) {
      return 'io.supabase.flutter://login-callback/';
    } else if (Platform.isIOS) {
      return 'com.myyear.mystory://login-callback/';
    } else {
      return 'http://localhost:55078/';
    }
  }

  /// 🔒 Logout
  static Future<void> signOut(BuildContext context) async {
    try {
      await SupabaseConfig.signOut();
      print('👋 Logout concluído.');
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    } catch (e) {
      print('⚠️ Erro ao sair: $e');
    }
  }

  /// 🪄 Redireciona pro Dashboard
  static void _goToDashboard(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      fadePageTransition(
        DashboardScreen(
          month: DateTime.now().month,
          year: DateTime.now().year,
        ),
      ),
          (route) => false,
    );
  }

  /// ❌ Mostra diálogo de erro
  static void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Erro de autenticação'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
