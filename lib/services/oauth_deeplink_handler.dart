import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:myyearmystory/services/app_session.dart';



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
      await _handleUri(initialUri);
    }

    // 2️⃣ Caso app já esteja aberto
    _sub = _appLinks.uriLinkStream.listen(
      (Uri uri) async {
        await _handleUri(uri);
      },
      onError: (err) {},
    );
  }

static Future<void> _handleUri(Uri uri) async {
  final type = uri.queryParameters['type'];

  // 🔐 RESET DE SENHA
  if (type == 'recovery') {
    AppSession.flow = AppAuthFlow.resettingPassword;

  

    await Supabase.instance.client.auth.getSessionFromUrl(uri);

    return;
  }

 
}




  static void dispose() {
    _sub?.cancel();
    _sub = null;
    _initialized = false;
  }
}
