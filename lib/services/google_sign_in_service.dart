import 'dart:async';
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

      // 🔹 Declara variável antes de usá-la
      late final StreamSubscription<AuthState> authSubscription;

      // 🔹 Listener: aguarda evento de autenticação do Supabase
      authSubscription = client.auth.onAuthStateChange.listen((data) async {
        final AuthChangeEvent event = data.event;
        final Session? session = data.session;

        print('🌀 Evento de autenticação detectado: $event');

        if (event == AuthChangeEvent.signedIn && session?.user != null) {
          print('🎉 Login concluído com sucesso!');
          print('👤 ID do usuário: ${session!.user!.id}');
          print('📧 E-mail: ${session.user!.email}');

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Login realizado com sucesso!')),
          );

          _goToDashboard(context);

          // ✅ Agora o cancel funciona sem erro
          await authSubscription.cancel();
        } else if (event == AuthChangeEvent.signedOut) {
          print('👋 Usuário saiu da conta.');
        } else {
          print('⏳ Aguardando sessão ser criada...');
        }
      });

      // 🔹 Inicia o fluxo OAuth
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
      // 🌐 Quando rodar no Chrome, só pra testes
      // (vai dar erro visual, mas o login do Supabase é validado no painel)
      return 'https://abrctowsfsgfxdoszmdq.supabase.co/auth/v1/callback';
    } else if (Platform.isAndroid || Platform.isIOS) {
      // 📱 Fluxo real do app (mobile)
      return 'com.myyear.my_year_my_story://login-callback/';
    } else {
      return 'https://abrctowsfsgfxdoszmdq.supabase.co/auth/v1/callback';
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
