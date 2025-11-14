import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:myyearmystory/supabase/supabase_config.dart';
import 'package:myyearmystory/services/secure_storage_service.dart';

class AuthListener {
  static StreamSubscription<AuthState>? _subscription;
  static DateTime? _lastSignOutTime;

  static void initialize(GlobalKey<NavigatorState> navigatorKey) {
    if (_subscription != null) return;

    _subscription = SupabaseConfig.client.auth.onAuthStateChange.listen(
      (data) {
        final event = data.event;
        final session = data.session;
        final navigator = navigatorKey.currentState;

        if (navigator == null) return;

        debugPrint('📡 AuthListener → Evento: $event | Sessão ativa: ${session != null}');

        switch (event) {
          case AuthChangeEvent.signedIn:
            // Evita redirecionamento duplicado após logout
            if (_lastSignOutTime != null &&
                DateTime.now().difference(_lastSignOutTime!).inMilliseconds < 1200) {
              debugPrint('⏳ Ignorando signedIn muito próximo ao logout');
              return;
            }

            if (session != null) {
              unawaited(SecureStorageService.saveSession(session));
              final current = navigator.context.widget.toString();

              // Evita abrir dashboard se já estamos nele
              if (!current.contains('DashboardScreen')) {
                navigator.pushNamedAndRemoveUntil('/dashboard', (route) => false);
              }

              debugPrint('✅ Usuário logado — listener navegou');
            }
            break;

          case AuthChangeEvent.signedOut:
            _lastSignOutTime = DateTime.now();

            final current = navigator.context.widget.toString();

            // Evita redirecionamento caso já esteja na tela de login
            if (!current.contains('LoginScreen') &&
                !current.contains('AuthPageView')) {
              navigator.pushNamedAndRemoveUntil('/login', (route) => false);
            }

            debugPrint('👋 Usuário deslogado — listener navegou');
            break;

          case AuthChangeEvent.tokenRefreshed:
            if (session != null) {
              unawaited(SecureStorageService.saveSession(session));
            }
            debugPrint('🔄 Token atualizado automaticamente');
            break;

          default:
            debugPrint('ℹ️ Evento não tratado: $event');
            break;
        }
      },
    );
  }

  static Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
  }
}
