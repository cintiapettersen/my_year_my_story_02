import 'package:myyearmystory/services/secure_storage_service.dart';
import 'package:myyearmystory/supabase/supabase_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserService {
  // -----------------------------------------------------------
  // 🔐 1. CADASTRO (EMAIL + SENHA)
  // -----------------------------------------------------------
  static Future<Map<String, dynamic>> signUp({
    required String email,
    required String password,
    required String name,
    String? birthDate,
  }) async {
    try {
      final response = await SupabaseConfig.client.auth.signUp(
        email: email.trim(),
        password: password.trim(),
      );

      final user = response.user;

      if (user == null) {
        return {
          'success': false,
          'message': 'Erro ao criar conta. Tente novamente.',
        };
      }

      // Cria o perfil na tabela
      await SupabaseConfig.client.from('profiles').insert({
        'id': user.id,
        'full_name': name,
        'birth_date': birthDate,
        'created_at': DateTime.now().toIso8601String(),
      });

      await SecureStorageService.saveSession(response.session);

      return {
        'success': true,
        'message': 'Conta criada com sucesso!',
        'user': user,
        'session': response.session,
      };
    } catch (e) {
      String msg = 'Erro de conexão. Verifique sua internet.';
      final error = e.toString().toLowerCase();

      if (error.contains('already registered')) {
        msg = 'Este email já está cadastrado.';
      } else if (error.contains('invalid email')) {
        msg = 'Email inválido.';
      } else if (error.contains('password') && error.contains('short')) {
        msg = 'A senha deve ter pelo menos 6 caracteres.';
      }

      return {'success': false, 'message': msg};
    }
  }

  // -----------------------------------------------------------
  // 🔑 2. LOGIN COM EMAIL + SENHA
  // -----------------------------------------------------------
  static Future<Map<String, dynamic>> signIn(
    String email,
    String password,
  ) async {
    try {
      final response = await SupabaseConfig.client.auth.signInWithPassword(
        email: email.trim(),
        password: password.trim(),
      );

      final user = response.user;
      final session = response.session;

      if (user == null || session == null) {
        return {
          'success': false,
          'message': 'Credenciais inválidas.',
        };
      }

      await SecureStorageService.saveSession(session);

      return {
        'success': true,
        'message': 'Login realizado com sucesso!',
        'user': user,
        'session': session,
      };
    } on AuthException catch (e) {
      String msg = 'Erro de conexão.';
      final error = e.message.toLowerCase();

      if (error.contains('invalid login credentials')) {
        msg = 'Email ou senha incorretos.';
      } else if (error.contains('email not confirmed')) {
        msg = 'Email não confirmado.';
      }

      return {'success': false, 'message': msg};
    } catch (_) {
      return {
        'success': false,
        'message': 'Erro inesperado. Tente novamente.',
      };
    }
  }

  // -----------------------------------------------------------
  // 📄 3. BUSCAR PERFIL
  // -----------------------------------------------------------
  static Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      return await SupabaseConfig.client
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();
    } catch (e) {
      print('❌ [PERFIL] Erro ao buscar perfil: $e');
      return null;
    }
  }

  // -----------------------------------------------------------
  // ✏️ 4. ATUALIZAR PERFIL
  // -----------------------------------------------------------
  static Future<bool> updateUserProfile(
    String userId,
    Map<String, dynamic> updates,
  ) async {
    try {
      await SupabaseConfig.client
          .from('profiles')
          .update(updates)
          .eq('id', userId);

      return true;
    } catch (e) {
      print('❌ [PERFIL] Erro ao atualizar perfil: $e');
      return false;
    }
  }

  // -----------------------------------------------------------
  // 🔄 5. RESET PASSWORD
  // -----------------------------------------------------------
  static Future<Map<String, dynamic>> resetPassword(String email) async {
    try {
      await SupabaseConfig.client.auth.resetPasswordForEmail(email.trim());

      return {
        'success': true,
        'message': 'Email de recuperação enviado!',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Erro ao enviar email de recuperação.',
      };
    }
  }

  // -----------------------------------------------------------
  // 🚪 6. LOGOUT (SEGURO PARA BIOMETRIA)
  // -----------------------------------------------------------
  static Future<void> signOut() async {
    await SupabaseConfig.client.auth.signOut(scope: SignOutScope.local);
  }
}
