import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:myyearmystory/services/secure_storage_service.dart';

class AuthService {
  /// Tenta restaurar uma sessão salva no SecureStorage.
  /// Retorna true se conseguiu restaurar uma sessão válida.
  /// Retorna false se não existir sessão ou se estiver inválida.
  ///
  /// ⚠️ IMPORTANTE:
  /// - NÃO navega
  /// - NÃO faz signOut
  /// - NÃO decide fluxo
  /// O AuthListener é quem reage aos eventos.
  static Future<bool> restoreSession() async {
    try {
      final supabase = Supabase.instance.client;

      // 1️⃣ Ler sessão salva
      final sessionJson = await SecureStorageService.readSessionJson();

      // 👉 Não ter sessão NÃO é erro
      if (sessionJson == null || sessionJson.isEmpty) {
        return false;
      }

      // 2️⃣ Tenta recuperar sessão
      final response = await supabase.auth.recoverSession(sessionJson);

      final session = response.session;

      // 3️⃣ Sessão restaurada com sucesso
      if (session != null) {
        await SecureStorageService.saveSession(session);
        print('🔥 Sessão restaurada com sucesso');
        return true;
      }

      // 4️⃣ Sessão inválida / expirada
      return false;
    } catch (e) {
      // ❗ Nunca faz signOut aqui
      // ❗ Nunca navega
      print('❌ Erro ao restaurar sessão: $e');
      return false;
    }
  }
}
