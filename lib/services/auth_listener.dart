import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:myyearmystory/services/app_session.dart';

class AuthListener {
  static StreamSubscription<AuthState>? _subscription;

  static void initialize(GlobalKey<NavigatorState> navigatorKey) {
    if (_subscription != null) return;

    _subscription =
        Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      final session = data.session;
      final navigator = navigatorKey.currentState;

      if (navigator == null) return;

      debugPrint(
        '📡 AuthListener → event=$event | flow=${AppSession.flow}',
      );

      // --------------------------------------------------
      // 🔒 GUEST MODE — ignora tudo
      // --------------------------------------------------
      if (AppSession.isGuest) {
        debugPrint('🧭 Guest ativo — evento ignorado');
        return;
      }

      // --------------------------------------------------
      // 🔄 RESTORE SESSION (app reaberto)
      // --------------------------------------------------
      if (event == AuthChangeEvent.initialSession &&
          session != null &&
          AppSession.isSplash) {
        AppSession.flow = AppAuthFlow.authenticated;

        navigator.pushNamedAndRemoveUntil(
          '/dashboard',
          (_) => false,
        );

        debugPrint('🔄 Sessão restaurada — dashboard');
        return;
      }

      // --------------------------------------------------
      // ✅ LOGIN (email ou Google)
      // --------------------------------------------------
      if (event == AuthChangeEvent.signedIn && session != null) {
        AppSession.flow = AppAuthFlow.authenticated;

        navigator.pushNamedAndRemoveUntil(
          '/dashboard',
          (_) => false,
        );

        debugPrint('✅ Login concluído — dashboard');
        return;
      }

      // --------------------------------------------------
      // 🚪 LOGOUT (FINALMENTE FUNCIONANDO)
      // --------------------------------------------------
      if (event == AuthChangeEvent.signedOut) {
        debugPrint('👋 signedOut recebido');

        if (AppSession.isLoggingOut || AppSession.isAuthenticated) {
          AppSession.reset();

          navigator.pushNamedAndRemoveUntil(
            '/login',
            (_) => false,
          );

          debugPrint('👋 Logout concluído — login');
          return;
        }
      }

      // --------------------------------------------------
      // 💤 OUTROS EVENTOS
      // --------------------------------------------------
      debugPrint('🛑 Evento ignorado');
    });
  }

  static Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
  }
}
