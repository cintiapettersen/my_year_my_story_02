import 'package:supabase_flutter/supabase_flutter.dart';

/// Pequena fachada para expor o stream de mudanças de autenticação
/// sem realizar navegação manual. Toda a lógica de fluxo agora vive
/// no `SupabaseAuthState` usado em `main.dart`.
class AuthListener {
  static Stream<AuthState> get stream =>
      Supabase.instance.client.auth.onAuthStateChange;
}
