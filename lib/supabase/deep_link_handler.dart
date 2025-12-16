import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DeepLinkHandler {
  static final AppLinks _appLinks = AppLinks();
  static StreamSubscription? _sub;

  /// Inicializa listeners de deep link
  static Future<void> initialize() async {
    // Quando o app recebe um deep link ENQUANTO está aberto
    _sub = _appLinks.uriLinkStream.listen((uri) {
      if (uri != null) {
        print('🔥 Deep link recebido (stream): $uri');
        Supabase.instance.client.auth.getSessionFromUrl(uri);
      }
    });

    // Quando o app ABRE pelo deep link
    final initialUri = await _appLinks.getInitialLink();
    if (initialUri != null) {
      print('🚀 App aberto via deep link: $initialUri');
      Supabase.instance.client.auth.getSessionFromUrl(initialUri);
    }
  }

  static void dispose() {
    _sub?.cancel();
  }
}
