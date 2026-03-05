import 'package:myyearmystory/services/secure_storage_service.dart';
import 'package:myyearmystory/supabase/supabase_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';

class UserService {
  // -----------------------------------------------------------
  // 🔐 CADASTRO
  // -----------------------------------------------------------
  static Future<Map<String, dynamic>> signUp({
  required String email,
  required String password,
  required String name,
  String? birthDate,
}) async {
  try {
    // 1. Cria o usuário no auth
    final response = await SupabaseConfig.client.auth.signUp(
      email: email.trim(),
      password: password.trim(),
    );

    final user = response.user;

    if (user == null) {
      return {
        'success': false,
        'message': 'signup.error_general',
      };
    }

    // 2. A TRIGGER já criou o registro em "profiles",
    
    await SupabaseConfig.client.from('profiles').update({
  'full_name': name,
  'birth_date': birthDate,
  'email': email.trim(),
  'avatar_emoji': "🌸",   // opcional, mas ele ama começar com um emoji
   }).eq('id', user.id);

    // 3. Salva a sessão para login automático
    await SecureStorageService.saveSession(response.session);

    return {
      'success': true,
      'message': 'signup.success',
      'user': user,
      'session': response.session,
    };
  } catch (e) {
    String msg = 'signup.error_general';

    final error = e.toString().toLowerCase();

    if (error.contains('already registered')) {
      msg = 'signup.error_email_exists';
    } else if (error.contains('invalid email')) {
      msg = 'signup.error_email_invalid';
    } else if (error.contains('password') && error.contains('short')) {
      msg = 'signup.error_password_short';
    }

    return {'success': false, 'message': msg};
  }
}

  // -----------------------------------------------------------
  // 🔑 LOGIN
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
          'message': 'auth.login.error_invalid_credentials'.tr(),
        };
      }

      await SecureStorageService.saveSession(session);

      return {
        'success': true,
        'message': 'auth.login.success'.tr(),
        'user': user,
        'session': session,
      };
    } on AuthException catch (e) {
      String errorMessage = e.message.toLowerCase();

      if (errorMessage.contains("invalid login credentials")) {
        return {
          'success': false,
          'message': 'auth.login.error_invalid_credentials'.tr(),
        };
      }

      if (errorMessage.contains("email not confirmed")) {
        return {
          'success': false,
          'message': 'auth.login.error_email_not_confirmed'.tr(),
        };
      }

      return {
        'success': false,
        'message': 'auth.login.error_general'.tr(),
      };
    } catch (_) {
      return {
        'success': false,
        'message': 'auth.login.error_general'.tr(),
      };
    }
  }

  // -----------------------------------------------------------
  // 🔄 RESET PASSWORD
  // -----------------------------------------------------------
 static Future<Map<String, dynamic>> resetPassword(String email) async {
  try {
    await Supabase.instance.client.auth.resetPasswordForEmail(
      email.trim(),
      redirectTo: 'com.myyear.myyearmystory://reset-password',
    );

    return {
      'success': true,
      'message': 'auth.forgot.sent'.tr(),
    };
  } catch (_) {
    return {
      'success': false,
      'message': 'auth.forgot.error_general'.tr(),
    };
  }
}


  // -----------------------------------------------------------
  // 🚪 LOGOUT
  // -----------------------------------------------------------
  static Future<void> signOut() async {

    if (kDebugMode) debugPrint('🔥 SIGNOUT FOI CHAMADO AQUI');
    await SupabaseConfig.client.auth.signOut(
  scope: SignOutScope.global,
);
}
} 
