// lib/app_config.dart

class AppConfig {
  /// Ativa o modo desenvolvedora.
  /// Quando TRUE → todo conteúdo premium fica liberado pra você.
  /// Quando FALSE → app funciona normalmente com paywall.
  static const bool devMode = true;

  /// Caso você queira liberar acesso baseado no e-mail.
  /// (Opcional – pode deixar vazio se não quiser usar)
  static const String adminEmail = "cintyapadua@gmail.com";

  /// Helper pra verificar se modo dev está ativo OU usuário é admin.
  static bool isAdmin(String? email) {
    if (devMode) return true;
    if (email == null) return false;
    return email.toLowerCase().trim() == adminEmail.toLowerCase().trim();
  }
}
