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

    

    // ✅ LOGIN REAL (email ou Google)
    if (event == AuthChangeEvent.signedIn && session != null) {
      AppSession.flow = AppAuthFlow.authenticated;

      navigator.pushNamedAndRemoveUntil(
        '/dashboard',
        (_) => false,
      );

      debugPrint('✅ signedIn → dashboard');
      return;
    }

    // --------------------------------------------------
// ✅ LOGIN (email ou Google)
// --------------------------------------------------
if (event == AuthChangeEvent.signedIn && session != null) {
  // ⛔️ evita navegação duplicada (Google dispara 2x)
  if (AppSession.flow == AppAuthFlow.authenticated) {
    debugPrint('⏭️ signedIn ignorado (já autenticado)');
    return;
  }

  AppSession.flow = AppAuthFlow.authenticated;

  navigator.pushNamedAndRemoveUntil(
    '/dashboard',
    (_) => false,
  );

  debugPrint('✅ signedIn → dashboard');
  return;
}


    // 📦 LOGOUT REAL (apenas se estava autenticado ou saindo)
    if (event == AuthChangeEvent.signedOut &&
        (AppSession.flow == AppAuthFlow.authenticated ||
         AppSession.flow == AppAuthFlow.loggingOut)) {

      AppSession.flow = AppAuthFlow.splash;

      navigator.pushNamedAndRemoveUntil(
        '/login',
        (_) => false,
      );
debugPrint('👋 signedOut → login');
      return;
    }
  });
  }
}
