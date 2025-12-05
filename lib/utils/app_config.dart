// lib/app_config.dart

class AppConfig {
  /// Ativa o modo desenvolvedora.
  /// Quando TRUE → todo conteúdo premium fica liberado pra você.
  /// Quando FALSE → app funciona normalmente com paywall.
  static const bool devMode = true;

  /// E-mail com acesso liberado
  static const String adminEmail = "cintyapadua@gmail.com";

  /// Método já existente → não mexi!
  static bool isAdmin(String? email) {
    if (devMode) return true;
    if (email == null) return false;
    return email.toLowerCase().trim() == adminEmail.toLowerCase().trim();
  }

  /// 👉 NOVO MÉTODO (compatível com seu MoodScreen)
  /// Esse método usa exatamente a mesma lógica do isAdmin.
  static bool isUnlocked(String? email) {
    // Se devMode está ligado → tudo libera
    if (devMode) return true;

    // Se email é admin → libera também
    if (email != null &&
        email.toLowerCase().trim() == adminEmail.toLowerCase().trim()) {
      return true;
    }

    return false; // padrão → bloqueado
  }
}
