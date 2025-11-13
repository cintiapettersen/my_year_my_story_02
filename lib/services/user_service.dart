import 'package:my_year_my_story/supabase/supabase_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserService {
  // ✅ CADASTRO (EMAIL + SENHA)
  static Future<Map<String, dynamic>> signUp({
    required String email,
    required String password,
    required String name,
    String? birthDate, // agora é String
  }) async {
    try {
      print('🔧 [CADASTRO] Iniciando cadastro para: $email');

      final response = await SupabaseConfig.client.auth.signUp(
        email: email,
        password: password,
      );

      final user = response.user;

      if (user != null) {
        print('👤 [CADASTRO] Criando perfil na tabela profiles...');

        // Cria o registro na tabela profiles
        await SupabaseConfig.client.from('profiles').insert({
          'id': user.id,
          'full_name': name,
          'birth_date': birthDate, // formato yyyy-MM-dd
          'created_at': DateTime.now().toIso8601String(),
        });

        print('✅ [CADASTRO] Perfil criado com sucesso!');

        return {
          'success': true,
          'message': 'Conta criada com sucesso!',
          'user': user,
        };
      } else {
        return {
          'success': false,
          'message': 'Erro ao criar conta. Tente novamente.',
        };
      }
    } catch (e) {
      print('❌ [CADASTRO] ERRO: $e');

      String errorMessage = 'Erro de conexão. Verifique sua internet.';
      final errorString = e.toString().toLowerCase();

      if (errorString.contains('already registered')) {
        errorMessage = 'Este email já está cadastrado. Tente fazer login.';
      } else if (errorString.contains('invalid email')) {
        errorMessage = 'Email inválido. Verifique o formato.';
      } else if (errorString.contains('password') &&
          errorString.contains('short')) {
        errorMessage = 'A senha deve ter pelo menos 6 caracteres.';
      }

      return {'success': false, 'message': errorMessage};
    }
  }

  // ✅ LOGIN (EMAIL + SENHA)
  static Future<Map<String, dynamic>> signIn(
      String email, String password) async {
    try {
      print('🔐 [LOGIN] Tentando login para: $email');

      final response = await SupabaseConfig.client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      final user = response.user;

      if (user != null) {
        return {
          'success': true,
          'message': 'Login realizado com sucesso!',
          'user': user,
        };
      } else {
        return {
          'success': false,
          'message': 'Credenciais inválidas.',
        };
      }
    } catch (e) {
      print('❌ [LOGIN] ERRO: $e');
      String errorMessage = 'Erro de conexão. Verifique sua internet.';
      final errorString = e.toString().toLowerCase();

      if (errorString.contains('invalid login credentials')) {
        errorMessage = 'Email ou senha incorretos.';
      } else if (errorString.contains('email not confirmed')) {
        errorMessage = 'Email não confirmado. Verifique sua caixa de entrada.';
      }

      return {'success': false, 'message': errorMessage};
    }
  }

  // ✅ LOGIN / CADASTRO COM GOOGLE
  static Future<Map<String, dynamic>> signInWithGoogle() async {
    try {
      print('🔐 [GOOGLE] Iniciando login com Google...');

      await SupabaseConfig.client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'com.myyear.my_year_my_story://login-callback',
        authScreenLaunchMode: LaunchMode.externalApplication, // força abrir fora do app
      );

      print('🌐 [GOOGLE] Fluxo OAuth iniciado com sucesso. Aguardando retorno do navegador...');

      return {
        'success': true,
        'message': 'Login com Google iniciado. Aguarde o retorno.',
      };
    } catch (e) {
      print('❌ [GOOGLE] Erro ao iniciar login com Google: $e');
      return {
        'success': false,
        'message': 'Erro ao iniciar login com Google: $e',
      };
    }
  }


  // ✅ OBTER PERFIL PELO ID
  static Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final response = await SupabaseConfig.client
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();

      return response;
    } catch (e) {
      print('❌ [PERFIL] Erro ao buscar perfil: $e');
      return null;
    }
  }

  // ✅ ATUALIZAR PERFIL
  static Future<bool> updateUserProfile(
      String userId, Map<String, dynamic> updates) async {
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

  // ✅ REDEFINIR SENHA
  static Future<Map<String, dynamic>> resetPassword(String email) async {
    try {
      await SupabaseConfig.client.auth.resetPasswordForEmail(email);
      return {
        'success': true,
        'message': 'Email de recuperação enviado com sucesso!',
      };
    } catch (e) {
      print('❌ [RESET PASSWORD] Erro: $e');
      return {
        'success': false,
        'message': 'Erro ao enviar o email de recuperação: $e',
      };
    }
  }

  // ✅ LOGOUT
  static Future<void> signOut() async {
    await SupabaseConfig.client.auth.signOut();
  }
}
