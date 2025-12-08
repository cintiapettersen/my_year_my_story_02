import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:myyearmystory/services/secure_storage_service.dart';

class AuthService {
  // Recupera a sessão gravada no SecureStorage
  static Future<bool> restoreSession() async {
    try {
      final supabase = Supabase.instance.client;

      // 1. Ler sessão gravada
      final sessionJson = await SecureStorageService.readSessionJson();
      if (sessionJson == null) return false;

      // 2. Chamar recoverSession
      final response = await supabase.auth.recoverSession(sessionJson);

      // 3. Verificar se recuperou
      if (response.session != null) {
        print("🔥 Sessão restaurada com sucesso!");
        // salvar sessão restaurada (importante!)
        await SecureStorageService.saveSession(response.session);
        return true;
      }

      return false;
    } catch (e) {
      print("Erro ao restaurar sessão: $e");
      return false;
    }
  }
}
