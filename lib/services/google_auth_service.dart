import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class GoogleAuthService {
  static final _supabase = Supabase.instance.client;

  /// 🚀 Login com Google via Supabase OAuth
  static Future<Map<String, dynamic>> signInWithGoogle() async {
    try {
      final redirectUrl = _getRedirectUrl();

      await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: redirectUrl,
        authScreenLaunchMode: LaunchMode.externalApplication,
      );

      return {'success': true};

    } catch (e) {
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

    return 'com.myyear.myyearmystory://login-callback';

  }
}
