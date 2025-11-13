import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:my_year_my_story/supabase/supabase_config.dart';

class GoogleSignInService {
  /// 🚀 Login com Google (Web + Mobile)
  static Future<void> signInWithGoogle(BuildContext context) async {
    try {
      final client = SupabaseConfig.client;

      print('🌍 Iniciando login com Google...');
      final redirectUrl = _getRedirectUrl();
      print('🔗 Redirect URL detectado: $redirectUrl');

      // 💫 Inicia o fluxo OAuth
      await client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: redirectUrl,
        authScreenLaunchMode: LaunchMode.externalApplication,
      );

      print('✅ Fluxo OAuth iniciado com sucesso. Aguardando retorno...');

    } catch (e) {
      print('❌ Erro durante o login com Google: $e');
      _showErrorDialog(context, 'Ocorreu um erro durante o login com o Google.');
    }
  }

  /// ✨ Define URL de redirecionamento conforme ambiente
  static String _getRedirectUrl() {
    if (kIsWeb) {
      return 'https://abrctowsfsgfxdoszmdq.supabase.co/auth/v1/callback';
    } else if (Platform.isAndroid || Platform.isIOS) {
      return 'com.myyear.myyearmystory://auth/callback';
    } else {
      return 'https://abrctowsfsgfxdoszmdq.supabase.co/auth/v1/callback';
    }
  }

  /// 🔒 Logout
  static Future<void> signOut(BuildContext context) async {
    try {
      await SupabaseConfig.client.auth.signOut();
      print('👋 Logout concluído.');
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    } catch (e) {
      print('⚠️ Erro ao sair: $e');
    }
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
