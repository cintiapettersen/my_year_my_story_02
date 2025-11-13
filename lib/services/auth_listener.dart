import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:my_year_my_story/supabase/supabase_config.dart';

/// 🔐 Ouve eventos de autenticação (login, logout, link mágico)
class AuthListener {
  static void initialize(GlobalKey<NavigatorState> navigatorKey) {
    final client = SupabaseConfig.client;

    client.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      final session = data.session;
      final navigator = navigatorKey.currentState;

      if (navigator == null) return;

      switch (event) {
        case AuthChangeEvent.signedIn:
          if (session != null) {
            navigator.pushNamedAndRemoveUntil('/dashboard', (route) => false);
          }
          break;

        case AuthChangeEvent.signedOut:
          navigator.pushNamedAndRemoveUntil('/login', (route) => false);
          break;

        default:
          break;
      }
    });
  }
}
