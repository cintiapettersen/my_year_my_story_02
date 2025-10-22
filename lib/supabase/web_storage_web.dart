import 'dart:html' as html;

/// Implementação específica para Web.
/// Limpa localStorage e sessionStorage.
class WebStorage {
  static void clear() {
    // Limpa localStorage
    html.window.localStorage.clear();

    // Limpa sessionStorage
    html.window.sessionStorage.clear();

    // Remove chaves relacionadas ao Supabase
    final keysToRemove = <String>[];
    for (var key in html.window.localStorage.keys) {
      if (key.contains('supabase') ||
          key.contains('auth') ||
          key.contains('session') ||
          key.contains('token')) {
        keysToRemove.add(key);
      }
    }
    for (final key in keysToRemove) {
      html.window.localStorage.remove(key);
    }
  }
}
