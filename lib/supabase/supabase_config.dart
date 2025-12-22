import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Import condicional: web usa web_storage_web.dart, mobile usa stub
import 'web_storage_stub.dart'
    if (dart.library.html) 'web_storage_web.dart';

// 🌎 Instância global do cliente Supabase
SupabaseClient get supabase => Supabase.instance.client;

class SupabaseConfig {
  static bool _initialized = false;

  // 🔗 Chaves e URLs do seu projeto Supabase
  static const String supabaseUrl = 'https://abrctowsfsgfxdoszmdq.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFicmN0b3dzZnNnZnhkb3N6bWRxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTQ1Nzc5MTksImV4cCI6MjA3MDE1MzkxOX0.ptaOeholjF8dBsXocOsBrSdtYidWVm2BtixsIhE2WF8';

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
    detectSessionInUri: true, // ✅ ESSENCIAL
  ),
);


      _initialized = true;
      print('✅ Supabase inicializado com sucesso!');
    } catch (e) {
      print('❌ Erro ao inicializar Supabase: $e');
      rethrow;
    }
  }

  /// 🔑 Login com e-mail e senha
  static Future<AuthResponse> signIn(String email, String password) async {
    try {
      final response = await client.auth.signInWithPassword(
        email: email.trim(),
        password: password.trim(),
      );
      print('✅ Login realizado com sucesso para $email');
      return response;
    } on AuthException catch (e) {
      print('❌ Erro de autenticação: ${e.message}');
      rethrow;
    } catch (e) {
      print('⚠️ Erro inesperado: $e');
      rethrow;
    }
  }

  /// ✨ Registra novo usuário
  static Future<AuthResponse> signUp(String email, String password) async {
    try {
      final response = await client.auth.signUp(
        email: email.trim(),
        password: password.trim(),
      );
      print('✅ Usuário criado com sucesso: $email');
      return response;
    } on AuthException catch (e) {
      print('❌ Erro no cadastro: ${e.message}');
      rethrow;
    } catch (e) {
      print('⚠️ Erro inesperado no cadastro: $e');
      rethrow;
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
