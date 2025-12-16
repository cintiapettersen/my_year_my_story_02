import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart';

class GoogleAuthService {
  static final _supabase = Supabase.instance.client;

  /// 🚀 Login com Google via Supabase OAuth
  static Future<Map<String, dynamic>> signInWithGoogle() async {
    try {
      final redirectUrl = _getRedirectUrl();

      print('🌍 Iniciando login com Google...');
      print('🔗 Redirect URL: $redirectUrl');

      await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: redirectUrl,
      );

      return {'success': true};

    } catch (e) {
      print('❌ Erro no login com Google: $e');
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  /// 🔗 Define o redirect correto para Web / Android / iOS
  static String _getRedirectUrl() {
    if (kIsWeb) {
      return 'https://abrctowsfsgfxdoszmdq.supabase.co/auth/v1/callback';
    }

    return 'com.myyear.myyearmystory://auth/callback';
  }
}
