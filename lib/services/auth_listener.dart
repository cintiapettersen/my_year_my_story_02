import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:myyearmystory/services/app_session.dart';
import 'package:myyearmystory/services/profile_service.dart';



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

      _handleAuthEvent(
        event: event,
        session: session,
        navigator: navigator,
      );
    });
  }

  // --------------------------------------------------
  static Future<void> _handleAuthEvent({
    required AuthChangeEvent event,
    required Session? session,
    required NavigatorState navigator,
  }) async {
    debugPrint(
      '📡 AuthListener → event=$event | flow=${AppSession.flow}',
    );

   // 🔐 PASSWORD RECOVERY (evento inicial)
if (event == AuthChangeEvent.passwordRecovery && session != null) {
  AppSession.flow = AppAuthFlow.resettingPassword;

  navigator.pushNamedAndRemoveUntil(
    '/reset-password',
    (_) => false,
  );

  debugPrint('🔐 passwordRecovery → reset-password');
  return;
}

// 🔐 BLOQUEIO TOTAL DURANTE RESET
if (AppSession.flow == AppAuthFlow.resettingPassword &&
    event != AuthChangeEvent.signedOut) {
  debugPrint('🔐 Reset ativo → ignorando $event');
  return;
}

// --------------------------------------------------
// ✅ LOGIN REAL (email ou Google)
// --------------------------------------------------
if (event == AuthChangeEvent.signedIn &&
    session != null &&
    AppSession.flow != AppAuthFlow.resettingPassword) {

  if (AppSession.flow == AppAuthFlow.authenticated) {
    debugPrint('⏭️ signedIn ignorado (já autenticado)');
    return;
  }

  AppSession.flow = AppAuthFlow.authenticating;

  await profileService.ensureProfile();
  await profileService.load();

  final isComplete = profileService.isProfileComplete;

  AppSession.flow = AppAuthFlow.authenticated;

  if (isComplete) {
    navigator.pushNamedAndRemoveUntil('/dashboard', (_) => false);
  } else {
    navigator.pushNamedAndRemoveUntil('/complete-profile', (_) => false);
  }

  return;
}

    // --------------------------------------------------
    // 🚪 LOGOUT
    // --------------------------------------------------
    if (event == AuthChangeEvent.signedOut) {
      AppSession.flow = AppAuthFlow.splash;

      navigator.pushNamedAndRemoveUntil(
        '/login',
        (_) => false,
      );

      debugPrint('👋 signedOut → login');
      return;
    }
  }
}
