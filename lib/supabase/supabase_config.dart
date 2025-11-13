import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app_links/app_links.dart';
import 'package:my_year_my_story/main.dart' show navigatorKey;

// Import condicional: web usa web_storage_web.dart, mobile usa stub
import 'web_storage_stub.dart'
    if (dart.library.html) 'web_storage_web.dart';

// 🌎 Instância global do cliente Supabase (lazy getter)
SupabaseClient get supabase => Supabase.instance.client;

/// Tipos de erro usados no fluxo de Magic Link.
enum MagicLinkExceptionType { userNotFound, generic }

/// Exceção específica do fluxo de Magic Link para facilitar tratamento na UI.
class MagicLinkException implements Exception {
  MagicLinkException(this.type, this.message, [this.originalError]);

  final MagicLinkExceptionType type;
  final String message;
  final Object? originalError;

  @override
  String toString() => message;
}

class SupabaseConfig {
  static bool _initialized = false;
  static StreamSubscription<Uri>? _linkSub;

  // 🔗 Chaves e URLs do seu projeto Supabase
  static const String supabaseUrl = 'https://abrctowsfsgfxdoszmdq.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFicmN0b3dzZnNnZnhkb3N6bWRxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTQ1Nzc5MTksImV4cCI6MjA3MDE1MzkxOX0.ptaOeholjF8dBsXocOsBrSdtYidWVm2BtixsIhE2WF8';

  // 🌎 URLs de redirecionamento
  static const String appRedirectUrl =
      'com.myyear.myyearmystory://auth/callback';

  static SupabaseClient get client => Supabase.instance.client;

  /// 🚀 Inicializa o Supabase (somente uma vez)
  static Future<void> initialize() async {
    if (_initialized) {
      print('⚙️ Supabase já estava inicializado.');
      return;
    }

    print('🚀 Inicializando Supabase...');

    try {
      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseAnonKey,
        debug: true,
        authOptions: const FlutterAuthClientOptions(
          autoRefreshToken: true,
          
          detectSessionInUri: true, // 👈 ESSENCIAL pro Magic Link
          authFlowType: AuthFlowType.pkce,
        ),
      );

      // 🔁 Escuta mudanças no estado de autenticação
      Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
        final event = data.event;
        final session = data.session;

        print('🌀 Auth event: $event');

        if (event == AuthChangeEvent.signedIn && session != null) {
          print('✅ Usuário autenticado: ${session.user.email}');
          final context = navigatorKey.currentContext;
          if (context != null && context.mounted) {
            Navigator.pushNamedAndRemoveUntil(
                context, '/dashboard', (route) => false);
          }
        } else if (event == AuthChangeEvent.signedOut) {
          print('🚪 Sessão encerrada.');
          final context = navigatorKey.currentContext;
          if (context != null && context.mounted) {
            Navigator.pushNamedAndRemoveUntil(
                context, '/login', (route) => false);
          }
        }
      });

      // 🧩 Inicializa listener de deep links (opcional, pra redundância)
      await _initDeepLinkListener();

      _initialized = true;
      print('✅ Supabase inicializado com sucesso!');
    } catch (e) {
      print('❌ Erro ao inicializar Supabase: $e');
      rethrow;
    }
  }

  /// 🧭 Listener para deep links (iOS / Android)
  static Future<void> _initDeepLinkListener() async {
    final appLinks = AppLinks();

    try {
      final Uri? initialLink = await appLinks.getInitialLink();
      if (initialLink != null) {
        await handleAuthLink(initialLink);
      }
    } catch (e) {
      print('⚠️ Erro ao obter link inicial: $e');
    }

    _linkSub = appLinks.uriLinkStream.listen((uri) async {
      await handleAuthLink(uri);
    });
  }

  /// ✨ Envia Magic Link (passwordless)
  static Future<void> sendMagicLink(String email) async {
    final normalizedEmail = email.trim().toLowerCase();

    if (normalizedEmail.isEmpty) {
      throw MagicLinkException(
        MagicLinkExceptionType.generic,
        'Email vazio não pode receber link mágico.',
      );
    }

    try {
      print('📨 Enviando Magic Link para $normalizedEmail...');

      await client.auth.signInWithOtp(
        email: normalizedEmail,
        emailRedirectTo: appRedirectUrl,
        shouldCreateUser: false,
      );

      print('✅ Magic Link enviado com sucesso para $normalizedEmail');
    } on AuthException catch (e) {
      final lowerMessage = e.message.toLowerCase();
      final isUnknownUser = lowerMessage.contains('user not found') ||
          lowerMessage.contains('security reasons');

      if (isUnknownUser) {
        throw MagicLinkException(
          MagicLinkExceptionType.userNotFound,
          'Email não cadastrado.',
          e,
        );
      }

      throw MagicLinkException(
        MagicLinkExceptionType.generic,
        e.message,
        e,
      );
    } catch (e, stack) {
      print('❌ Erro inesperado ao enviar Magic Link: $e');
      print(stack);
      throw MagicLinkException(
        MagicLinkExceptionType.generic,
        'Erro inesperado ao enviar link mágico.',
        e,
      );
    }
  }

    /// 📩 Trata links mágicos (deep links) vindos do e-mail
  static Future<void> handleAuthLink(Uri uri) async {
    try {
      print('📩 Link recebido: $uri');

      // Verifica se o link pertence ao app
      if (uri.scheme != 'com.myyear.myyearmystory' ||
          !uri.path.contains('/auth/callback')) {
        print('⚠️ Link ignorado: não pertence ao app.');
        return;
      }

      // 🔑 Faz a troca do código do link mágico por uma sessão válida
      final res = await Supabase.instance.client.auth.exchangeCodeForSession(uri.toString());

      final session = res.session;
      final user = session?.user;

      if (session != null && user != null) {
        print('✅ Sessão autenticada com sucesso: ${user.email}');

        // 🔁 Força atualização do token (caso necessário)
        await Supabase.instance.client.auth.refreshSession();

        // 🔀 Redireciona para o dashboard
        final context = navigatorKey.currentContext;
        if (context != null && context.mounted) {
          Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (route) => false);
        }
      } else {
        print('⚠️ Nenhuma sessão retornada. Verifique o link mágico.');
      }
    } on AuthException catch (e) {
      print('❌ Erro de autenticação: ${e.message}');
    } catch (e, stack) {
      print('❌ Erro ao processar deep link mágico: $e');
      print(stack);
    }
  }

  /// 👋 Faz logout completo
  static Future<void> signOut(BuildContext context) async {
    try {
      await client.auth.signOut();
      await clearAllCache();
      print('👋 Logout realizado com sucesso.');

      if (context.mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
    } catch (e) {
      print('⚠️ Erro ao sair da conta: $e');
    }
  }

  /// 🧹 Limpa cache e sessão
  static Future<void> clearAllCache({bool silent = false}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      if (!silent) print('✅ SharedPreferences limpo.');
    } catch (e) {
      if (!silent) print('⚠️ Erro ao limpar SharedPreferences: $e');
    }

    if (kIsWeb) {
      try {
        WebStorage.clear();
        if (!silent) print('✅ Browser storage limpo.');
      } catch (e) {
        if (!silent) print('⚠️ Erro ao limpar browser storage: $e');
      }
    }
  }
}
