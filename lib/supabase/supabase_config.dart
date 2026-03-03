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
      return;
    }

    try {
  await Supabase.initialize(
  url: supabaseUrl,
  anonKey: supabaseAnonKey,
  debug: true,
  authOptions: const FlutterAuthClientOptions(
  autoRefreshToken: true,
  detectSessionInUri: true,
),
);


      _initialized = true;
    } catch (e) {
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
      return response;
    } on AuthException {
      rethrow;
    } catch (e) {
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
      return response;
    } on AuthException {
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  /// 👋 Faz logout completo
  static Future<void> signOut(BuildContext context) async {
    try {
      await client.auth.signOut();
      await clearAllCache();

      if (context.mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
    } catch (e) {
    }
  }

  /// 🧹 Limpa cache e sessão
  static Future<void> clearAllCache({bool silent = false}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    } catch (e) {}

    if (kIsWeb) {
      try {
        WebStorage.clear();
      } catch (e) {}
    }
  }
}
