import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OAuthDeepLinkHandler {
  static final AppLinks _appLinks = AppLinks();
  static StreamSubscription<Uri>? _sub;
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    // 1️⃣ Caso app volte do background / cold start
    final Uri? initialUri = await _appLinks.getInitialLink();

    if (initialUri != null) {
      print('🔗 Initial deep link: $initialUri');
      await _handleUri(initialUri);
    }

    // 2️⃣ Caso app já esteja aberto
    _sub = _appLinks.uriLinkStream.listen(
      (Uri uri) async {
        print('🔗 Stream deep link: $uri');
        await _handleUri(uri);
      },
      onError: (err) {
        print('❌ Erro no deep link stream: $err');
      },
    );
  }

  static Future<void> _handleUri(Uri uri) async {
    if (uri.queryParameters.containsKey('code')) {
      try {
        print('🔑 Processando OAuth do Supabase...');
        await Supabase.instance.client.auth.getSessionFromUrl(uri);
        print('✅ getSessionFromUrl OK');
      } catch (e) {
        print('❌ Erro no getSessionFromUrl: $e');
      }
    }
  }

  static void dispose() {
    _sub?.cancel();
    _sub = null;
    _initialized = false;
  }
}
